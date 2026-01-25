import 'package:flutter/material.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class WorkerCVCreateScreen extends StatefulWidget {
  final Worker worker;
  const WorkerCVCreateScreen({super.key, required this.worker});

  @override
  State<WorkerCVCreateScreen> createState() => _WorkerCVCreateScreenState();
}

class _WorkerCVCreateScreenState extends State<WorkerCVCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _summaryController = TextEditingController();
  final List<TextEditingController> _experienceControllers = [TextEditingController()];
  final List<TextEditingController> _educationControllers = [TextEditingController()];
  final List<TextEditingController> _skillControllers = [TextEditingController()];

  bool _isSaving = false;

  @override
  void dispose() {
    _summaryController.dispose();
    for (var c in _experienceControllers) c.dispose();
    for (var c in _educationControllers) c.dispose();
    for (var c in _skillControllers) c.dispose();
    super.dispose();
  }

  // সিভি সেভ করার লজিক
  Future<void> _saveCV() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final cvData = {
        'summary': _summaryController.text.trim(),
        'experiences': _experienceControllers.map((c) => c.text.trim()).toList(),
        'education': _educationControllers.map((c) => c.text.trim()).toList(),
        'skills': _skillControllers.map((c) => c.text.trim()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ফায়ারবেসে ইউজারের ডকুমেন্টে cv_data হিসেবে সেভ হবে
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'cv_data': cvData,
        'has_created_cv': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CV Created & Saved Successfully!"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড ভেরিয়েবলস
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.black87;

    return FloatingScaffold(
      title: "CREATE PROFESSIONAL CV",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.all(16),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Professional Summary", textColor),
            _buildTextField(_summaryController, "Write a short summary about yourself...", isDark, cardColor, textColor, maxLines: 3),

            const SizedBox(height: 20),
            _buildDynamicSection("Experience", _experienceControllers, "e.g. 2 Years as Electrician at ABC Co.", textColor, cardColor, isDark),

            const SizedBox(height: 20),
            _buildDynamicSection("Education", _educationControllers, "e.g. Diploma in Electrical Engineering", textColor, cardColor, isDark),

            const SizedBox(height: 20),
            _buildDynamicSection("Skills", _skillControllers, "e.g. House Wiring, AC Repair", textColor, cardColor, isDark),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCV,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SAVE CV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // সেকশন টাইটেল উইজেট
  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  // টেক্সট ফিল্ড হেল্পার
  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, Color fillColor, Color textColor, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? "This field is required" : null,
    );
  }

  // ডায়নামিক লিস্ট সেকশন
  Widget _buildDynamicSection(String title, List<TextEditingController> controllers, String hint, Color textColor, Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(title, textColor),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.brandMain),
              onPressed: () => setState(() => controllers.add(TextEditingController())),
            ),
          ],
        ),
        ...controllers.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _buildTextField(entry.value, hint, isDark, cardColor, textColor)),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    onPressed: () => setState(() => controllers.removeAt(idx)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}