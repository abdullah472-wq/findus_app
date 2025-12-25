import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart'; // সফল হলে চ্যাটে নিয়ে যাব
import 'package:findus_app/services/notification_service.dart'; // 🔹 NEW: notification service import

class HireRequestScreen extends StatefulWidget {
  final Worker worker; // যাকে হায়ার করা হচ্ছে তার ডাটা

  const HireRequestScreen({super.key, required this.worker});

  @override
  State<HireRequestScreen> createState() => _HireRequestScreenState();
}

class _HireRequestScreenState extends State<HireRequestScreen> {
  String _selectedWorkType = 'Urgent'; // Urgent or Scheduled
  double _offerPrice = 100.0; // ডিফল্ট অফার প্রাইস
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  // --- রিকোয়েস্ট পাঠানোর লজিক + Firebase notification ---
  Future<void> _sendRequest() async {
    if (_detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your problem briefly")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔹 hire_request notification পাঠানো হবে worker এর কাছে
      await NotificationService.sendNotificationToUser(
        toUserId: widget.worker.id, // worker-এর uid / id
        title: "New hire request",
        body:
        "You have a new ${_selectedWorkType.toLowerCase()} hire request.",
        type: "hire_request",
        status: "pending", // শুরুতে pending
        data: {
          'workType': _selectedWorkType,          // Urgent / Scheduled
          'offerPrice': _offerPrice,              // অফার প্রাইস
          'details': _detailsController.text,     // সমস্যা/কাজের বর্ণনা
        },
        // fromUserId ফাঁকা রেখে দিলে NotificationService নিজে currentUser.uid বসাবে
      );

      // সফল হলে সাকসেস ডায়ালগ
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request. Please try again.\n$e")),
      );
    }
  }

  // --- সাকসেস ডায়ালগ (অ্যানিমেশন সহ) ---
  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // সাকসেস আইকন (অ্যানিমেটেড এফেক্ট)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 80),
            ),
            const SizedBox(height: 20),
            const Text("Request Sent!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark)),
            const SizedBox(height: 10),
            Text(
              "Your request has been sent to ${widget.worker.name}.\nPlease wait for approval.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // চ্যাটে যাওয়ার বাটন
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // ডায়ালগ বন্ধ
                    Navigator.pop(context); // রিকোয়েস্ট পেজ বন্ধ

                    // চ্যাট স্ক্রিনে নিয়ে যাওয়া হচ্ছে
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: widget.worker.id, // 🔹 এখানে widget.worker
                          userName: widget.worker.name,
                          userRole: widget.worker.role,
                          userImage: widget.worker.image,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Go to Chat",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.bgBlue, // একদম হালকা গ্রে ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text("Hire Details",
            style: TextStyle(
                color: AppColors.brandDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.brandLight,
        elevation: 0.5,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new, color: AppColors.brandDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. ওয়ার্কার ইনফো কার্ড
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.worker.image,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60,
                        width: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
                title: Text(
                  "Hiring ${widget.worker.name}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                subtitle: Text(
                  widget.worker.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ২. কাজের বিবরণ (Text Field)
            const Text("Describe the issue",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark)),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                "Ex: My kitchen tap is leaking, need urgent fix...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 25),

            // ৩. সময় নির্বাচন (Chips)
            const Text("When do you need it?",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChip("Urgent (Now)", "Urgent"),
                const SizedBox(width: 15),
                _buildChip("Schedule Later", "Scheduled"),
              ],
            ),

            const SizedBox(height: 25),

            // ৪. প্রাইস অফার (Slider)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Offer Price",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark)),
                Text(
                  "৳ ${_offerPrice.toInt()}",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandMain),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.brandMain,
                inactiveTrackColor: AppColors.brandLight,
                thumbColor: AppColors.brandDark,
                overlayColor: AppColors.brandMain.withOpacity(0.2),
              ),
              child: Slider(
                value: _offerPrice,
                min: 50,
                max: 2000,
                divisions: 39, // 50 করে করে বাড়বে
                label: _offerPrice.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _offerPrice = value;
                  });
                },
              ),
            ),
            Center(
              child: Text(
                "Base Charge starts from ${widget.worker.price}",
                style:
                const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 40),

            // ৫. সেন্ড বাটন
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _sendRequest(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Send Request",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.send_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // চিপ বাটন ডিজাইন (Urgent/Schedule)
  Widget _buildChip(String label, String value) {
    bool isSelected = _selectedWorkType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWorkType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandMain : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? AppColors.brandMain
                    : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}