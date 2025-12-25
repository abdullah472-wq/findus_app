import 'package:flutter/material.dart';
import 'package:uddoktapay/uddoktapay.dart';
import 'package:uddoktapay/models/customer_model.dart';
import 'package:uddoktapay/models/request_response.dart';

class UddoktaPayService {
  /// UddoktaPay payment start করে result return করবে
  static Future<Map<String, dynamic>> payWithUddoktaPay({
    required BuildContext context,
    required double amount,
    required String customerName,
    required String customerEmail,
  }) async {
    try {
      final response = await UddoktaPay.createPayment(
        context: context,
        customer: CustomerDetails(
          fullName: customerName,
          email: customerEmail,
        ),
        amount: amount.toString(), // String হিসেবে পাঠাতে হয়
      );

      // ResponseStatus অনুযায়ী map বানাই
      if (response.status == ResponseStatus.completed) {
        debugPrint(
            'UddoktaPay completed, Trx ID: ${response.transactionId}, Sender: ${response.senderNumber}');
        return {
          'success': true,
          'status': 'completed',
          'transactionId': response.transactionId,
          'senderNumber': response.senderNumber,
          'error': null,
        };
      } else if (response.status == ResponseStatus.canceled) {
        debugPrint('UddoktaPay canceled');
        return {
          'success': false,
          'status': 'canceled',
          'transactionId': null,
          'senderNumber': null,
          'error': 'Payment canceled',
        };
      } else if (response.status == ResponseStatus.pending) {
        debugPrint('UddoktaPay pending');
        return {
          'success': false,
          'status': 'pending',
          'transactionId': null,
          'senderNumber': null,
          'error': 'Payment pending',
        };
      } else {
        return {
          'success': false,
          'status': 'unknown',
          'transactionId': null,
          'senderNumber': null,
          'error': 'Unknown status',
        };
      }
    } catch (e) {
      debugPrint('UddoktaPay error: $e');
      return {
        'success': false,
        'status': 'error',
        'transactionId': null,
        'senderNumber': null,
        'error': e.toString(),
      };
    }
  }
}