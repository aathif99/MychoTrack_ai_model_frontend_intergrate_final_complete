import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/api_service.dart';
import '../services/classifier_service.dart';
import 'analysis_result_screen.dart';

class UploadScreen extends StatefulWidget {
  final bool openCamera;
  final String? initialImagePath;
  const UploadScreen({super.key, this.openCamera = false, this.initialImagePath});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  String _captureMethod = 'Gallery';
  final ImagePicker _picker = ImagePicker();
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Warm up the TFLite model in the background so inference is instant
    ClassifierService().initialize();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
      _captureMethod = 'Camera';
    } else if (widget.openCamera) {
      _pickImage(ImageSource.camera);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _captureMethod = source == ImageSource.camera ? 'Camera' : 'Gallery';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _analyseImage() async {
    if (_selectedImage == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });
    _spinController.repeat();

    try {
      // Give the UI a frame to render the loading spinner before running inference
      await Future.delayed(const Duration(milliseconds: 50));

      // 1. Instant on-device classification & heatmap generation (~200ms)
      final localResult = await ClassifierService().predictImage(
        _selectedImage!.path,
        captureMethod: _captureMethod,
      );

      // 2. Asynchronously sync scan to AWS MySQL in the background (non-blocking)
      ApiService().syncDetection(
        imagePath: _selectedImage!.path,
        prediction: localResult,
        captureMethod: _captureMethod,
      ).then((syncRes) {
        if (syncRes['success']) {
          print('✅ Scan synced to AWS MySQL database.');
        } else {
          print('ℹ️ Cloud sync info: ${syncRes['message']}');
        }
      }).catchError((err) {
        print('⚠️ Cloud sync background error: $err');
      });

      if (mounted) {
        _spinController.stop();
        setState(() {
          _isLoading = false;
        });

        // 3. Immediately show results to the user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(
              predictionResult: localResult,
            ),
          ),
        );
      }
    } catch (e) {
      print('On-device prediction error: $e');
      if (mounted) {
        _spinController.stop();
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
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
                const Text('Upload Image', style: AppTextStyles.appBarTitle),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Upload Container
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E9),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                          // Show loading overlay on top of image
                          if (_isLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RotationTransition(
                                      turns: _spinController,
                                      child: const Icon(
                                        Icons.autorenew_rounded,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Analysing...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Select an image to analyse',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 40),
              
              if (_selectedImage == null) ...[
                _buildActionButton(context, 'Choose from Gallery', () => _pickImage(ImageSource.gallery)),
              ] else ...[
                _buildActionButton(
                  context,
                  _isLoading ? 'Analysing...' : 'Analyse Image',
                  _isLoading ? null : _analyseImage,
                  isAnalyzing: _isLoading,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  _captureMethod == 'Camera' ? 'Capture Again' : 'Change Image',
                  _isLoading ? null : () {
                    if (_captureMethod == 'Camera') {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _selectedImage = null;
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              _buildActionButton(context, 'Cancel', _isLoading ? null : () {
                Navigator.pop(context);
              }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    VoidCallback? onPressed, {
    bool isAnalyzing = false,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? AppColors.primaryBrown.withValues(alpha: 0.7)
              : AppColors.primaryBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isAnalyzing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _spinController,
                    child: const Icon(
                      Icons.autorenew_rounded,
                      color: AppColors.lightBackground,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Analysing...',
                    style: TextStyle(
                      color: AppColors.lightBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  color: AppColors.lightBackground,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
