import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'upload_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  FlashMode _flashMode = FlashMode.auto;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      // Use the first back camera if available, otherwise the first camera found
      CameraDescription? selectedCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= _cameras.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        // Set default flash mode
        await _controller!.setFlashMode(_flashMode);
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before camera was initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    
    FlashMode nextMode;
    String modeText;
    
    if (_flashMode == FlashMode.auto) {
      nextMode = FlashMode.always;
      modeText = 'ALWAYS ON';
    } else if (_flashMode == FlashMode.always) {
      nextMode = FlashMode.off;
      modeText = 'OFF';
    } else {
      nextMode = FlashMode.auto;
      modeText = 'AUTO';
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flash Mode: $modeText'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Failed to set flash mode: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();
      
      // Save image to permanent documents directory to prevent OS cleanup/deletion
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String savePath = '${extDir.path}/captured_skin_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(file.path).copy(savePath);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadScreen(initialImagePath: savePath),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  String _getFlashLabel() {
    switch (_flashMode) {
      case FlashMode.auto:
        return 'FLASH AUTO';
      case FlashMode.always:
        return 'FLASH ON';
      case FlashMode.off:
      default:
        return 'FLASH OFF';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 10,
              left: 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.lightBackground,
                    size: 36,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text('Capture Skin', style: AppTextStyles.appBarTitle),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // Camera View Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: MediaQuery.of(context).size.width - 48, // Make it a square
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Live Camera Preview
                        if (_isInitialized && _controller != null)
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: _controller!.value.previewSize!.height,
                                height: _controller!.value.previewSize!.width,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          )
                        else if (_errorMessage.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),

                        // Guideline Overlay Box in Center
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            // Corner brackets for guidance
                            child: Stack(
                              children: [
                                _buildCorner(Alignment.topLeft),
                                _buildCorner(Alignment.topRight),
                                _buildCorner(Alignment.bottomLeft),
                                _buildCorner(Alignment.bottomRight),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Divider line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    color: Colors.grey.withValues(alpha: 0.3),
                    thickness: 1,
                  ),
                ),

                const SizedBox(height: 20),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Spacer to balance the layout
                      const SizedBox(width: 70),

                      const Spacer(),

                      // Capture Button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBrown,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _isInitialized ? _takePicture : null,
                        ),
                      ),

                      const Spacer(),

                      // Flash Button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ]
                            ),
                            child: IconButton(
                              icon: Icon(
                                _getFlashIcon(),
                                color: Colors.black87,
                              ),
                              onPressed: _isInitialized ? _toggleFlash : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFlashLabel(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Security Notice
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 14,
                      color: Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your data is encrypted and analyzed securely by MycoTrack',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight)
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  )
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight)
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  )
                : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  )
                : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
