import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../models/prediction_result.dart';
import '../utils/constants.dart';
import '../utils/date_time_utils.dart';

class AnalysisResultScreen extends StatefulWidget {
  final PredictionResult predictionResult;

  const AnalysisResultScreen({super.key, required this.predictionResult});

  static String formatDiseaseName(String diseaseName) {
    final normalized = diseaseName.trim().toLowerCase();

    if (normalized.contains('versicolor') ||
        normalized.contains('versicolar')) {
      return 'Tinea Versicolor';
    }
    if (normalized.contains('cruris')) {
      return 'Tinea Cruris';
    }
    if (normalized.contains('ringworm') || normalized.contains('rinworm')) {
      return 'Ringworm';
    }

    return diseaseName.trim().isEmpty ? 'Unknown' : diseaseName.trim();
  }

  static String getRiskLevel(String diseaseName) {
    final normalized = diseaseName.toLowerCase();

    if (normalized.contains('versicolor') ||
        normalized.contains('versicolar')) {
      return 'Low Risk';
    }
    if (normalized.contains('cruris') ||
        normalized.contains('ringworm') ||
        normalized.contains('rinworm')) {
      return 'Moderate Risk';
    }

    return 'Unknown';
  }

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _showHeatmap = true;

  Widget _buildHeatmapImage() {
    if (widget.predictionResult.heatmapBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(
          widget.predictionResult.heatmapBase64.replaceFirst(
            RegExp(r'data:image/[^;]+;base64,'),
            '',
          ),
        ),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    } else if (widget.predictionResult.heatmapUrl.isNotEmpty) {
      final url = widget.predictionResult.heatmapUrl.startsWith('http')
          ? widget.predictionResult.heatmapUrl
          : '${AppConstants.serverUrl}${widget.predictionResult.heatmapUrl}';
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          print('⚠️ Failed to load heatmap from network: $error (URL: $url)');
          return const SizedBox.shrink();
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOriginalImage() {
    final imageUrl = widget.predictionResult.imageUrl;
    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    }

    // Check if it's a local file on device
    try {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        );
      }
    } catch (_) {}

    return Image.network(
      '${AppConstants.serverUrl}$imageUrl',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diseaseName = AnalysisResultScreen.formatDiseaseName(widget.predictionResult.diseaseName);
    final hasHeatmap = widget.predictionResult.heatmapBase64.isNotEmpty ||
        widget.predictionResult.heatmapUrl.isNotEmpty;

    // Format predicted date and time
    DateTime? localDateTime = DateTimeUtils.parseToLocal(
      widget.predictionResult.detectionDate,
      widget.predictionResult.detectionTime,
    );
    localDateTime ??= DateTime.now();

    final formattedDate = DateTimeUtils.formatDate(localDateTime);
    final formattedTime = DateTimeUtils.formatTime(localDateTime);

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
                const Text('Analysis Result', style: AppTextStyles.appBarTitle),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Image Container (with Heatmap toggle button at top right corner)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 320,
                      color: Colors.black12,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Layer 1: Permanent original image base - never reloads, never shifts, never shrinks
                          _buildOriginalImage(),

                          // Layer 2: Transparent heatmap overlay with smooth animated fade
                          if (hasHeatmap)
                            AnimatedOpacity(
                              opacity: _showHeatmap ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _buildHeatmapImage(),
                            ),

                          // Single toggle button at top right corner
                          if (hasHeatmap)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showHeatmap = !_showHeatmap;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBrown.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.lightBackground.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _showHeatmap
                                              ? Icons.layers_clear_outlined
                                              : Icons.layers_outlined,
                                          size: 16,
                                          color: AppColors.lightBackground,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _showHeatmap ? 'Hide heatmap' : 'Show heatmap',
                                          style: const TextStyle(
                                            color: AppColors.lightBackground,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Result Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PREDICTED DISEASE',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    diseaseName,
                                    style: const TextStyle(
                                      color: AppColors.primaryBrown,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBrown.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.health_and_safety_outlined,
                                color: AppColors.primaryBrown,
                                size: 32,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Date and Time Info Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F6F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEBE0CD)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.primaryBrown,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Date: $formattedDate',
                                    style: const TextStyle(
                                      color: AppColors.primaryBrown,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.primaryBrown,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Time: $formattedTime',
                                    style: const TextStyle(
                                      color: AppColors.primaryBrown,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Confidence Score',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.predictionResult.confidenceScore.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: AppColors.primaryBrown,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: widget.predictionResult.confidenceScore / 100,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBrown,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Medical Disclaimer
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Medical Disclaimer: ',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: 'This app is not a medical diagnostic tool; please consult a doctor for an accurate diagnosis.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


