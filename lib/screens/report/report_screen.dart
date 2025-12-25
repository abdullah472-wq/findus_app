import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _reportType = 'Worker issue'; // ডিফল্ট টাইপ
  final TextEditingController _relatedInfoController =
  TextEditingController();
  final TextEditingController _descriptionController =
  TextEditingController();
  final TextEditingController _contactController =
  TextEditingController();

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

    // TODO: এখানে backend এ report পাঠাবে (API call)
    // final data = {
    //   "type": _reportType,
    //   "related_info": _relatedInfoController.text.trim(),
    //   "description": _descriptionController.text.trim(),
    //   "contact": _includeContact ? _contactController.text.trim() : null,
    // };

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report submitted successfully (demo)."),
        backgroundColor: AppColors.brandMain,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Report a Problem",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // উপরের অংশ স্ক্রলেবল
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "If you faced any problem with a worker, supporter, job post or the app itself, please submit a report.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Report type dropdown
                      const Text(
                        "Report Type",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _reportType,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'Worker issue',
                                child: Text('Worker issue'),
                              ),
                              DropdownMenuItem(
                                value: 'Supporter issue',
                                child: Text('Supporter issue'),
                              ),
                              DropdownMenuItem(
                                value: 'Job post',
                                child: Text('Job post'),
                              ),
                              DropdownMenuItem(
                                value: 'Payment',
                                child: Text('Payment'),
                              ),
                              DropdownMenuItem(
                                value: 'App problem',
                                child: Text('App problem / Bug'),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _reportType = val);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Related info
                      const Text(
                        "Related User / Job Info (optional)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _relatedInfoController,
                        decoration: InputDecoration(
                          hintText:
                          "e.g. Worker name, Job ID, date & time...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description (required)
                      const Text(
                        "Describe the issue",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                          "Please explain what happened in detail...",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Description is required";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Include contact টগল
                      SwitchListTile(
                        value: _includeContact,
                        activeColor: AppColors.brandMain,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Include my contact details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandDark,
                          ),
                        ),
                        subtitle: const Text(
                          "Support team may contact you for more info.",
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (val) =>
                            setState(() => _includeContact = val),
                      ),

                      if (_includeContact) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactController,
                          decoration: InputDecoration(
                            hintText:
                            "Phone / Email (optional but helpful)",
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // নিচে SUBMIT বাটন
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "SUBMIT REPORT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}