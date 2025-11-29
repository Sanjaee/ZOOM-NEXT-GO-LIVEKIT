import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/services/room_service.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/chat_sidebar.dart';

class VideoCallPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const VideoCallPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> with SingleTickerProviderStateMixin {
  final RoomService _roomService = RoomService();
  
  Room? _room;
  LocalParticipant? _localParticipant;
  List<RemoteParticipant> _remoteParticipants = [];
  
  bool _isConnecting = true;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isFrontCamera = true;
  bool _isChatOpen = false;
  String? _error;
  
  EventsListener<RoomEvent>? _listener;
  
  // Animation controller for chat slide
  late AnimationController _chatAnimationController;
  late Animation<Offset> _chatSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize chat animation
    _chatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chatSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _initRoom();
  }

  @override
  void dispose() {
    _chatAnimationController.dispose();
    _listener?.dispose();
    _disconnectRoom();
    super.dispose();
  }
  
  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
    if (_isChatOpen) {
      _chatAnimationController.forward();
    } else {
      _chatAnimationController.reverse();
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<void> _initRoom() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      // Request permissions
      await _requestPermissions();

      // Get LiveKit token from backend
      final joinResponse = await _roomService.joinRoom(widget.roomId);
      
      debugPrint('[VideoCall] Connecting to: ${joinResponse.url}');
      debugPrint('[VideoCall] Token received: ${joinResponse.token.isNotEmpty}');

      // Create room instance
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
            params: VideoParametersPresets.h720_169,
          ),
          defaultAudioCaptureOptions: AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
          ),
        ),
      );

      // Setup room listeners
      _setupRoomListeners();

      // Connect to LiveKit
      await _room!.connect(
        joinResponse.url,
        joinResponse.token,
      );

      debugPrint('[VideoCall] Connected to room');
      
      _localParticipant = _room!.localParticipant;

      // Enable camera and microphone
      try {
        await _localParticipant?.setCameraEnabled(true);
        await _localParticipant?.setMicrophoneEnabled(true);
        debugPrint('[VideoCall] Camera and mic enabled');
      } catch (e) {
        debugPrint('[VideoCall] Could not enable camera/mic: $e');
      }

      setState(() {
        _remoteParticipants = _room!.remoteParticipants.values.toList();
        _isConnecting = false;
        _isMicEnabled = _localParticipant?.isMicrophoneEnabled() ?? false;
        _isCameraEnabled = _localParticipant?.isCameraEnabled() ?? false;
      });
    } catch (e) {
      debugPrint('[VideoCall] Error: $e');
      setState(() {
        _error = e.toString();
        _isConnecting = false;
      });
    }
  }

  void _setupRoomListeners() {
    _listener = _room!.createListener();

    _listener!
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint('[VideoCall] Participant connected: ${event.participant.identity}');
        setState(() {
          _remoteParticipants = _room!.remoteParticipants.values.toList();
        });
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint('[VideoCall] Participant disconnected: ${event.participant.identity}');
        setState(() {
          _remoteParticipants = _room!.remoteParticipants.values.toList();
        });
      })
      ..on<TrackSubscribedEvent>((event) {
        debugPrint('[VideoCall] Track subscribed: ${event.track.kind}');
        setState(() {});
      })
      ..on<TrackUnsubscribedEvent>((event) {
        debugPrint('[VideoCall] Track unsubscribed');
        setState(() {});
      })
      ..on<LocalTrackPublishedEvent>((event) {
        debugPrint('[VideoCall] Local track published: ${event.publication.kind}');
        setState(() {
          _isMicEnabled = _localParticipant?.isMicrophoneEnabled() ?? false;
          _isCameraEnabled = _localParticipant?.isCameraEnabled() ?? false;
        });
      })
      ..on<LocalTrackUnpublishedEvent>((event) {
        debugPrint('[VideoCall] Local track unpublished');
        setState(() {
          _isMicEnabled = _localParticipant?.isMicrophoneEnabled() ?? false;
          _isCameraEnabled = _localParticipant?.isCameraEnabled() ?? false;
        });
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('[VideoCall] Room disconnected');
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
  }

  Future<void> _disconnectRoom() async {
    try {
      await _room?.disconnect();
      await _roomService.leaveRoom(widget.roomId);
    } catch (e) {
      debugPrint('[VideoCall] Error disconnecting: $e');
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_localParticipant == null) return;
    
    try {
      await _localParticipant!.setMicrophoneEnabled(!_isMicEnabled);
      setState(() {
        _isMicEnabled = !_isMicEnabled;
      });
    } catch (e) {
      debugPrint('[VideoCall] Error toggling mic: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_localParticipant == null) return;
    
    try {
      await _localParticipant!.setCameraEnabled(!_isCameraEnabled);
      setState(() {
        _isCameraEnabled = !_isCameraEnabled;
      });
    } catch (e) {
      debugPrint('[VideoCall] Error toggling camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_localParticipant == null || !_isCameraEnabled) return;
    
    try {
      final track = _localParticipant!.videoTrackPublications
          .where((pub) => pub.source == TrackSource.camera)
          .firstOrNull
          ?.track;
      
      if (track is LocalVideoTrack) {
        await track.setCameraPosition(
          _isFrontCamera ? CameraPosition.back : CameraPosition.front,
        );
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      }
    } catch (e) {
      debugPrint('[VideoCall] Error switching camera: $e');
    }
  }

  void _leaveRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Room?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari video call?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Menghubungkan ke ${widget.roomName}...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Gagal terhubung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                _buildHeader(),

                // Video Grid
                Expanded(
                  child: _buildVideoGrid(),
                ),

                // Controls
                _buildControls(),
              ],
            ),
            
            // Chat overlay backdrop (when chat is open)
            if (_isChatOpen)
              GestureDetector(
                onTap: _toggleChat,
                child: AnimatedBuilder(
                  animation: _chatAnimationController,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withValues(
                        alpha: 0.5 * _chatAnimationController.value,
                      ),
                    );
                  },
                ),
              ),
            
            // Sliding Chat Panel
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: _chatSlideAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ChatSidebar(
                        roomId: widget.roomId,
                        onClose: _toggleChat,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black.withValues(alpha: 0.8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_remoteParticipants.length + 1} peserta',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    final allParticipants = <Participant>[];
    if (_localParticipant != null) {
      allParticipants.add(_localParticipant!);
    }
    allParticipants.addAll(_remoteParticipants);

    if (allParticipants.isEmpty) {
      return const Center(
        child: Text(
          'Menunggu peserta lain...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Determine grid layout
    int crossAxisCount;
    if (allParticipants.length == 1) {
      crossAxisCount = 1;
    } else if (allParticipants.length <= 4) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 9,
      ),
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        return _buildParticipantTile(
          allParticipants[index],
          isLocal: index == 0 && _localParticipant != null,
        );
      },
    );
  }

  Widget _buildParticipantTile(Participant participant, {bool isLocal = false}) {
    // Get video track
    VideoTrack? videoTrack;
    final videoPublications = participant.videoTrackPublications
        .where((pub) => pub.source == TrackSource.camera)
        .toList();
    
    if (videoPublications.isNotEmpty && videoPublications.first.track != null) {
      videoTrack = videoPublications.first.track as VideoTrack;
    }

    // Check mic status
    final isMuted = participant.audioTrackPublications
        .where((pub) => pub.source == TrackSource.microphone)
        .every((pub) => pub.muted || pub.track == null);

    final hasVideo = videoTrack != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or placeholder
          if (hasVideo)
            VideoTrackRenderer(
              videoTrack,
            )
          else
            _buildNoVideoPlaceholder(participant.identity),

          // Name label
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLocal ? 'Anda' : participant.identity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  if (isLocal && !_isFrontCamera) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Belakang',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Mic/camera status
          Positioned(
            right: 8,
            top: 8,
            child: Row(
              children: [
                if (isMuted)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                if (!hasVideo) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.videocam_off,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVideoPlaceholder(String identity) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              (identity.isNotEmpty ? identity[0] : '?').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.black.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
            isActive: _isMicEnabled,
            onPressed: _toggleMicrophone,
            label: 'Mic',
          ),
          _buildControlButton(
            icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            isActive: _isCameraEnabled,
            onPressed: _toggleCamera,
            label: 'Kamera',
          ),
          _buildControlButton(
            icon: Icons.cameraswitch,
            isActive: true,
            onPressed: _switchCamera,
            label: 'Putar',
            isEnabled: _isCameraEnabled,
          ),
          _buildControlButton(
            icon: _isChatOpen ? Icons.chat : Icons.chat_bubble_outline,
            isActive: _isChatOpen,
            onPressed: _toggleChat,
            label: 'Chat',
            isHighlighted: _isChatOpen,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            isActive: false,
            onPressed: _leaveRoom,
            label: 'Keluar',
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String label,
    bool isDestructive = false,
    bool isEnabled = true,
    bool isHighlighted = false,
  }) {
    Color? bgColor;
    if (isDestructive) {
      bgColor = Colors.red;
    } else if (isHighlighted) {
      bgColor = const Color(0xFF2563EB); // blue-600 for highlighted chat
    } else if (isActive) {
      bgColor = Colors.grey[800];
    } else {
      bgColor = Colors.red;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isEnabled ? onPressed : null,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? bgColor : Colors.grey[700],
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey[500],
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
