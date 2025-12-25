import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/saved_service.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  // নির্দিষ্ট role (কীওয়ার্ড) অনুযায়ী সেভকৃত worker ফিল্টার করবে
  List<Map<String, dynamic>> _getSavedWorkersByRole(List<String> roles) {
    return SavedService.savedWorkers.where((worker) {
      String workerRole = worker['role']?.toString().toUpperCase() ?? '';
      return roles.any((role) => workerRole.contains(role));
    }).toList();
  }

  // ফোন কল helper
  Future<void> _callWorker(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: trimmed);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open dialer.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open dialer.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // পুরো ব্যাকগ্রাউন্ড কালার
      body: ListView(
        padding: const EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: 80,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: Text(
              "Saved Profiles",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),

          // ১. FARMER / GARDENER
          _buildCategoryItem(
            context,
            title: "FARMER & GARDENER",
            color: Colors.cyan.shade100,
            iconImage:
            "https://cdn-icons-png.flaticon.com/512/3022/3022999.png",
            initiallyExpanded: true,
            workersData: _getSavedWorkersByRole(
              ['FARMER', 'GARDEN', 'কৃষক'],
            ),
          ),

          // ২. PAINTER
          _buildCategoryItem(
            context,
            title: "PAINTER",
            color: Colors.orange.shade100,
            iconImage:
            "https://cdn-icons-png.flaticon.com/512/2972/2972117.png",
            initiallyExpanded: true,
            workersData: _getSavedWorkersByRole(
              ['PAINTER', 'COLOR', 'রং', 'MISTRI'],
            ),
          ),

          // ৩. SHOPPER / BAZAR
          _buildCategoryItem(
            context,
            title: "SHOPPER",
            color: Colors.green.shade100,
            iconImage:
            "https://cdn-icons-png.flaticon.com/512/3022/3022856.png",
            initiallyExpanded: true,
            workersData: _getSavedWorkersByRole(
              ['SHOPPER', 'BAZAR', 'বাজার'],
            ),
          ),

          // ৪. RICKSHAW
          _buildCategoryItem(
            context,
            title: "RIKSHAW",
            color: Colors.purple.shade100,
            iconImage:
            "https://cdn-icons-png.flaticon.com/512/3022/3022856.png",
            initiallyExpanded: false,
            workersData: _getSavedWorkersByRole(
              ['RICKSHAW', 'DRIVER', 'রিকশা'],
            ),
          ),
        ],
      ),
    );
  }

  // ক্যাটাগরি বিল্ডার
  Widget _buildCategoryItem(
      BuildContext context, {
        required String title,
        required Color color,
        required String iconImage,
        required bool initiallyExpanded,
        required List<Map<String, dynamic>> workersData,
      }) {
    if (workersData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          leading: Image.network(
            iconImage,
            width: 50,
            height: 50,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, size: 50),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF004D40),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              "${workersData.length}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F7FA),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Column(
                children: workersData
                    .map((data) => _buildWorkerCard(context, data))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ওয়ার্কার কার্ড (logic + UI fixed)
  Widget _buildWorkerCard(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    final String name = data['name']?.toString() ?? "Unknown";
    final String role = data['role']?.toString() ?? "Worker";
    final String price = data['price']?.toString() ?? "N/A";
    final String time = data['time']?.toString() ?? "Anytime";

    final String location = (data['address'] ??
        data['location'] ??
        "Gazipur, Bangladesh")
        .toString();

    final String imgUrl =
        data['image']?.toString() ?? "https://i.pravatar.cc/150";

    final String ratingStr = data['rating']?.toString() ?? "4.0";
    final String reviews = data['reviews']?.toString() ?? "0";
    final String completed = data['completed']?.toString() ?? "0";

    final double rating = double.tryParse(ratingStr) ?? 0.0;

    // ফোন নাম্বার (যদি থাকে)
    final String phone = data['phone']?.toString() ??
        data['phoneNumber']?.toString() ??
        "";

    // প্রোফাইল ওপেন হলে Worker অবজেক্ট
    final worker = Worker(
      id: "", // future: Firestore uid দিতে পারো
      name: name,
      role: role,
      image: imgUrl,
      rating: rating,
      price: price,
      location: location,
    );

    return GestureDetector(
      onTap: () {
        // প্রোফাইল পেজে যাওয়া
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerProfileScreen(
              worker: worker,
              phoneNumber: phone.isNotEmpty ? phone : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.teal.shade100),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(imgUrl),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Verified",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    _statItem(Icons.settings, completed, "Done"),
                    const SizedBox(width: 10),
                    _statItem(Icons.star, ratingStr, "Rate"),
                    const SizedBox(width: 10),
                    _statItem(Icons.reviews, reviews, "Rev"),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final convId =
                        phone.isNotEmpty ? phone : name;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convId,
                              userName: name,
                              userRole: role,
                              userImage: imgUrl,
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.chat,
                        size: 25,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: phone.isNotEmpty
                          ? () => _callWorker(phone)
                          : null,
                      child: Icon(
                        Icons.phone_in_talk,
                        size: 25,
                        color: phone.isNotEmpty
                            ? const Color(0xFF004D40)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String val, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: const Color(0xFF004D40),
        ),
        Text(
          " $val",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}