import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // ডেমো ডাটা – ভবিষ্যতে Firestore থেকে আনতে পারো
  List<double> get _weeklyImpressions => [120, 180, 220, 160, 260, 300, 250];
  List<double> get _weeklyChats => [10, 14, 18, 12, 22, 26, 20];
  List<double> get _weeklyHires => [2, 3, 4, 3, 5, 6, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.bgBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Analytics",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(),
              const SizedBox(height: 16),
              _buildLineChartCard(),
              const SizedBox(height: 16),
              _buildBarChartCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --------- Top summary cards ---------
  Widget _buildSummaryRow() {
    final totalImpressions =
    _weeklyImpressions.reduce((a, b) => a + b).toInt();
    final totalChats = _weeklyChats.reduce((a, b) => a + b).toInt();
    final totalHires = _weeklyHires.reduce((a, b) => a + b).toInt();

    final double ctr =
    totalImpressions == 0 ? 0 : (totalChats / totalImpressions) * 100;
    final double hireRate =
    totalChats == 0 ? 0 : (totalHires / totalChats) * 100;

    return Row(
      children: [
        _summaryCard(
          label: "Total Views",
          value: "$totalImpressions",
          icon: Icons.remove_red_eye_outlined,
        ),
        const SizedBox(width: 8),
        _summaryCard(
          label: "Chat rate",
          value: "${ctr.toStringAsFixed(1)}%",
          icon: Icons.chat_bubble_outline,
        ),
        const SizedBox(width: 8),
        _summaryCard(
          label: "Hire rate",
          value: "${hireRate.toStringAsFixed(1)}%",
          icon: Icons.handshake_outlined,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandLight.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.brandDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------- Line chart (Impressions / Chats) ---------
  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last 7 days traffic",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Impressions & chats trend (demo)",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _weeklyImpressions.reduce((a, b) => max(a, b)) + 50,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 100,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Impressions line
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.brandMain,
                    barWidth: 3,
                    spots: List.generate(
                      _weeklyImpressions.length,
                          (i) => FlSpot(i.toDouble(), _weeklyImpressions[i]),
                    ),
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                      AppColors.brandMain.withOpacity(0.15),
                    ),
                  ),
                  // Chats line
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    spots: List.generate(
                      _weeklyChats.length,
                          (i) => FlSpot(i.toDouble(), _weeklyChats[i] * 10),
                    ),
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _LegendDot(color: AppColors.brandMain, label: 'Impressions'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.orange, label: 'Chats (x10)'),
            ],
          ),
        ],
      ),
    );
  }

  // --------- Bar chart (Hires per day) ---------
  Widget _buildBarChartCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily hires / responses",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "How many times workers responded or got hired",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_weeklyHires.reduce(max) + 2).toDouble(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_weeklyHires.length, (i) {
                  final y = _weeklyHires[i].toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: y,
                        width: 14,
                        color: AppColors.brandMain,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ছোট legend dot widget
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}