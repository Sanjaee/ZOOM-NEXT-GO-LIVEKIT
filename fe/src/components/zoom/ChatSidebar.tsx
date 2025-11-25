import { useState, useEffect, useRef } from "react";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Send, MessageSquare } from "lucide-react";
import { api } from "@/lib/api";
import { toast } from "@/hooks/use-toast";

interface ChatMessage {
  id: string;
  room_id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  message: string;
  created_at: string;
}

interface ChatSidebarProps {
  roomId: string;
  userId: string;
  isOpen: boolean;
  onClose?: () => void;
}

export default function ChatSidebar({ roomId, userId, isOpen, onClose }: ChatSidebarProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (isOpen && roomId) {
      fetchMessages();
      connectWebSocket();
    }

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }
    };
  }, [isOpen, roomId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchMessages = async () => {
    try {
      setLoading(true);
      const token = api.getAccessToken();
      if (!token) {
        throw new Error("No access token");
      }

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/v1/rooms/${roomId}/messages`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch messages");
      }

      const data = await response.json();
      setMessages(data.data || []);
    } catch (error: any) {
      console.error("Error fetching messages:", error);
      toast({
        title: "Error",
        description: "Gagal memuat pesan",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const connectWebSocket = () => {
    if (!roomId || !userId) return;

    const token = api.getAccessToken();
    if (!token) {
      console.error("No access token for WebSocket");
      return;
    }

    const wsProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsHost = process.env.NEXT_PUBLIC_API_URL?.replace(/^https?:\/\//, "") || "localhost:5000";
    const wsUrl = `${wsProtocol}//${wsHost}/api/v1/rooms/${roomId}/chat/ws?token=${encodeURIComponent(token)}`;

    console.log("[WS] Attempting to connect to:", wsUrl.replace(/token=[^&]*/, "token=***"));

    try {
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log("[WS] WebSocket connected successfully for chat");
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          
          if (message.type === "message" && message.payload) {
            setMessages((prev) => {
              // Avoid duplicates
              const exists = prev.some((m) => m.id === message.payload.id);
              if (exists) return prev;
              return [...prev, message.payload];
            });
          }
        } catch (error) {
          console.error("Error parsing WebSocket message:", error);
        }
      };

      ws.onerror = (error) => {
        console.error("[WS] WebSocket error:", error);
        console.error("[WS] Error details:", {
          readyState: ws.readyState,
          url: wsUrl.replace(/token=[^&]*/, "token=***"),
        });
      };

      ws.onclose = (event) => {
        console.log("[WS] WebSocket disconnected:", {
          code: event.code,
          reason: event.reason,
          wasClean: event.wasClean,
        });
        // Reconnect after 3 seconds
        setTimeout(() => {
          if (isOpen) {
            connectWebSocket();
          }
        }, 3000);
      };
    } catch (error) {
      console.error("Error connecting WebSocket:", error);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || sending) return;

    try {
      setSending(true);
      const token = api.getAccessToken();
      const fetchResponse = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/v1/rooms/${roomId}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ message: newMessage.trim() }),
      });

      if (!fetchResponse.ok) {
        throw new Error("Failed to send message");
      }

      const responseData = await fetchResponse.json();
      const messageData = responseData.data || responseData;

      if (messageData) {
        setMessages((prev) => {
          const exists = prev.some((m) => m.id === messageData.id);
          if (exists) return prev;
          return [...prev, messageData];
        });
      }

      setNewMessage("");
    } catch (error: any) {
      console.error("Error sending message:", error);
      toast({
        title: "Error",
        description: error.message || "Gagal mengirim pesan",
        variant: "destructive",
      });
    } finally {
      setSending(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return "Baru saja";
    if (diffMins < 60) return `${diffMins}m yang lalu`;
    
    return date.toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" });
  };

  if (!isOpen) return null;

  return (
    <Card className="w-80 h-full flex flex-col bg-gray-800 border-gray-700">
      {/* Header */}
      <div className="p-4 border-b border-gray-700">
        <div className="flex items-center gap-2">
          <MessageSquare className="h-5 w-5 text-gray-300" />
          <h3 className="text-lg font-semibold text-white">Chat</h3>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4" ref={messagesContainerRef}>
        {loading ? (
          <div className="text-center text-gray-400 py-8">Memuat pesan...</div>
        ) : messages.length === 0 ? (
          <div className="text-center text-gray-400 py-8">Belum ada pesan</div>
        ) : (
          <div className="space-y-3">
            {messages.map((msg) => {
              const isOwnMessage = msg.user_id === userId;
              return (
                <div
                  key={msg.id}
                  className={`flex flex-col ${isOwnMessage ? "items-end" : "items-start"}`}
                >
                  {!isOwnMessage && (
                    <span className="text-xs text-gray-400 mb-1">{msg.user_name}</span>
                  )}
                  <div
                    className={`max-w-[80%] rounded-lg px-3 py-2 ${
                      isOwnMessage
                        ? "bg-blue-600 text-white"
                        : "bg-gray-700 text-gray-100"
                    }`}
                  >
                    <p className="text-sm break-words">{msg.message}</p>
                  </div>
                  <span className="text-xs text-gray-500 mt-1">
                    {formatTime(msg.created_at)}
                  </span>
                </div>
              );
            })}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input */}
      <div className="p-4 border-t border-gray-700">
        <div className="flex gap-2">
          <Input
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Ketik pesan..."
            className="bg-gray-700 border-gray-600 text-white placeholder:text-gray-400"
            disabled={sending}
          />
          <Button
            onClick={handleSendMessage}
            disabled={!newMessage.trim() || sending}
            size="icon"
            className="bg-blue-600 hover:bg-blue-700"
          >
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </Card>
  );
}

