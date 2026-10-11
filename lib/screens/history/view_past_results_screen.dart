import 'package:flutter/material.dart';
import '../../widgets/delete_dialog.dart';

class ViewPastResultsScreen extends StatelessWidget {
  const ViewPastResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EBD5),

      appBar: AppBar(
        backgroundColor: const Color(0xFF8D604F),
        elevation: 0,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "View Past Results",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          HistoryCard(
            prediction: "Melanoma",
            date: "24.01.2025",
            time: "01:30",
          ),

          SizedBox(height: 18),

          HistoryCard(
            prediction: "Tinea Corporis",
            date: "18.04.2025",
            time: "09:45",
          ),

          SizedBox(height: 18),

          HistoryCard(
            prediction: "Tinea Versicolor",
            date: "20.05.2025",
            time: "04:15",
          ),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final String prediction;
  final String date;
  final String time;

  const HistoryCard({
    super.key,
    required this.prediction,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8D604F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [

          // Placeholder Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE7D8C5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.photo,
              color: Color(0xFF8D604F),
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Prediction: $prediction",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        "Date: $date",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Text(
                      "Time: $time",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const DeleteDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}