// lib/screens/wallet/manual_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class ManualPaymentScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final int duration;

  const ManualPaymentScreen({super.key, required this.planId, required this.amount, required this.duration});

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final _senderController = TextEditingController();
  final _trxIdController = TextEditingController();
  String _selectedMethod = 'bKash';
  bool _isSubmitting = false;

  // আপনার পার্সোনাল নম্বরগুলো এখানে দিন
  final Map<String, String> _adminNumbers = {
    'bKash': '017XXXXXXXX (Personal)',
    'Nagad': '018XXXXXXXX (Personal)',
    'Rocket': '019XXXXXXXX (Personal)',
  };

  Future<void> _submitRequest() async {
    final sender = _senderController.text.trim();
    final trxId = _trxIdController.text.trim();

    if (sender.isEmpty || trxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Firestore-এ 'payment_requests' কালেকশনে ডাটা সেভ হবে
      await FirebaseFirestore.instance.collection('payment_requests').add({
        'uid': uid,
        'planId': widget.planId,
        'amount': widget.amount,
        'duration': widget.duration,
        'method': _selectedMethod,
        'senderNumber': sender,
        'trxId': trxId,
        'status': 'pending', // আপনি ম্যানুয়ালি এটি 'approved' করবেন
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showPendingDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Request Submitted"),
        content: const Text("আপনার পেমেন্ট রিকোয়েস্টটি জমা হয়েছে। অ্যাডমিন ভেরিফাই করার পর (৩০-৬০ মিনিটের মধ্যে) আপনার প্ল্যানটি এক্টিভেট হয়ে যাবে।"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Back to Plans
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "MANUAL PAYMENT",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: 25),
            _buildPaymentMethods(),
            const SizedBox(height: 25),
            _buildInputFields(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.shade200)),
      child: Column(
        children: [
          const Text("পেমেন্ট করার নিয়ম:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 10),
          Text("নিচের যেকোনো একটি নম্বরে ৳${widget.amount} সেন্ডমানি (Send Money) করুন এবং ট্রানজ্যাকশন আইডি ও আপনার নম্বরটি নিচে ইনপুট দিন।", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: _adminNumbers.keys.map((method) {
        bool isSelected = _selectedMethod == method;
        return ListTile(
          onTap: () => setState(() => _selectedMethod = method),
          leading: Radio(value: method, groupValue: _selectedMethod, onChanged: (v) => setState(() => _selectedMethod = v!)),
          title: Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(_adminNumbers[method]!),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _adminNumbers[method]!.split(' ')[0]));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Number Copied!")));
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextField(
          controller: _senderController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: "Your $_selectedMethod Number", border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _trxIdController,
          decoration: const InputDecoration(labelText: "Transaction ID (TrxID)", border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitRequest,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, minimumSize: const Size(double.infinity, 55)),
      child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT PAYMENT INFO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}