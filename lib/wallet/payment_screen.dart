import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/services/uddoktapay_service.dart';

/// এখন শুধু একটাই চ্যানেল ব্যবহার করছি
enum PaymentChannel { uddoktapay }

/// পেমেন্টের উদ্দেশ্য
enum PaymentPurpose {
  subscription,
  profileBoost,
  workerPayment,
  supporterPayment,
}

class PaymentScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final int duration;
  final PaymentPurpose purpose;
  final String? description;
  final String? referenceId;

  const PaymentScreen({
    Key? key,
    required this.planId,
    required this.amount,
    required this.duration,
    required this.purpose,
    this.description,
    this.referenceId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentChannel _selectedChannel = PaymentChannel.uddoktapay;
  bool _isPaying = false;

  // তোমার Vercel-based admin backend URL
  static const String _adminBaseUrl =
      'https://findus-admin-panel.vercel.app';

  // শেষ পেমেন্টের txId (উদাহরণস্বরূপ রাখা)
  String? _lastPaymentTxId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = _getTitleForPurpose(widget.purpose);

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopSection(theme),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a payment method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              theme,
              PaymentChannel.uddoktapay,
              'UddoktaPay',
              'Pay via UddoktaPay (bKash, Nagad, Card etc.)',
              Icons.payment_rounded,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _onConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isPaying
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text('Confirm & Pay'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- TOP SECTION: Amount + Plan Info ----------

  Widget _buildTopSection(ThemeData theme) {
    final String durationLabel =
    widget.purpose == PaymentPurpose.subscription
        ? _durationLabel(widget.duration)
        : 'One-time payment';
    final String amountLabel = '৳${widget.amount}';

    final String subtitle = _getSubtitleForPurpose(
      widget.purpose,
      widget.description,
    );

    return Column(
      children: [
        // শুধু amount summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForPurpose(widget.purpose),
                  color: AppColors.brandMain,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Duration: $durationLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Payment method option ----------

  Widget _buildPaymentOption(
      ThemeData theme,
      PaymentChannel channel,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final selected = _selectedChannel == channel;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedChannel = channel),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.brandMain
                : theme.dividerColor.withOpacity(0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PaymentChannel>(
              value: channel,
              groupValue: _selectedChannel,
              onChanged: (v) {
                setState(() => _selectedChannel = v!);
              },
              activeColor: AppColors.brandMain,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brandMain, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// subscription হলে payment successful–এর পর backend এ
  /// `/api/apply-subscription` কল করবে।
  Future<void> _applySubscriptionIfNeeded() async {
    if (widget.purpose != PaymentPurpose.subscription) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final uri = Uri.parse('$_adminBaseUrl/api/apply-subscription');

      final body = jsonEncode({
        "uid": currentUser.uid,
        "planId": widget.planId,
        "amount": widget.amount,
        "channel": _selectedChannel.name,
        "txId": _lastPaymentTxId ?? "",
      });

      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode != 200) {
        debugPrint(
            'apply-subscription failed: ${resp.statusCode} ${resp.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Subscription activation failed on server.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('apply-subscription exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Subscription activation error. Please try again.'),
        ),
      );
    }
  }

  // ---------- Confirm Payment Logic ----------

  Future<void> _onConfirmPayment() async {
    // একটাই channel থাকলেও future-proof check
    if (_selectedChannel != PaymentChannel.uddoktapay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select UddoktaPay as payment method.'),
        ),
      );
      return;
    }

    _lastPaymentTxId = null;

    setState(() {
      _isPaying = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? 'user@example.com';
      final userName = currentUser?.displayName ?? 'FINDUS User';

      final result = await UddoktaPayService.payWithUddoktaPay(
        context: context,
        amount: widget.amount.toDouble(),
        customerName: userName,
        customerEmail: userEmail,
      );

      if (!(result['success'] as bool)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'UddoktaPay payment failed: ${result['error'] ?? 'Unknown error'}',
            ),
          ),
        );
        return;
      }

      final trxId = result['transactionId'] as String?;
      _lastPaymentTxId = trxId;

      // Subscription হলে backend–এ সাবস্ক্রিপশন আপডেট
      await _applySubscriptionIfNeeded();

      // Notification পাঠানো
      if (currentUser != null) {
        await NotificationService.sendNotificationToUser(
          toUserId: currentUser.uid,
          title: _getPaymentNotificationTitle(widget.purpose),
          body: 'You paid ৳${widget.amount} via UddoktaPay.',
          type: 'payment',
          status: 'success',
          data: {
            'amount': widget.amount,
            'purpose': widget.purpose.name,
            'planId': widget.planId,
            'duration': widget.duration,
            'channel': _selectedChannel.name,
            'referenceId': widget.referenceId,
            'txId': _lastPaymentTxId,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  // ---------- Helpers ----------

  String _durationLabel(int months) {
    switch (months) {
      case 1:
        return '1 month';
      case 3:
        return '3 months';
      case 6:
        return '6 months';
      case 12:
        return '12 months';
      default:
        return '$months month(s)';
    }
  }

  String _getTitleForPurpose(PaymentPurpose purpose) {
    switch (purpose) {
      case PaymentPurpose.subscription:
        return 'Subscription Payment';
      case PaymentPurpose.profileBoost:
        return 'Profile Boost Payment';
      case PaymentPurpose.workerPayment:
        return 'Worker Payment';
      case PaymentPurpose.supporterPayment:
        return 'Supporter Payment';
    }
  }

  String _getSubtitleForPurpose(
      PaymentPurpose purpose,
      String? description,
      ) {
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }

    switch (purpose) {
      case PaymentPurpose.subscription:
        return 'FINDUS subscription plan payment';
      case PaymentPurpose.profileBoost:
        return 'Boost your profile visibility';
      case PaymentPurpose.workerPayment:
        return 'Pay directly to your selected worker';
      case PaymentPurpose.supporterPayment:
        return 'Pay your supporter for this job/service';
    }
  }

  IconData _iconForPurpose(PaymentPurpose purpose) {
    switch (purpose) {
      case PaymentPurpose.subscription:
        return Icons.workspace_premium_rounded;
      case PaymentPurpose.profileBoost:
        return Icons.trending_up_rounded;
      case PaymentPurpose.workerPayment:
        return Icons.handshake_rounded;
      case PaymentPurpose.supporterPayment:
        return Icons.volunteer_activism_rounded;
    }
  }

  String _getPaymentNotificationTitle(PaymentPurpose purpose) {
    switch (purpose) {
      case PaymentPurpose.subscription:
        return 'Subscription payment successful';
      case PaymentPurpose.profileBoost:
        return 'Profile boost payment successful';
      case PaymentPurpose.workerPayment:
        return 'Worker payment sent';
      case PaymentPurpose.supporterPayment:
        return 'Supporter payment sent';
    }
  }
}