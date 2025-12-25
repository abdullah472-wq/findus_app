import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'bKash';
  final TextEditingController _accountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        backgroundColor: AppColors.brandLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available to withdraw',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '৳ 2,000.00',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Enter amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 300',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select withdraw method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildMethodRadio('bKash'),
            _buildMethodRadio('Nagad'),
            _buildMethodRadio('Bank Transfer'),

            const SizedBox(height: 16),
            const Text(
              'Account / Number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                hintText: 'e.g. 01XXXXXXXXX or Bank account no.',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onConfirmWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Confirm & Withdraw'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodRadio(String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: label,
      groupValue: _selectedMethod,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _selectedMethod = v);
      },
    );
  }

  void _onConfirmWithdraw() {
    if (_amountController.text.trim().isEmpty ||
        _accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    // TODO: এখানে আসল withdraw API / payment integration দেবে
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Withdrawing ৳${_amountController.text} to $_selectedMethod (${_accountController.text}) (demo only).',
        ),
      ),
    );

    Navigator.pop(context);
  }
}