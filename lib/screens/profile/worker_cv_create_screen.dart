import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class WorkerCVCreateScreen extends StatefulWidget {
  final Worker worker;
  const WorkerCVCreateScreen({super.key, required this.worker});

  @override
  State<WorkerCVCreateScreen> createState() => _WorkerCVCreateScreenState();
}

class _WorkerCVCreateScreenState extends State<WorkerCVCreateScreen> {
  final _formKey = GlobalKey<FormState>();

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

  // ✅ পিডিএফ জেনারেট এবং সেভ ফাংশন
  Future<void> _generateAndSavePDF() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final pdf = pw.Document();

      // পিডিএফ ডিজাইন
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // হেডার (নাম ও রোল)
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(widget.worker.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text(widget.worker.userRole.toUpperCase(), style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // সামারি সেকশন
                pw.Text("Professional Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Text(_summaryController.text, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),

                // এক্সপেরিয়েন্স সেকশন
                pw.Text("Experience", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ..._experienceControllers.map((c) => pw.Bullet(text: c.text)),
                pw.SizedBox(height: 20),

                // এডুকেশন সেকশন
                pw.Text("Education", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ..._educationControllers.map((c) => pw.Bullet(text: c.text)),
                pw.SizedBox(height: 20),

                // স্কিলস সেকশন
                pw.Text("Skills", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ..._skillControllers.map((c) => pw.Bullet(text: c.text)),
              ],
            );
          },
        ),
      );

      // ১. ফাইল সেভ করা (লোকাল স্টোরেজ)
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/my_cv.pdf");
      await file.writeAsBytes(await pdf.save());

      // ২. ফায়ারবেস আপডেট (অপশনাল: শুধু স্ট্যাটাস আপডেট)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'has_created_cv': true,
          'cv_updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      // ৩. প্রিভিউ বা শেয়ার অপশন দেখানো
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'My_Professional_CV',
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CV Generated Successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

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
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _generateAndSavePDF,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("GENERATE & SAVE PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

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