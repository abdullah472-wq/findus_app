// lib/screens/wallet/manual_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/settings/activation_screen.dart'; // ✅ সাকসেস হলে এখানে পাঠাবে

enum PaymentPurpose {
  subscription,
  profileBoost,
  workerPayment,
  supporterPayment,
}

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

  // ✅ আপনার পার্সোনাল নম্বরগুলো এখানে দিন
  final Map<String, String> _adminNumbers = {
    'bKash': '017XXXXXXXX',
    'Nagad': '018XXXXXXXX',
    'Rocket': '019XXXXXXXX',
  };

  Future<void> _submitRequest() async {
    final sender = _senderController.text.trim();
    final trxId = _trxIdController.text.trim();

    if (sender.isEmpty || trxId.isEmpty) {
      _showSnack("Please fill all fields", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // ১. Firestore-এ রিকোয়েস্ট সেভ করা
      await FirebaseFirestore.instance.collection('payment_requests').add({
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

      // ২. ইউজারের স্ট্যাটাস 'pending' করে রাখা (যাতে এক্টিভেশন স্ক্রিন লিসেন করতে পারে)
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'subStatus': 'pending',
        'lastPaymentMethod': _selectedMethod,
        'lastTrxId': trxId,
      });

      if (mounted) {
        // ৩. সাকসেস হলে এক্টিভেশন স্ক্রিনে পাঠানো
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "PAYMENT INFO",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryBox(isDark),
            const SizedBox(height: 25),
            _buildInstructionBox(),
            const SizedBox(height: 25),
            const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildMethodSelector(isDark),
            const SizedBox(height: 25),
            _buildInputFields(isDark),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.planId.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(widget.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text("৳${widget.amount}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandMain)),
        ],
      ),
    );
  }

  Widget _buildInstructionBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              const Text("How to pay?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 10),
          Text("নিচের যেকোনো একটি নম্বরে ৳${widget.amount} সেন্ডমানি (Send Money) করে ট্রানজ্যাকশন আইডি ও আপনার নম্বরটি দিন।", style: const TextStyle(fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark) {
    return Column(
      children: _adminNumbers.keys.map((method) {
        bool isSelected = _selectedMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = method),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandMain.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.white),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.brandMain : Colors.grey),
                const SizedBox(width: 15),
                Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildInputFields(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _senderController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Sender $_selectedMethod Number",
            hintText: "01XXXXXXXXX",
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _trxIdController,
          decoration: InputDecoration(
            labelText: "Transaction ID (TrxID)",
            hintText: "8N7X6W5V...",
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
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
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SUBMIT PAYMENT INFO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}