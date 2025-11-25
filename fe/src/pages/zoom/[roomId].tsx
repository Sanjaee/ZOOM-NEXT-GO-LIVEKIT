import { useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/router";
import { useSession } from "next-auth/react";
import { api, TokenManager } from "@/lib/api";
import type { JoinRoomResponse } from "@/types/room";
import { Room, RemoteParticipant, RoomEvent, Track } from "livekit-client";
import Navbar from "@/components/general/Navbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { toast } from "@/hooks/use-toast";
import { Mic, MicOff, Video, VideoOff, PhoneOff, Users } from "lucide-react";

export default function ZoomCallPage() {
  const router = useRouter();
  const { data: session, status } = useSession();
  const { roomId } = router.query;
  const [room, setRoom] = useState<Room | null>(null);
  const [participants, setParticipants] = useState<Map<string, RemoteParticipant>>(new Map());
  const [isMicMuted, setIsMicMuted] = useState(false);
  const [isCameraOff, setIsCameraOff] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const videoElementsRef = useRef<Map<string, HTMLVideoElement>>(new Map());
  const localVideoRef = useRef<HTMLVideoElement>(null);
  const isJoiningRef = useRef(false);
  const hasJoinedRef = useRef(false);

  const attachTrack = useCallback((track: Track, participant: RemoteParticipant) => {
    if (track.kind === "video") {
      let videoEl = videoElementsRef.current.get(participant.identity);
      if (!videoEl) {
        videoEl = document.createElement("video");
        videoEl.autoplay = true;
        videoEl.playsInline = true;
        videoEl.className = "w-full h-full object-cover rounded-lg";
        videoElementsRef.current.set(participant.identity, videoEl);
      }
      track.attach(videoEl);
    } else if (track.kind === "audio") {
      const audioEl = track.attach();
      document.body.appendChild(audioEl);
    }
  }, []);

  const joinRoom = useCallback(async (id: string) => {
    // Prevent multiple simultaneous joins
    if (isJoiningRef.current || hasJoinedRef.current) {
      console.log("[DEBUG] Already joining or joined, skipping...");
      return;
    }

    // Check if already connected
    if (room && room.state === "connected") {
      console.log("[DEBUG] Already connected to room");
      setLoading(false);
      return;
    }

    isJoiningRef.current = true;

    try {
      console.log("[DEBUG] Starting joinRoom for room:", id);
      setLoading(true);
      setError(null);

      // Disconnect existing room if any
      if (room) {
        console.log("[DEBUG] Disconnecting existing room...");
        try {
          await room.disconnect();
        } catch (e) {
          console.warn("[DEBUG] Error disconnecting existing room:", e);
        }
      }

      // Get token from session or localStorage
      let token: string | null = null;
      
      if (session?.accessToken) {
        token = session.accessToken as string;
        console.log("[DEBUG] Using token from NextAuth session");
        // Save to localStorage for API client
        if (session.refreshToken) {
          TokenManager.setTokens(token, session.refreshToken as string);
        }
      } else {
        token = TokenManager.getAccessToken();
        console.log("[DEBUG] Using token from localStorage");
      }
      
      console.log("[DEBUG] Access token exists:", !!token);
      if (!token) {
        throw new Error("No access token found. Please login again.");
      }
      
      // Set token to API client
      api.setAccessToken(token);

      // Get join token from backend
      console.log("[DEBUG] Calling API joinRoom...");
      const data = await api.joinRoom(id) as JoinRoomResponse;
      console.log("[DEBUG] Join room response received:", { 
        hasToken: !!data.token, 
        url: data.url,
        roomId: data.room?.id 
      });

      // Connect to LiveKit room
      console.log("[DEBUG] Creating Room instance...");
      const newRoom = new Room({
        adaptiveStream: true,
        dynacast: true,
      });

      // Set up event listeners
      console.log("[DEBUG] Setting up room listeners...");
      
      // Participant connected
      newRoom.on(RoomEvent.ParticipantConnected, (participant) => {
        console.log("Participant connected:", participant.identity);
        setParticipants((prev) => {
          const newMap = new Map(prev);
          newMap.set(participant.identity, participant);
          return newMap;
        });
      });

      // Participant disconnected
      newRoom.on(RoomEvent.ParticipantDisconnected, (participant) => {
        console.log("Participant disconnected:", participant.identity);
        setParticipants((prev) => {
          const newMap = new Map(prev);
          newMap.delete(participant.identity);
          return newMap;
        });
        // Status is checked directly from participant in render, no need to remove separately
        // Remove video element
        const videoEl = videoElementsRef.current.get(participant.identity);
        if (videoEl) {
          videoEl.srcObject = null;
          videoElementsRef.current.delete(participant.identity);
        }
      });

      // Track subscribed
      newRoom.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
        console.log("Track subscribed:", track.kind, participant.identity);
        attachTrack(track, participant);
        
        // Update participants map if not already there
        setParticipants((prev) => {
          const newMap = new Map(prev);
          if (!newMap.has(participant.identity)) {
            newMap.set(participant.identity, participant);
          }
          return newMap;
        });

        // Status is checked directly from participant in render, no need to store separately
      });

      // Local track published
      newRoom.on(RoomEvent.LocalTrackPublished, (publication) => {
        console.log("Local track published:", publication.kind);
        if (publication.kind === "video" && publication.track && localVideoRef.current) {
          publication.track.attach(localVideoRef.current);
        }
        // Update state based on actual track state
        if (publication.kind === "audio") {
          setIsMicMuted(!newRoom.localParticipant.isMicrophoneEnabled);
        }
        if (publication.kind === "video") {
          setIsCameraOff(!newRoom.localParticipant.isCameraEnabled);
        }
      });

      // Local track unpublished
      newRoom.on(RoomEvent.LocalTrackUnpublished, (publication) => {
        console.log("Local track unpublished:", publication.kind);
        // Update state based on actual LiveKit state
        setIsMicMuted(!newRoom.localParticipant.isMicrophoneEnabled);
        setIsCameraOff(!newRoom.localParticipant.isCameraEnabled);
        
        // Detach video element when camera is unpublished
        if (publication.kind === "video") {
          if (publication.track && localVideoRef.current) {
            publication.track.detach();
          }
          if (localVideoRef.current) {
            localVideoRef.current.srcObject = null;
          }
        }
      });

      // Track unsubscribed
      newRoom.on(RoomEvent.TrackUnsubscribed, (track) => {
        track.detach();
        // Status is checked directly from participant in render
      });

      // Status is checked directly from participant in render, no need for event handlers

      // Connect to room
      console.log("[DEBUG] Connecting to LiveKit:", { url: data.url, hasToken: !!data.token });
      await newRoom.connect(data.url, data.token);
      console.log("[DEBUG] Successfully connected to LiveKit room");
      
      // Get existing participants in the room
      const existingParticipants = new Map<string, RemoteParticipant>();
      newRoom.remoteParticipants.forEach((participant) => {
        console.log("[DEBUG] Found existing participant:", participant.identity);
        existingParticipants.set(participant.identity, participant);
        
        // Attach existing tracks
        participant.trackPublications.forEach((publication) => {
          if (publication.track) {
            console.log("[DEBUG] Attaching existing track:", publication.kind, participant.identity);
            attachTrack(publication.track, participant);
          }
        });
      });
      setParticipants(existingParticipants);
      
      setRoom(newRoom);
      hasJoinedRef.current = true;
      setLoading(false);

      // Try to enable camera and microphone, but don't fail if permission denied
      try {
        await newRoom.localParticipant.enableCameraAndMicrophone();
        // Update state based on actual LiveKit state
        setIsMicMuted(!newRoom.localParticipant.isMicrophoneEnabled);
        setIsCameraOff(!newRoom.localParticipant.isCameraEnabled);
        console.log("[DEBUG] Camera and microphone enabled");
      } catch (err: any) {
        console.warn("[DEBUG] Could not enable camera/microphone:", err);
        // Don't show error toast, just continue without camera/mic
        // Update state based on actual LiveKit state
        setIsMicMuted(!newRoom.localParticipant.isMicrophoneEnabled);
        setIsCameraOff(!newRoom.localParticipant.isCameraEnabled);
        // User can manually enable later
      }
    } catch (err: any) {
      console.error("[ERROR] Error joining room:", err);
      console.error("[ERROR] Error details:", {
        message: err.message,
        stack: err.stack,
        response: err.response,
      });
      const errorMessage = err.message || err.response?.data?.message || "Gagal bergabung ke room";
      setError(errorMessage);
      setLoading(false);
      hasJoinedRef.current = false;
      
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
      
      // Don't redirect automatically, let user see the error
      // Only redirect if it's an auth error
      if (err.response?.status === 401 || err.message?.includes("token") || err.message?.includes("authenticated")) {
        console.log("[DEBUG] Auth error detected, redirecting to login...");
        setTimeout(() => {
          router.push("/auth/login");
        }, 2000);
      }
    } finally {
      isJoiningRef.current = false;
    }
  }, [attachTrack, session, room, router]);

  // Sync state with LiveKit participant state
  useEffect(() => {
    if (!room || room.state !== "connected") return;

    // Initial sync
    setIsMicMuted(!room.localParticipant.isMicrophoneEnabled);
    setIsCameraOff(!room.localParticipant.isCameraEnabled);

    // Set up interval to periodically sync state (fallback)
    // This ensures UI stays in sync with actual LiveKit state
    const syncInterval = setInterval(() => {
      if (room && room.state === "connected") {
        setIsMicMuted(() => !room.localParticipant.isMicrophoneEnabled);
        setIsCameraOff(() => !room.localParticipant.isCameraEnabled);
      }
    }, 500); // Check every 500ms

    return () => {
      clearInterval(syncInterval);
    };
  }, [room]);

  useEffect(() => {
    console.log("[DEBUG] useEffect triggered, roomId:", roomId, "session status:", status);
    
    // Wait for session to load
    if (status === "loading") {
      console.log("[DEBUG] Session loading, waiting...");
      return;
    }

    if (!roomId || typeof roomId !== "string") {
      console.log("[DEBUG] Invalid roomId, waiting...");
      return;
    }

    // Prevent multiple joins
    if (hasJoinedRef.current || isJoiningRef.current) {
      console.log("[DEBUG] Already joined or joining, skipping...");
      return;
    }

    // Check for token from NextAuth session first, then localStorage
    let token: string | null = null;
    
    if (session?.accessToken) {
      token = session.accessToken as string;
      console.log("[DEBUG] Token from NextAuth session");
      // Also save to localStorage for API client
      if (session.refreshToken) {
        TokenManager.setTokens(token, session.refreshToken as string);
      }
    } else {
      token = TokenManager.getAccessToken();
      console.log("[DEBUG] Token from localStorage");
    }

    console.log("[DEBUG] Token check:", { hasToken: !!token, roomId, hasSession: !!session });
    
    if (!token) {
      console.log("[DEBUG] No token found, redirecting to login");
      router.push("/auth/login?callbackUrl=" + encodeURIComponent(`/zoom/${roomId}`));
      return;
    }

    console.log("[DEBUG] Setting access token and joining room");
    api.setAccessToken(token);
    joinRoom(roomId);

    return () => {
      // Cleanup on unmount
      if (room && room.state === "connected") {
        console.log("[DEBUG] Cleaning up room on unmount");
        room.disconnect().catch(console.error);
      }
      hasJoinedRef.current = false;
      isJoiningRef.current = false;
    };
  }, [roomId, router, session, status]); // Removed joinRoom and room from dependencies to prevent loops

  const toggleMic = async () => {
    if (!room || room.state !== "connected") return;
    
    try {
      // Get current state from LiveKit
      const currentlyEnabled = room.localParticipant.isMicrophoneEnabled;
      const newEnabledState = !currentlyEnabled;
      
      console.log("[DEBUG] Toggling mic:", { currentlyEnabled, newEnabledState });
      
      // Toggle microphone
      await room.localParticipant.setMicrophoneEnabled(newEnabledState);
      
      // Update state based on actual LiveKit state after toggle
      setIsMicMuted(!room.localParticipant.isMicrophoneEnabled);
      
      console.log("[DEBUG] Mic state after toggle:", room.localParticipant.isMicrophoneEnabled);
    } catch (err: any) {
      console.error("Error toggling microphone:", err);
      
      // Update state based on actual LiveKit state (might not have changed)
      if (room) {
        setIsMicMuted(!room.localParticipant.isMicrophoneEnabled);
      }
      
      // Don't show error if permission denied, just update state
      if (err.name === "NotAllowedError" || err.name === "PermissionDeniedError") {
        toast({
          title: "Izin Diperlukan",
          description: "Izin mikrofon diperlukan untuk menggunakan fitur ini",
          variant: "default",
        });
      } else {
        toast({
          title: "Error",
          description: "Tidak dapat mengakses mikrofon",
          variant: "destructive",
        });
      }
    }
  };

  const toggleCamera = async () => {
    if (!room || room.state !== "connected") return;
    
    try {
      // Get current state from LiveKit
      const currentlyEnabled = room.localParticipant.isCameraEnabled;
      const newEnabledState = !currentlyEnabled;
      
      console.log("[DEBUG] Toggling camera:", { currentlyEnabled, newEnabledState });
      
      // Toggle camera
      await room.localParticipant.setCameraEnabled(newEnabledState);
      
      // Update state based on actual LiveKit state after toggle
      setIsCameraOff(!room.localParticipant.isCameraEnabled);
      
      // Attach/detach video element
      if (room.localParticipant.isCameraEnabled && localVideoRef.current) {
        const videoPublication = room.localParticipant.getTrackPublication(Track.Source.Camera);
        if (videoPublication?.track) {
          videoPublication.track.attach(localVideoRef.current);
        }
      } else if (localVideoRef.current) {
        // Clear video element when camera is off
        localVideoRef.current.srcObject = null;
      }
      
      console.log("[DEBUG] Camera state after toggle:", room.localParticipant.isCameraEnabled);
    } catch (err: any) {
      console.error("Error toggling camera:", err);
      
      // Update state based on actual LiveKit state (might not have changed)
      if (room) {
        setIsCameraOff(!room.localParticipant.isCameraEnabled);
      }
      
      // Don't show error if permission denied, just update state
      if (err.name === "NotAllowedError" || err.name === "PermissionDeniedError") {
        toast({
          title: "Izin Diperlukan",
          description: "Izin kamera diperlukan untuk menggunakan fitur ini",
          variant: "default",
        });
      } else {
        toast({
          title: "Error",
          description: "Tidak dapat mengakses kamera",
          variant: "destructive",
        });
      }
    }
  };

  const leaveRoom = async () => {
    if (room && room.state === "connected") {
      try {
        // Unpublish all tracks first
        const publications = Array.from(room.localParticipant.trackPublications.values());
        for (const publication of publications) {
          try {
            if (publication.track) {
              await room.localParticipant.unpublishTrack(publication.track);
            }
          } catch (err) {
            console.error("Error unpublishing track:", err);
          }
        }

        // Detach all tracks
        room.localParticipant.trackPublications.forEach((publication) => {
          if (publication.track) {
            publication.track.detach();
          }
        });

        // Disconnect from room
        await room.disconnect();
      } catch (err) {
        console.error("Error during disconnect:", err);
      } finally {
        setRoom(null);
        hasJoinedRef.current = false;
        isJoiningRef.current = false;
      }
    }

    // Call API to remove participant from room
    if (roomId && typeof roomId === "string") {
      try {
        await api.leaveRoom(roomId);
      } catch (err: any) {
        console.error("Error leaving room via API:", err);
        // Continue even if API call fails
      }
    }

    // Clear participants
    setParticipants(new Map());
    videoElementsRef.current.clear();

    // Reset state
    setIsMicMuted(false);
    setIsCameraOff(false);

    // Small delay to ensure cleanup is complete
    await new Promise((resolve) => setTimeout(resolve, 500));

    // Navigate back to zoom list
    router.push("/zoom");
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mb-4"></div>
          <p className="text-gray-600 dark:text-gray-400">Menghubungkan ke room...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 flex items-center justify-center">
        <Card className="p-8 max-w-md">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Error</h2>
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error}</p>
          <div className="space-y-2">
            <Button onClick={() => router.push("/zoom")} className="w-full">
              Kembali ke Rooms
            </Button>
            <Button 
              onClick={() => {
                console.log("[DEBUG] Retry button clicked");
                setError(null);
                setLoading(true);
                if (roomId && typeof roomId === "string") {
                  joinRoom(roomId);
                }
              }} 
              variant="outline" 
              className="w-full"
            >
              Coba Lagi
            </Button>
          </div>
          <details className="mt-4">
            <summary className="text-sm text-gray-500 cursor-pointer">Debug Info</summary>
            <pre className="mt-2 text-xs bg-gray-100 dark:bg-gray-800 p-2 rounded overflow-auto max-h-40">
              {JSON.stringify({ roomId, error, hasToken: !!TokenManager.getAccessToken() }, null, 2)}
            </pre>
          </details>
        </Card>
      </div>
    );
  }

  const participantCount = participants.size + 1; // +1 for local participant

  return (
    <div className="min-h-screen bg-gray-900 flex flex-col">
      <Navbar />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="bg-gray-800 px-6 py-4 flex justify-between items-center">
          <div>
            <h2 className="text-xl font-semibold text-white">Room: {roomId}</h2>
            <p className="text-gray-400 text-sm">Video Call</p>
          </div>
          <div className="flex items-center gap-2 bg-gray-700 px-4 py-2 rounded-full">
            <Users className="h-4 w-4 text-gray-300" />
            <span className="text-white text-sm">{participantCount} peserta</span>
          </div>
        </div>

        {/* Video Grid */}
        <div className="flex-1 p-6 overflow-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-w-7xl mx-auto">
            {/* Local Video */}
            <Card className="relative p-0 aspect-video bg-gray-800 overflow-hidden">
              <video
                ref={localVideoRef}
                className="w-full h-full object-cover"
                autoPlay
                playsInline
                muted
              />
              <div className="absolute bottom-2 left-2 bg-black/70 text-white px-3 py-1 rounded text-sm">
                Anda
              </div>
              {/* Status Icons Overlay */}
              <div className="absolute top-2 right-2 flex gap-2">
                {isMicMuted && (
                  <div className="bg-red-600/90 rounded-full p-1.5">
                    <MicOff className="h-4 w-4 text-white" />
                  </div>
                )}
                {isCameraOff && (
                  <div className="bg-red-600/90 rounded-full p-1.5">
                    <VideoOff className="h-4 w-4 text-white" />
                  </div>
                )}
              </div>
            </Card>

            {/* Remote Participants */}
            {Array.from(participants.entries()).map(([identity, participant]) => {
              // Check actual status from participant
              const micPublication = participant.getTrackPublication(Track.Source.Microphone);
              const cameraPublication = participant.getTrackPublication(Track.Source.Camera);
              const actualMicMuted = !micPublication?.isSubscribed || micPublication.isMuted;
              const actualCameraOff = !cameraPublication?.isSubscribed || !cameraPublication.track;
              
              return (
                <Card key={identity} className="relative aspect-video bg-gray-800 overflow-hidden">
                  <div
                    ref={(el) => {
                      if (el) {
                        const videoEl = videoElementsRef.current.get(identity);
                        if (videoEl && !el.contains(videoEl)) {
                          el.appendChild(videoEl);
                        }
                      }
                    }}
                    className="w-full h-full"
                  />
                  <div className="absolute bottom-2 left-2 bg-black/70 text-white px-3 py-1 rounded text-sm">
                    {identity}
                  </div>
                  {/* Status Icons Overlay */}
                  <div className="absolute top-2 right-2 flex gap-2">
                    {actualMicMuted && (
                      <div className="bg-red-600/90 rounded-full p-1.5">
                        <MicOff className="h-4 w-4 text-white" />
                      </div>
                    )}
                    {actualCameraOff && (
                      <div className="bg-red-600/90 rounded-full p-1.5">
                        <VideoOff className="h-4 w-4 text-white" />
                      </div>
                    )}
                  </div>
                </Card>
              );
            })}
          </div>
        </div>

        {/* Controls */}
        <div className="bg-gray-800 px-6 py-4 flex justify-center gap-4">
          <Button
            onClick={toggleMic}
            size="lg"
            className={`rounded-full h-14 w-14 p-0 ${
              isMicMuted
                ? "bg-red-600 hover:bg-red-700"
                : "bg-gray-700 hover:bg-gray-600"
            }`}
          >
            {isMicMuted ? (
              <MicOff className="h-6 w-6" />
            ) : (
              <Mic className="h-6 w-6" />
            )}
          </Button>
          <Button
            onClick={toggleCamera}
            size="lg"
            className={`rounded-full h-14 w-14 p-0 ${
              isCameraOff
                ? "bg-red-600 hover:bg-red-700"
                : "bg-gray-700 hover:bg-gray-600"
            }`}
          >
            {isCameraOff ? (
              <VideoOff className="h-6 w-6" />
            ) : (
              <Video className="h-6 w-6" />
            )}
          </Button>
          <Button
            onClick={leaveRoom}
            size="lg"
            className="rounded-full h-14 w-14 p-0 bg-red-600 hover:bg-red-700"
          >
            <PhoneOff className="h-6 w-6" />
          </Button>
        </div>
      </div>
    </div>
  );
}

