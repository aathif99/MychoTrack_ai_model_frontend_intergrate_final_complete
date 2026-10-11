import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/api_service.dart';
import 'analysis_result_screen.dart';

class UploadScreen extends StatefulWidget {
  final bool openCamera;
  final String? initialImagePath;
  const UploadScreen({super.key, this.openCamera = false, this.initialImagePath});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String _captureMethod = 'Gallery';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
      _captureMethod = 'Camera';
    } else if (widget.openCamera) {
      _pickImage(ImageSource.camera);
    }
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
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService().predict(_selectedImage!.path, _captureMethod);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(
              predictionResult: result['result'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
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
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
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
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primaryBrown))
              else ...[
                if (_selectedImage == null) ...[
                  _buildActionButton(context, 'Choose from Gallery', () => _pickImage(ImageSource.gallery)),
                ] else ...[
                  _buildActionButton(context, 'Analyse Image', _analyseImage),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    context,
                    _captureMethod == 'Camera' ? 'Capture Again' : 'Change Image',
                    () {
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
                    _buildActionButton(context, 'Cancel', () {
                      Navigator.pop(context);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
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
