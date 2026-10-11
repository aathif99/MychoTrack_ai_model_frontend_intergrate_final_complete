import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/api_service.dart';
import '../models/history_item.dart';
import '../models/prediction_result.dart';
import '../utils/constants.dart';
import '../utils/date_time_utils.dart';
import 'analysis_result_screen.dart';

class PastResultsScreen extends StatefulWidget {
  const PastResultsScreen({super.key});

  @override
  State<PastResultsScreen> createState() => _PastResultsScreenState();
}

class _PastResultsScreenState extends State<PastResultsScreen> {
  late Future<List<HistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService().getHistory();
    });
  }

  void _deleteItem(int id) async {
    final success = await ApiService().deleteHistory(id);
    if (success) {
      _showDeleteSuccessDialog(context);
      _loadHistory(); // Reload the list
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete record')),
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
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.lightBackground, size: 36),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'View Past Results',
                  style: TextStyle(
                    fontSize: 34,
                    color: AppColors.lightBackground,
                    fontFamily: 'Federant',
                  ),
                ),
              ],
            ),
          ),
          
          // Results List
          Expanded(
            child: FutureBuilder<List<HistoryItem>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBrown));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No past results found.', style: AppTextStyles.bodyGrey));
                }

                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    // Parse date and time accurately to phone local time
                    final localDateTime = DateTimeUtils.parseToLocal(item.detectionDate, item.detectionTime);
                    
                    final formattedDate = DateTimeUtils.formatDate(
                      localDateTime,
                      fallback: item.detectionDate.contains('T') ? item.detectionDate.split('T')[0] : item.detectionDate,
                    );
                    final formattedTime = DateTimeUtils.formatTime(
                      localDateTime,
                      fallback: item.detectionTime.length >= 5 ? item.detectionTime.substring(0, 5) : item.detectionTime,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: _buildResultCard(
                        imagePath: item.imagePath,
                        heatmapPath: item.heatmapPath,
                        prediction: item.diseaseClass,
                        date: formattedDate,
                        time: formattedTime,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalysisResultScreen(
                                predictionResult: PredictionResult.fromHistoryItem(item),
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          _showDeleteConfirmationDialog(context, item.detectionId);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFFF6F0E6), // Match profile screen dialog bg
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure want\nto delete?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBrown,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEBE0CD), // Light beige
                          foregroundColor: AppColors.primaryBrown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          _deleteItem(id); // Execute delete
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3B21), // Dark brown
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Delete', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AppColors.lightBackground, // Solid background
      builder: (BuildContext context) {
        // Automatically close after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Successfully\ndeleted!!!',
                textAlign: TextAlign.center,
                style: AppTextStyles.appBarTitle.copyWith(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard({
    required String imagePath,
    required String heatmapPath,
    required String prediction,
    required String date,
    required String time,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    // Show heatmap thumbnail if available, otherwise original image
    final displayImagePath = heatmapPath.isNotEmpty ? heatmapPath : imagePath;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBrown,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image thumbnail
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.black26, // Placeholder background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: displayImagePath.isNotEmpty
                      ? Image.network(
                          '${AppConstants.serverUrl}$displayImagePath',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.white54),
                        )
                      : const Icon(Icons.image, color: Colors.white54),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Prediction:  $prediction',
                              style: const TextStyle(
                                color: AppColors.lightBackground,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            CupertinoIcons.delete,
                            color: AppColors.lightBackground,
                            size: 32,
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: $date',
                          style: const TextStyle(
                            color: AppColors.lightBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Time: $time',
                          style: const TextStyle(
                            color: AppColors.lightBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

