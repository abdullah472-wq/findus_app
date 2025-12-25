import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'bKash';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money'),
        backgroundColor: AppColors.brandLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                hintText: 'e.g. 500',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select payment method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildMethodRadio('bKash'),
            _buildMethodRadio('Nagad'),
            _buildMethodRadio('Visa/MasterCard'),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onConfirmAddMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Confirm & Add Money'),
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

  void _onConfirmAddMoney() {
    // TODO: এখানে তোমার payment integration / backend call আসবে
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Adding ৳${_amountController.text} via $_selectedMethod (demo only).',
        ),
      ),
    );

    Navigator.pop(context);
  }
}