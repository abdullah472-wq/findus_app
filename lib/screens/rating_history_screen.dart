import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class RatingHistoryScreen extends StatefulWidget {
  const RatingHistoryScreen({super.key});

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen> {
  // 🔹 Demo reviews (পরে API থেকে আসল data আনবে)
  final List<Map<String, dynamic>> _allReviews = [
    {
      "name": "Saiful Islam",
      "job": "Rickshaw Ride",
      "rating": 5,
      "date": "12 Dec 2024",
      "comment": "Very polite, came on time and completed the ride safely.",
    },
    {
      "name": "Nazia Sultana",
      "job": "Home Cleaning",
      "rating": 4,
      "date": "10 Dec 2024",
      "comment":
      "Good service overall. Could improve on speed but quality was nice.",
    },
    {
      "name": "Rakib Hasan",
      "job": "Electric Repair",
      "rating": 5,
      "date": "08 Dec 2024",
      "comment": "Expert in work. Fixed the problem very quickly.",
    },
    {
      "name": "Jannat Ara",
      "job": "Gardening",
      "rating": 3,
      "date": "05 Dec 2024",
      "comment":
      "Average work. Some plants were not trimmed properly, but okay.",
    },
    {
      "name": "Abdul Karim",
      "job": "Furniture Moving",
      "rating": 2,
      "date": "01 Dec 2024",
      "comment":
      "Came late and communication was weak. Work was done but not smooth.",
    },
    {
      "name": "Mitu Akter",
      "job": "Cooking Help",
      "rating": 4,
      "date": "28 Nov 2024",
      "comment": "Tasty food and maintained hygiene properly.",
    },
    {
      "name": "Habib Ullah",
      "job": "Painting Job",
      "rating": 5,
      "date": "25 Nov 2024",
      "comment": "Excellent painting and finishing. Highly recommended.",
    },
  ];

  int? _selectedStar; // null = All

  double get _averageRating {
    if (_allReviews.isEmpty) return 0.0;
    final sum =
    _allReviews.fold<double>(0, (p, e) => p + (e['rating'] as int).toDouble());
    return sum / _allReviews.length;
  }

  int get _totalReviews => _allReviews.length;

  // প্রতিটি স্টারের count
  Map<int, int> get _starCounts {
    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _allReviews) {
      final int s = r['rating'] as int;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> get _filteredReviews {
    if (_selectedStar == null) return _allReviews;
    return _allReviews.where((r) => r['rating'] == _selectedStar).toList();
  }

  void _selectStarFilter(int? star) {
    setState(() {
      _selectedStar = star;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avg = _averageRating;
    final avgText = avg.toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rating & Reviews"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // 🔹 উপরে summary card
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
                  // Average rating বড় করে
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avgText,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStars(avg.round(), size: 18),
                      const SizedBox(height: 4),
                      Text(
                        "$_totalReviews reviews",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // প্রতিটি স্টারের count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (index) {
                      final star = 5 - index;
                      final count = _starCounts[star] ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$star★",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: _totalReviews == 0
                                  ? 0
                                  : count / _totalReviews,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.amber,
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Filter chips: All, 5★, 4★, 3★, 2★, 1★
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: _selectedStar == null,
                  onSelected: (_) => _selectStarFilter(null),
                ),
                const SizedBox(width: 6),
                ...List.generate(5, (i) {
                  final star = 5 - i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text("$star★"),
                      selected: _selectedStar == star,
                      onSelected: (_) => _selectStarFilter(star),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Reviews list
          Expanded(
            child: _filteredReviews.isEmpty
                ? const Center(
              child: Text(
                "No reviews for this filter.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 5),
              itemCount: _filteredReviews.length,
              itemBuilder: (context, index) {
                final r = _filteredReviews[index];
                return _buildReviewCard(r);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating, {double size = 16}) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? Colors.amber : Colors.grey.shade400,
          size: size,
        );
      }),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    final int rating = r['rating'] as int;
    final String name = r['name'] as String;
    final String job = r['job'] as String;
    final String date = r['date'] as String;
    final String comment = r['comment'] as String;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // উপরে নাম + rating + তারিখ
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              _buildStars(rating, size: 14),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            job,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}