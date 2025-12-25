import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class WalletSettingsScreen extends StatefulWidget {
  const WalletSettingsScreen({super.key});

  @override
  State<WalletSettingsScreen> createState() => _WalletSettingsScreenState();
}

class _WalletSettingsScreenState extends State<WalletSettingsScreen> {
  bool _useWalletByDefault = true;
  bool _lowBalanceAlert = true;
  bool _showMiniStatementOnHome = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          'Wallet settings',
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Payment preferences'),
          SwitchListTile(
            value: _useWalletByDefault,
            activeColor: AppColors.brandMain,
            onChanged: (v) {
              setState(() => _useWalletByDefault = v);
            },
            title: const Text(
              'Use wallet as default payment method',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'When possible, payments will use wallet balance first.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Alerts & notifications'),
          SwitchListTile(
            value: _lowBalanceAlert,
            activeColor: AppColors.brandMain,
            onChanged: (v) {
              setState(() => _lowBalanceAlert = v);
            },
            title: const Text(
              'Low balance alert',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Get a notification when your balance goes below a safe limit.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          SwitchListTile(
            value: _showMiniStatementOnHome,
            activeColor: AppColors.brandMain,
            onChanged: (v) {
              setState(() => _showMiniStatementOnHome = v);
            },
            title: const Text(
              'Show mini statement on home',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Show latest wallet summary in your dashboard.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Note: These settings are only stored locally for now. '
                'Later you can sync them with Firestore/user profile.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
        ),
      ),
    );
  }
}