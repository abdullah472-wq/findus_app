import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _reportType = 'Worker issue';
  final TextEditingController _relatedInfoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _includeContact = true;

  @override
  void dispose() {
    _relatedInfoController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Backend integration (API call)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report submitted successfully."),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade400;

    return FloatingScaffold(
      title: "REPORT A PROBLEM",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ইনফো টেক্সট
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Please describe your issue in detail. Our support team will review it shortly.",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Report Type", textColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _reportType,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 15),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandMain),
                  items: const [
                    DropdownMenuItem(value: 'Worker issue', child: Text('Worker issue')),
                    DropdownMenuItem(value: 'Supporter issue', child: Text('Supporter issue')),
                    DropdownMenuItem(value: 'Job post', child: Text('Job post')),
                    DropdownMenuItem(value: 'Payment', child: Text('Payment')),
                    DropdownMenuItem(value: 'App problem', child: Text('App problem / Bug')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _reportType = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel("Related Info (Optional)", textColor),
            _buildTextField(
              controller: _relatedInfoController,
              hint: "e.g. Worker name, Job ID, Date...",
              icon: Icons.info_outline,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            const SizedBox(height: 20),

            _buildLabel("Description", textColor),
            _buildTextField(
              controller: _descriptionController,
              hint: "Please explain what happened...",
              maxLines: 5,
              isRequired: true,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            const SizedBox(height: 25),

            // কন্টাক্ট টগল
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: _includeContact,
                activeColor: AppColors.brandMain,
                title: Text(
                  "Include Contact Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                ),
                subtitle: Text(
                  "Allow support team to contact you",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.grey.shade600),
                ),
                onChanged: (val) => setState(() => _includeContact = val),
              ),
            ),

            if (_includeContact) ...[
              const SizedBox(height: 15),
              _buildTextField(
                controller: _contactController,
                hint: "Phone / Email (optional)",
                icon: Icons.contact_phone_outlined,
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                hintColor: hintColor,
              ),
            ],

            const SizedBox(height: 30),

            // সাবমিট বাটন
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "SUBMIT REPORT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool isRequired = false,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? "This field is required" : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandMain, width: 1.5),
        ),
      ),
    );
  }
}