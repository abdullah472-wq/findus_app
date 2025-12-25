import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  // 🔹 Demo earning history data
  List<Map<String, dynamic>> get _earnings => [
    {
      "date": "12 Dec 2024",
      "job": "Rickshaw Ride",
      "client": "Saiful Islam",
      "amount": 150.0,
      "status": "Completed",
    },
    {
      "date": "11 Dec 2024",
      "job": "Home Cleaning",
      "client": "Nazia Sultana",
      "amount": 800.0,
      "status": "Completed",
    },
    {
      "date": "10 Dec 2024",
      "job": "Electric Repair",
      "client": "Rakib Hasan",
      "amount": 1200.0,
      "status": "Completed",
    },
    {
      "date": "08 Dec 2024",
      "job": "Gardening Work",
      "client": "Jannat Ara",
      "amount": 500.0,
      "status": "Completed",
    },
    {
      "date": "05 Dec 2024",
      "job": "Office Cleaning",
      "client": "Creative IT",
      "amount": 2000.0,
      "status": "Completed",
    },
    {
      "date": "02 Dec 2024",
      "job": "Food Delivery",
      "client": "Habib Ullah",
      "amount": 300.0,
      "status": "Completed",
    },
    {
      "date": "30 Nov 2024",
      "job": "Painting Job",
      "client": "Abdul Karim",
      "amount": 1800.0,
      "status": "Completed",
    },
  ];

  double get _totalEarned =>
      _earnings.fold(0.0, (p, e) => p + (e['amount'] as double));

  int get _totalJobs => _earnings.length;

  @override
  Widget build(BuildContext context) {
    final totalText = _totalEarned.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earning History"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // 🔹 Summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Left summary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Earned (demo)",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "৳ $totalText",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$_totalJobs jobs completed",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right side icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.brandDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 History list
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              itemCount: _earnings.length,
              itemBuilder: (context, index) {
                final e = _earnings[index];
                return _buildEarningCard(e);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(Map<String, dynamic> e) {
    final String date = e['date'] as String;
    final String job = e['job'] as String;
    final String client = e['client'] as String;
    final double amount = e['amount'] as double;
    final String status = e['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Left icon + date
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.brandDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          // Middle: job + client + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Client: $client",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "৳ ${amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}