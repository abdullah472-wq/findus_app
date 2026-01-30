// lib/screens/wallet/manual_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/settings/activation_screen.dart';

enum PaymentPurpose { subscription, profileBoost, workerPayment, supporterPayment }

class ManualPaymentScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final int duration;
  final PaymentPurpose purpose;
  final String description;

  const ManualPaymentScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.duration,
    required this.purpose,
    required this.description,
  });

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final _senderController = TextEditingController();
  final _trxIdController = TextEditingController();
  String _selectedMethod = 'bKash';
  bool _isSubmitting = false;

  final Map<String, String> _adminNumbers = {
    'bKash': '01581818368',
    'Nagad': '01312200043',
    'Rocket': '01312200043',
  };

  Future<void> _submitRequest() async {
    final sender = _senderController.text.trim();
    final trxId = _trxIdController.text.trim();

    if (sender.isEmpty || trxId.isEmpty) {
      _showSnack("Please fill all fields", Colors.red);
      return;
    }

    // 🔹 আগে login check করি, যাতে _isSubmitting=true হবার আগেই বেরিয়ে আসতে পারি
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("Please login first", Colors.red);
      return;
    }
    final uid = user.uid;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('payment_requests')
          .add({
        'uid': uid,
        'planId': widget.planId,
        'amount': widget.amount,
        'duration': widget.duration,
        'purpose': widget.purpose.name,
        'method': _selectedMethod,
        'senderNumber': sender,
        'trxId': trxId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 যদি শুধু subscription এর জন্য subStatus ব্যবহার করো তবে চাইলে এখানে purpose চেক করতে পারো
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'subStatus': 'pending',
        'lastPaymentMethod': _selectedMethod,
        'lastTrxId': trxId,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActivationScreen(
              planId: widget.planId,
              amount: widget.amount,
              trxId: trxId,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

    return FloatingScaffold(
      title: "PAYMENT INFO",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryBox(isDark, cardColor, textColor),
            const SizedBox(height: 25),
            _buildInstructionBox(isDark),
            const SizedBox(height: 25),
            Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 10),
            _buildMethodSelector(isDark, cardColor, textColor),
            const SizedBox(height: 25),
            _buildInputFields(isDark, cardColor, textColor, hintColor),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.planId.replaceAll('_', ' '), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              Text(widget.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text("৳${widget.amount}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandMain)),
        ],
      ),
    );
  }

  Widget _buildInstructionBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Text("How to pay?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Send Money ৳${widget.amount} to the number below, then enter your number & TrxID.",
            style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark, Color cardColor, Color textColor) {
    return Column(
      children: _adminNumbers.keys.map((method) {
        bool isSelected = _selectedMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = method),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandMain.withOpacity(0.1) : cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.brandMain : Colors.grey),
                const SizedBox(width: 15),
                Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const Spacer(),
                Text(_adminNumbers[method]!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.brandMain),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _adminNumbers[method]!));
                    _showSnack("$method Number Copied!", Colors.green);
                  },
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputFields(bool isDark, Color cardColor, Color textColor, Color hintColor) {
    return Column(
      children: [
        TextField(
          controller: _senderController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Sender $_selectedMethod Number",
            hintText: "01XXXXXXXXX",
            labelStyle: TextStyle(color: hintColor),
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _trxIdController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Transaction ID (TrxID)",
            hintText: "8N7X6W5V...",
            labelStyle: TextStyle(color: hintColor),
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SUBMIT PAYMENT INFO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}