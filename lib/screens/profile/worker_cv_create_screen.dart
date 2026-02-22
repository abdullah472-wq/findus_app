import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CV TEMPLATES ENUM
// ═══════════════════════════════════════════════════════════════════════════

enum CVTemplate {
  modern,
  classic,
  minimal,
  creative,
}

extension CVTemplateExtension on CVTemplate {
  String get name {
    switch (this) {
      case CVTemplate.modern:
        return "Modern";
      case CVTemplate.classic:
        return "Classic";
      case CVTemplate.minimal:
        return "Minimal";
      case CVTemplate.creative:
        return "Creative";
    }
  }

  String get description {
    switch (this) {
      case CVTemplate.modern:
        return "Clean & Professional";
      case CVTemplate.classic:
        return "Traditional Style";
      case CVTemplate.minimal:
        return "Simple & Elegant";
      case CVTemplate.creative:
        return "Bold & Colorful";
    }
  }

  PdfColor get primaryColor {
    switch (this) {
      case CVTemplate.modern:
        return PdfColor.fromHex('#38B6FF');
      case CVTemplate.classic:
        return PdfColor.fromHex('#2C3E50');
      case CVTemplate.minimal:
        return PdfColor.fromHex('#333333');
      case CVTemplate.creative:
        return PdfColor.fromHex('#E74C3C');
    }
  }

  PdfColor get accentColor {
    switch (this) {
      case CVTemplate.modern:
        return PdfColor.fromHex('#00D4AA');
      case CVTemplate.classic:
        return PdfColor.fromHex('#7F8C8D');
      case CVTemplate.minimal:
        return PdfColor.fromHex('#666666');
      case CVTemplate.creative:
        return PdfColor.fromHex('#F39C12');
    }
  }

  IconData get icon {
    switch (this) {
      case CVTemplate.modern:
        return Icons.auto_awesome;
      case CVTemplate.classic:
        return Icons.article;
      case CVTemplate.minimal:
        return Icons.text_fields;
      case CVTemplate.creative:
        return Icons.palette;
    }
  }

  Color get flutterColor {
    switch (this) {
      case CVTemplate.modern:
        return const Color(0xFF38B6FF);
      case CVTemplate.classic:
        return const Color(0xFF2C3E50);
      case CVTemplate.minimal:
        return const Color(0xFF333333);
      case CVTemplate.creative:
        return const Color(0xFFE74C3C);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();

  final List<Map<String, TextEditingController>> _experienceList = [];
  final List<Map<String, TextEditingController>> _educationList = [];
  final List<TextEditingController> _skillControllers = [TextEditingController()];
  final List<TextEditingController> _languageControllers = [TextEditingController()];

  CVTemplate _selectedTemplate = CVTemplate.modern;
  bool _isSaving = false;
  bool _isPreview = false;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _addExperience();
    _addEducation();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    for (var map in _experienceList) {
      map.values.forEach((c) => c.dispose());
    }
    for (var map in _educationList) {
      map.values.forEach((c) => c.dispose());
    }
    for (var c in _skillControllers) {
      c.dispose();
    }
    for (var c in _languageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD PROFILE IMAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadProfileImage() async {
    if (widget.worker.image.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(widget.worker.image));
      if (response.statusCode == 200) {
        setState(() => _profileImageBytes = response.bodyBytes);
      }
    } catch (e) {
      debugPrint("Failed to load profile image: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC FIELD HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _addExperience() {
    setState(() {
      _experienceList.add({
        'title': TextEditingController(),
        'company': TextEditingController(),
        'duration': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _removeExperience(int index) {
    if (_experienceList.length > 1) {
      setState(() {
        _experienceList[index].values.forEach((c) => c.dispose());
        _experienceList.removeAt(index);
      });
    }
  }

  void _addEducation() {
    setState(() {
      _educationList.add({
        'degree': TextEditingController(),
        'institution': TextEditingController(),
        'year': TextEditingController(),
      });
    });
  }

  void _removeEducation(int index) {
    if (_educationList.length > 1) {
      setState(() {
        _educationList[index].values.forEach((c) => c.dispose());
        _educationList.removeAt(index);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();

    // Load fonts
    final regularFont = await PdfGoogleFonts.nunitoSansRegular();
    final boldFont = await PdfGoogleFonts.nunitoSansBold();
    final italicFont = await PdfGoogleFonts.nunitoSansItalic();

    // Profile image
    pw.ImageProvider? profileImage;
    if (_profileImageBytes != null) {
      profileImage = pw.MemoryImage(_profileImageBytes!);
    }

    // Generate based on template
    switch (_selectedTemplate) {
      case CVTemplate.modern:
        _buildModernTemplate(pdf, regularFont, boldFont, italicFont, profileImage);
        break;
      case CVTemplate.classic:
        _buildClassicTemplate(pdf, regularFont, boldFont, italicFont, profileImage);
        break;
      case CVTemplate.minimal:
        _buildMinimalTemplate(pdf, regularFont, boldFont, italicFont, profileImage);
        break;
      case CVTemplate.creative:
        _buildCreativeTemplate(pdf, regularFont, boldFont, italicFont, profileImage);
        break;
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODERN TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _buildModernTemplate(
      pw.Document pdf,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      pw.ImageProvider? profileImage,
      ) {
    final primaryColor = _selectedTemplate.primaryColor;
    final accentColor = _selectedTemplate.accentColor;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          // Header with sidebar feel
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, accentColor],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Profile Image
                if (profileImage != null)
                  pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.white, width: 3),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  )
                else
                  pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.white, width: 3),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        widget.worker.name.isNotEmpty ? widget.worker.name[0].toUpperCase() : "?",
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 40,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),

                pw.SizedBox(width: 25),

                // Name & Title
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        widget.worker.name.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 28,
                          color: PdfColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        widget.worker.userRole.toUpperCase(),
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 14,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      // Contact Info Row
                      pw.Wrap(
                        spacing: 20,
                        runSpacing: 5,
                        children: [
                          if (_phoneController.text.isNotEmpty)
                            _pdfContactItem("📞 ${_phoneController.text}", regularFont),
                          if (_emailController.text.isNotEmpty)
                            _pdfContactItem("✉️ ${_emailController.text}", regularFont),
                          if (_addressController.text.isNotEmpty)
                            _pdfContactItem("📍 ${_addressController.text}", regularFont),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary
                if (_summaryController.text.isNotEmpty) ...[
                  _pdfSectionTitle("PROFESSIONAL SUMMARY", boldFont, primaryColor),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _summaryController.text,
                    style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 4),
                  ),
                  pw.SizedBox(height: 25),
                ],

                // Two Column Layout
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Column (Experience)
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfSectionTitle("WORK EXPERIENCE", boldFont, primaryColor),
                          pw.SizedBox(height: 10),
                          ..._experienceList.map((exp) => _pdfExperienceItem(
                            exp['title']!.text,
                            exp['company']!.text,
                            exp['duration']!.text,
                            exp['description']!.text,
                            regularFont,
                            boldFont,
                            italicFont,
                            primaryColor,
                          )),
                          pw.SizedBox(height: 20),
                          _pdfSectionTitle("EDUCATION", boldFont, primaryColor),
                          pw.SizedBox(height: 10),
                          ..._educationList.map((edu) => _pdfEducationItem(
                            edu['degree']!.text,
                            edu['institution']!.text,
                            edu['year']!.text,
                            regularFont,
                            boldFont,
                            primaryColor,
                          )),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 30),

                    // Right Column (Skills & Languages)
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfSectionTitle("SKILLS", boldFont, primaryColor),
                          pw.SizedBox(height: 10),
                          ..._skillControllers
                              .where((c) => c.text.isNotEmpty)
                              .map((c) => _pdfSkillBar(c.text, regularFont, primaryColor, accentColor)),
                          pw.SizedBox(height: 20),
                          _pdfSectionTitle("LANGUAGES", boldFont, primaryColor),
                          pw.SizedBox(height: 10),
                          ..._languageControllers
                              .where((c) => c.text.isNotEmpty)
                              .map((c) => _pdfLanguageItem(c.text, regularFont, primaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLASSIC TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _buildClassicTemplate(
      pw.Document pdf,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      pw.ImageProvider? profileImage,
      ) {
    final primaryColor = _selectedTemplate.primaryColor;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                if (profileImage != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.ClipOval(
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                pw.SizedBox(height: 15),
                pw.Text(
                  widget.worker.name,
                  style: pw.TextStyle(font: boldFont, fontSize: 26, color: primaryColor),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  widget.worker.userRole,
                  style: pw.TextStyle(font: italicFont, fontSize: 14, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: primaryColor, thickness: 2),
                pw.SizedBox(height: 5),
                // Contact Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (_phoneController.text.isNotEmpty) ...[
                      pw.Text(_phoneController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      pw.Text(" | ", style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey)),
                    ],
                    if (_emailController.text.isNotEmpty) ...[
                      pw.Text(_emailController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      pw.Text(" | ", style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey)),
                    ],
                    if (_addressController.text.isNotEmpty)
                      pw.Text(_addressController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Summary
          if (_summaryController.text.isNotEmpty) ...[
            _pdfClassicSectionTitle("Profile", boldFont, primaryColor),
            pw.SizedBox(height: 8),
            pw.Text(
              _summaryController.text,
              style: pw.TextStyle(font: regularFont, fontSize: 11, lineSpacing: 3),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 20),
          ],

          // Experience
          _pdfClassicSectionTitle("Professional Experience", boldFont, primaryColor),
          pw.SizedBox(height: 8),
          ..._experienceList.map((exp) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(exp['title']!.text, style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text(exp['duration']!.text, style: pw.TextStyle(font: italicFont, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(exp['company']!.text, style: pw.TextStyle(font: italicFont, fontSize: 11, color: primaryColor)),
                if (exp['description']!.text.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(exp['description']!.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                ],
              ],
            ),
          )),

          pw.SizedBox(height: 15),

          // Education
          _pdfClassicSectionTitle("Education", boldFont, primaryColor),
          pw.SizedBox(height: 8),
          ..._educationList.map((edu) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(edu['degree']!.text, style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    pw.Text(edu['institution']!.text, style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(edu['year']!.text, style: pw.TextStyle(font: italicFont, fontSize: 10)),
              ],
            ),
          )),

          pw.SizedBox(height: 15),

          // Skills
          _pdfClassicSectionTitle("Skills", boldFont, primaryColor),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _skillControllers
                .where((c) => c.text.isNotEmpty)
                .map((c) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryColor),
                borderRadius: pw.BorderRadius.circular(15),
              ),
              child: pw.Text(c.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MINIMAL TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _buildMinimalTemplate(
      pw.Document pdf,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      pw.ImageProvider? profileImage,
      ) {
    final primaryColor = _selectedTemplate.primaryColor;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (context) => [
          // Simple Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      widget.worker.name,
                      style: pw.TextStyle(font: boldFont, fontSize: 32, color: primaryColor),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      widget.worker.userRole,
                      style: pw.TextStyle(font: regularFont, fontSize: 14, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (_phoneController.text.isNotEmpty)
                    pw.Text(_phoneController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  if (_emailController.text.isNotEmpty)
                    pw.Text(_emailController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  if (_addressController.text.isNotEmpty)
                    pw.Text(_addressController.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 20),

          // Summary
          if (_summaryController.text.isNotEmpty) ...[
            pw.Text(
              _summaryController.text,
              style: pw.TextStyle(font: italicFont, fontSize: 11, color: PdfColors.grey700, lineSpacing: 4),
            ),
            pw.SizedBox(height: 25),
          ],

          // Experience
          pw.Text("Experience", style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
          pw.SizedBox(height: 10),
          ..._experienceList.map((exp) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.only(left: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: PdfColors.grey300, width: 2)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("${exp['title']!.text} — ${exp['company']!.text}", style: pw.TextStyle(font: boldFont, fontSize: 11)),
                pw.Text(exp['duration']!.text, style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                if (exp['description']!.text.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(exp['description']!.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                ],
              ],
            ),
          )),

          pw.SizedBox(height: 20),

          // Two columns for Education & Skills
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Education", style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
                    pw.SizedBox(height: 10),
                    ..._educationList.map((edu) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu['degree']!.text, style: pw.TextStyle(font: boldFont, fontSize: 10)),
                          pw.Text("${edu['institution']!.text}, ${edu['year']!.text}",
                              style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey600)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Skills", style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
                    pw.SizedBox(height: 10),
                    ..._skillControllers.where((c) => c.text.isNotEmpty).map(
                          (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Text("• ${c.text}", style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATIVE TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _buildCreativeTemplate(
      pw.Document pdf,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      pw.ImageProvider? profileImage,
      ) {
    final primaryColor = _selectedTemplate.primaryColor;
    final accentColor = _selectedTemplate.accentColor;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          children: [
            // Left Sidebar
            pw.Container(
              width: 200,
              height: double.infinity,
              color: primaryColor,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  if (profileImage != null)
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.white, width: 4),
                      ),
                      child: pw.ClipOval(child: pw.Image(profileImage, fit: pw.BoxFit.cover)),
                    )
                  else
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: accentColor,
                        border: pw.Border.all(color: PdfColors.white, width: 4),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          widget.worker.name.isNotEmpty ? widget.worker.name[0].toUpperCase() : "?",
                          style: pw.TextStyle(font: boldFont, fontSize: 50, color: PdfColors.white),
                        ),
                      ),
                    ),

                  pw.SizedBox(height: 20),

                  // Contact Section
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 15),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.white, width: 0.5),
                        bottom: pw.BorderSide(color: PdfColors.white, width: 0.5),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("CONTACT", style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white, letterSpacing: 2)),
                        pw.SizedBox(height: 10),
                        if (_phoneController.text.isNotEmpty)
                          _pdfCreativeContactItem("📞", _phoneController.text, regularFont),
                        if (_emailController.text.isNotEmpty)
                          _pdfCreativeContactItem("✉️", _emailController.text, regularFont),
                        if (_addressController.text.isNotEmpty)
                          _pdfCreativeContactItem("📍", _addressController.text, regularFont),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Skills
                  pw.Container(
                    width: double.infinity,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SKILLS", style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white, letterSpacing: 2)),
                        pw.SizedBox(height: 10),
                        ..._skillControllers.where((c) => c.text.isNotEmpty).map(
                              (c) => pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(c.text, style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.white)),
                                pw.SizedBox(height: 3),
                                pw.Container(
                                  height: 4,
                                  width: double.infinity,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    borderRadius: pw.BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Languages
                  pw.Container(
                    width: double.infinity,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("LANGUAGES", style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white, letterSpacing: 2)),
                        pw.SizedBox(height: 10),
                        ..._languageControllers.where((c) => c.text.isNotEmpty).map(
                              (c) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5),
                            child: pw.Text("• ${c.text}", style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right Content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name Header
                    pw.Text(
                      widget.worker.name.toUpperCase(),
                      style: pw.TextStyle(font: boldFont, fontSize: 32, color: primaryColor, letterSpacing: 3),
                    ),
                    pw.Text(
                      widget.worker.userRole.toUpperCase(),
                      style: pw.TextStyle(font: regularFont, fontSize: 14, color: accentColor, letterSpacing: 2),
                    ),
                    pw.SizedBox(height: 20),

                    // Summary
                    if (_summaryController.text.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F5F5F5'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          _summaryController.text,
                          style: pw.TextStyle(font: italicFont, fontSize: 11, lineSpacing: 4),
                        ),
                      ),
                      pw.SizedBox(height: 25),
                    ],

                    // Experience
                    pw.Row(
                      children: [
                        pw.Container(width: 30, height: 30, color: primaryColor,
                            child: pw.Center(child: pw.Text("💼", style: const pw.TextStyle(fontSize: 14)))),
                        pw.SizedBox(width: 10),
                        pw.Text("EXPERIENCE", style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor, letterSpacing: 1)),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    ..._experienceList.map((exp) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 12, left: 40),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(exp['title']!.text, style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryColor)),
                          pw.Text("${exp['company']!.text} | ${exp['duration']!.text}",
                              style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey700)),
                          if (exp['description']!.text.isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(exp['description']!.text, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                          ],
                        ],
                      ),
                    )),

                    pw.SizedBox(height: 20),

                    // Education
                    pw.Row(
                      children: [
                        pw.Container(width: 30, height: 30, color: accentColor,
                            child: pw.Center(child: pw.Text("🎓", style: const pw.TextStyle(fontSize: 14)))),
                        pw.SizedBox(width: 10),
                        pw.Text("EDUCATION", style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor, letterSpacing: 1)),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    ..._educationList.map((edu) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8, left: 40),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu['degree']!.text, style: pw.TextStyle(font: boldFont, fontSize: 11)),
                          pw.Text("${edu['institution']!.text}, ${edu['year']!.text}",
                              style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _pdfContactItem(String text, pw.Font font) {
    return pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white));
  }

  pw.Widget _pdfCreativeContactItem(String icon, String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text(icon, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title, pw.Font boldFont, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: boldFont, fontSize: 14, color: color, letterSpacing: 1),
      ),
    );
  }

  pw.Widget _pdfClassicSectionTitle(String title, pw.Font boldFont, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 5, height: 20, color: color),
        pw.SizedBox(width: 10),
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 14, color: color)),
      ],
    );
  }

  pw.Widget _pdfExperienceItem(
      String title,
      String company,
      String duration,
      String description,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      PdfColor accentColor,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(duration, style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.white)),
              ),
            ],
          ),
          pw.Text(company, style: pw.TextStyle(font: italicFont, fontSize: 10, color: accentColor)),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(description, style: pw.TextStyle(font: regularFont, fontSize: 10, lineSpacing: 2)),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfEducationItem(
      String degree,
      String institution,
      String year,
      pw.Font regularFont,
      pw.Font boldFont,
      PdfColor color,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(degree, style: pw.TextStyle(font: boldFont, fontSize: 11)),
                pw.Text("$institution • $year", style: pw.TextStyle(font: regularFont, fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSkillBar(String skill, pw.Font font, PdfColor primary, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(skill, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 6,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 8,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(colors: [primary, accent]),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ),
                pw.Expanded(flex: 2, child: pw.Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLanguageItem(String language, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color)),
          pw.SizedBox(width: 8),
          pw.Text(language, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE & PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _previewPDF() async {
    setState(() => _isPreview = true);

    try {
      final pdfBytes = await _generatePDF();

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: '${widget.worker.name}_CV',
      );
    } catch (e) {
      _showError("Preview failed: $e");
    } finally {
      if (mounted) setState(() => _isPreview = false);
    }
  }

  Future<void> _savePDF() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final pdfBytes = await _generatePDF();

      // Save to local storage
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/${widget.worker.name}_CV.pdf");
      await file.writeAsBytes(pdfBytes);

      // Update Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'has_created_cv': true,
          'cv_template': _selectedTemplate.name,
          'cv_updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      // Share option
      await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.worker.name}_CV.pdf');

      _showSuccess("CV saved successfully!");
    } catch (e) {
      _showError("Save failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "CREATE CV",
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
            // ✅ Template Selector
            _buildLabel("Choose Template", textColor),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: CVTemplate.values.length,
                itemBuilder: (context, index) {
                  final template = CVTemplate.values[index];
                  final isSelected = _selectedTemplate == template;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTemplate = template),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? template.flutterColor.withOpacity(0.15) : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? template.flutterColor : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: template.flutterColor.withOpacity(0.3), blurRadius: 10)]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            template.icon,
                            color: isSelected ? template.flutterColor : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? template.flutterColor : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ✅ Contact Information
            _buildLabel("Contact Information", textColor),
            const SizedBox(height: 10),
            _buildTextField(_phoneController, "Phone Number", Icons.phone, isDark, cardColor, textColor),
            const SizedBox(height: 10),
            _buildTextField(_emailController, "Email Address", Icons.email, isDark, cardColor, textColor),
            const SizedBox(height: 10),
            _buildTextField(_addressController, "Address", Icons.location_on, isDark, cardColor, textColor),

            const SizedBox(height: 24),

            // ✅ Professional Summary
            _buildLabel("Professional Summary", textColor),
            const SizedBox(height: 10),
            _buildMultiLineField(_summaryController, "Write a short summary about yourself...", isDark, cardColor, textColor),

            const SizedBox(height: 24),

            // ✅ Experience Section
            _buildDynamicExperienceSection(textColor, cardColor, isDark),

            const SizedBox(height: 24),

            // ✅ Education Section
            _buildDynamicEducationSection(textColor, cardColor, isDark),

            const SizedBox(height: 24),

            // ✅ Skills Section
            _buildDynamicListSection("Skills", _skillControllers, "e.g. House Wiring, AC Repair", textColor, cardColor, isDark),

            const SizedBox(height: 24),

            // ✅ Languages Section
            _buildDynamicListSection("Languages", _languageControllers, "e.g. Bengali (Native), English (Fluent)", textColor, cardColor, isDark),

            const SizedBox(height: 40),

            // ✅ Action Buttons
            Row(
              children: [
                // Preview Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPreview || _isSaving ? null : _previewPDF,
                    icon: _isPreview
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.visibility),
                    label: const Text("Preview"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _selectedTemplate.flutterColor,
                      side: BorderSide(color: _selectedTemplate.flutterColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving || _isPreview ? null : _savePDF,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download, color: Colors.white),
                    label: const Text("Save & Share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTemplate.flutterColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _selectedTemplate.flutterColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      bool isDark,
      Color fillColor,
      Color textColor,
      ) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
        prefixIcon: Icon(icon, color: _selectedTemplate.flutterColor, size: 20),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _selectedTemplate.flutterColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMultiLineField(
      TextEditingController controller,
      String hint,
      bool isDark,
      Color fillColor,
      Color textColor,
      ) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _selectedTemplate.flutterColor, width: 1.5),
        ),
      ),
      validator: (v) => v!.isEmpty ? "This field is required" : null,
    );
  }

  Widget _buildDynamicExperienceSection(Color textColor, Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("Work Experience", textColor),
            IconButton(
              onPressed: _addExperience,
              icon: Icon(Icons.add_circle, color: _selectedTemplate.flutterColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._experienceList.asMap().entries.map((entry) {
          final index = entry.key;
          final exp = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text("Experience ${index + 1}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTemplate.flutterColor)),
                    ),
                    if (_experienceList.length > 1)
                      IconButton(
                        onPressed: () => _removeExperience(index),
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSmallTextField(exp['title']!, "Job Title", isDark, textColor),
                const SizedBox(height: 10),
                _buildSmallTextField(exp['company']!, "Company Name", isDark, textColor),
                const SizedBox(height: 10),
                _buildSmallTextField(exp['duration']!, "Duration (e.g. 2020 - Present)", isDark, textColor),
                const SizedBox(height: 10),
                _buildSmallTextField(exp['description']!, "Brief Description", isDark, textColor, maxLines: 2),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDynamicEducationSection(Color textColor, Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("Education", textColor),
            IconButton(
              onPressed: _addEducation,
              icon: Icon(Icons.add_circle, color: _selectedTemplate.flutterColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._educationList.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text("Education ${index + 1}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: _selectedTemplate.flutterColor)),
                    ),
                    if (_educationList.length > 1)
                      IconButton(
                        onPressed: () => _removeEducation(index),
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSmallTextField(edu['degree']!, "Degree / Certificate", isDark, textColor),
                const SizedBox(height: 10),
                _buildSmallTextField(edu['institution']!, "Institution Name", isDark, textColor),
                const SizedBox(height: 10),
                _buildSmallTextField(edu['year']!, "Year (e.g. 2015 - 2019)", isDark, textColor),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDynamicListSection(
      String title,
      List<TextEditingController> controllers,
      String hint,
      Color textColor,
      Color cardColor,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(title, textColor),
            IconButton(
              onPressed: () => setState(() => controllers.add(TextEditingController())),
              icon: Icon(Icons.add_circle, color: _selectedTemplate.flutterColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _buildSmallTextField(entry.value, hint, isDark, textColor)),
                if (controllers.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      controllers[index].dispose();
                      controllers.removeAt(index);
                    }),
                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSmallTextField(
      TextEditingController controller,
      String hint,
      bool isDark,
      Color textColor, {
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _selectedTemplate.flutterColor, width: 1),
        ),
      ),
    );
  }
}