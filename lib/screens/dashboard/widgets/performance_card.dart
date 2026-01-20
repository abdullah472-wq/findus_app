import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PerformanceCard extends StatelessWidget {
  final String userId;

  const PerformanceCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_stats')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // যদি এরর হয় বা লোড হতে দেরি হয়, তবে ডিফল্ট ০ দেখাবে
        Map<String, dynamic> data = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        }

        final impressions = data['impressions'] ?? 0;
        final views = data['profileViews'] ?? 0;
        final hires = data['hires'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile Performance",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "How users are interacting with you",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _perfItem("Impressions", _format(impressions), Icons.visibility, Colors.blue),
                  _perfItem("Views", _format(views), Icons.person_search, Colors.green),
                  _perfItem("Hires", _format(hires), Icons.handshake, Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(dynamic val) {
    int n = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  Widget _perfItem(String label, String val, IconData icon, Color col) {
    return Column(
      children: [
        Icon(icon, color: col, size: 20),
        const SizedBox(height: 5),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}