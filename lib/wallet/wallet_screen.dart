import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'add_money_screen.dart';
import 'withdraw_screen.dart';
import 'wallet_settings_screen.dart';
import 'manage_payment_methods_screen.dart';
import 'wallet_transaction_history_screen.dart';
import 'package:findus_app/screens/settings/faq_screen.dart';

enum WalletMenuAction { settings, downloadStatement, help }

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _onMenuSelected(BuildContext context, WalletMenuAction action) {
    switch (action) {
      case WalletMenuAction.settings:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WalletSettingsScreen(),
          ),
        );
        break;
      case WalletMenuAction.downloadStatement:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Statement download (PDF/CSV) feature coming soon.',
            ),
          ),
        );
        break;
      case WalletMenuAction.help:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FaqScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text(
          "My Wallet",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<WalletMenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (action) => _onMenuSelected(context, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: WalletMenuAction.settings,
                child: Text('Wallet settings'),
              ),
              PopupMenuItem(
                value: WalletMenuAction.downloadStatement,
                child: Text('Download statement'),
              ),
              PopupMenuItem(
                value: WalletMenuAction.help,
                child: Text('Help & support'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ১. মেইন ব্যালেন্স কার্ড
          _buildMainBalanceCard(),

          // ২. অ্যাভেইলেবল / লকড / আপকামিং ইনফো
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildInfoRow(),
          ),

          const SizedBox(height: 16),

          // ৩. অ্যাকশন বাটনস (Add, Withdraw)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.add,
                    "Add Money",
                    AppColors.brandMain,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddMoneyScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    Icons.download,
                    "Withdraw",
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WithdrawScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ৪. সেভড পেমেন্ট মেথড / লিংকড অ্যাকাউন্ট (ছোট কার্ড)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPaymentMethodsCard(context),
          ),

          const SizedBox(height: 20),

          // ৫. ট্রানজেকশন হিস্ট্রি টাইটেল + View All বাটন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const WalletTransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      color: AppColors.brandMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ৬. ট্রানজেকশন লিস্ট
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildTransactionItem(
                  title: "Payment to Rahim (Driver)",
                  date: "Today, 10:30 AM",
                  amount: "- ৳ 150",
                  isIncome: false,
                  icon: FontAwesomeIcons.car,
                ),
                _buildTransactionItem(
                  title: "Earnings from Gardening",
                  date: "Yesterday, 4:00 PM",
                  amount: "+ ৳ 500",
                  isIncome: true,
                  icon: FontAwesomeIcons.leaf,
                ),
                _buildTransactionItem(
                  title: "Added via bKash",
                  date: "24 Oct, 2023",
                  amount: "+ ৳ 1,000",
                  isIncome: true,
                  icon: FontAwesomeIcons.mobileScreenButton,
                ),
                _buildTransactionItem(
                  title: "Payment to Electrician",
                  date: "20 Oct, 2023",
                  amount: "- ৳ 400",
                  isIncome: false,
                  icon: FontAwesomeIcons.bolt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========== SECTION WIDGETS ===========

  Widget _buildMainBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, AppColors.brandMain],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // উপরে ওয়ালেট টাইটেল + আইকন
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Icon(
                FontAwesomeIcons.wallet,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "৳ 2,450.00",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Updated just now",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),

          // ইনকাম এবং খরচ সেকশন
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_downward,
                  label: "Income this month",
                  amount: "৳ 3,500",
                  iconColor: Colors.greenAccent,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white24,
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward,
                  label: "Spending this month",
                  amount: "৳ 1,050",
                  iconColor: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ২. Available / Locked / Upcoming payouts row
  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            title: "Available",
            amount: "৳ 2,000",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            title: "Locked",
            amount: "৳ 300",
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            title: "Next Payout",
            amount: "৳ 450",
            color: AppColors.brandMain,
          ),
        ),
      ],
    );
  }

  // ৩. Payment methods / Linked Accounts ছোট কার্ড
  Widget _buildPaymentMethodsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.creditCard,
            color: AppColors.brandDark,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Linked payment methods:\n• bKash • Nagad • Visa/MasterCard",
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagePaymentMethodsScreen(),
                ),
              );
            },
            child: const Text(
              "Manage",
              style: TextStyle(
                color: AppColors.brandMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ছোট স্ট্যাট widget
  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String amount,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        )
      ],
    );
  }

  // Horizontal info tile
  Widget _buildInfoTile({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Add/Withdraw action button
  Widget _buildActionButton(
      IconData icon,
      String label,
      Color accentColor,
      VoidCallback onTap,
      ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: accentColor),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Transaction item
  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isIncome,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withOpacity(0.08)
                  : Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isIncome ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}