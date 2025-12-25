import 'package:flutter/material.dart';
import '../models/worker_model.dart';

class CustomMarkerWidget extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;

  const CustomMarkerWidget({
    super.key,
    required this.worker,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Price Tag (উপরে টাকার পরিমাণ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107), // Amber color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Text(
              worker.price,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
              ),
            ),
          ),

          // 2. Pin & Image (মাঝখানে পিন এবং ছবি)
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // পিনের আইকন
              const Icon(Icons.location_on, size: 65, color: Colors.redAccent),

              // ব্যবহারকারীর ছবি
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(worker.image),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),

              // ভেরিফাইড ব্যাজ (একদম নিচে ছোট্ট টিক চিহ্ন)
              const Positioned(
                bottom: 14,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.verified, size: 14, color: Colors.blue),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}