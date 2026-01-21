import 'package:flutter/material.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    for (var c in _experienceControllers) {
      c.dispose();
    }
    for (var c in _educationControllers) {
      c.dispose();
    }
    for (var c in _skillControllers) {
      c.dispose();
    }
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
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Professional CV"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Professional Summary"),
              _buildTextField(_summaryController, "Write a short summary about yourself...", maxLines: 3),

              const SizedBox(height: 20),
              _buildDynamicSection("Experience", _experienceControllers, "e.g. 2 Years as Electrician at ABC Co."),

              const SizedBox(height: 20),
              _buildDynamicSection("Education", _educationControllers, "e.g. Diploma in Electrical Engineering"),

              const SizedBox(height: 20),
              _buildDynamicSection("Skills", _skillControllers, "e.g. House Wiring, AC Repair"),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCV,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE CV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // সেকশন টাইটেল উইজেট
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
    );
  }

  // টেক্সট ফিল্ড হেল্পার
  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? "This field is required" : null,
    );
  }

  // ডায়নামিক লিস্ট সেকশন (যোগ/বিয়োগ করা যাবে)
  Widget _buildDynamicSection(String title, List<TextEditingController> controllers, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(title),
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
                Expanded(child: _buildTextField(entry.value, hint)),
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