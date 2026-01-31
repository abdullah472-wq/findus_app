// lib/screens/settings/delete_account_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    // ১. কনফার্মেশন ডায়ালগ
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // বাইরে ট্যাপ/back দিলে ডায়ালগ বন্ধ হবে
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Account?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action cannot be undone. All your data, chats, and history will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are not logged in.")),
          );
        }
        return;
      }

      final uid = user.uid;

      // ২. Firestore থেকে user doc ডিলিট
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // TODO: চাইলে এখানে আরও ডাটা ক্লিন করতে পারো (chats, reviews, ইত্যাদি)

      // ৩. Firebase Auth থেকে user ডিলিট
      await user.delete();

      if (!mounted) return;

      // ৪. LoginScreen–এ পাঠিয়ে সব route ক্লিয়ার করা
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        // রি-অথেন্টিকেশন দরকার
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("Security Alert: Please login again to delete your account."),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "DELETE ACCOUNT",
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: false,
      bodyPadding: const EdgeInsets.all(24.0),
      body: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          Text(
            "Are you sure?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Deleting your account is permanent. All your history, badges, and points will be lost forever.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isDeleting ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "CONFIRM DELETE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}