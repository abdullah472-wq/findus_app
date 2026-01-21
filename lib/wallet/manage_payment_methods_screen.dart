import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() =>
      _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState
    extends State<ManagePaymentMethodsScreen> {
  // ডেমো ডাটা – future এ Firestore/user profile থেকে আসবে
  final List<_Method> _methods = [
    _Method(
      id: 'bkash',
      name: 'bKash',
      icon: FontAwesomeIcons.mobileScreen,
      isLinked: true,
      isDefault: true,
    ),
    _Method(
      id: 'nagad',
      name: 'Nagad',
      icon: FontAwesomeIcons.mobile,
      isLinked: false,
      isDefault: false,
    ),
    _Method(
      id: 'card',
      name: 'Visa/MasterCard',
      icon: FontAwesomeIcons.creditCard,
      isLinked: true,
      isDefault: false,
    ),
  ];

  void _setDefault(String id) {
    setState(() {
      for (final m in _methods) {
        m.isDefault = (m.id == id);
      }
    });
  }

  void _toggleLinked(String id, bool value) {
    setState(() {
      final method = _methods.firstWhere((m) => m.id == id);
      method.isLinked = value;
      if (!value && method.isDefault) {
        method.isDefault = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          'Manage payment methods',
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
          const Text(
            'Linked accounts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          ..._methods.map((m) => _buildMethodTile(context, m)),
          const SizedBox(height: 24),
          const Text(
            'Note: In the future, you can connect your own bKash/Nagad/card '
                'accounts here and sync them securely with your backend.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(BuildContext context, _Method m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
        border: Border.all(
          color: m.isDefault ? AppColors.brandMain : Colors.grey.shade300,
          width: m.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(m.icon, color: AppColors.brandDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.isLinked ? 'Linked' : 'Not linked',
                  style: TextStyle(
                    fontSize: 12,
                    color: m.isLinked ? Colors.green : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: m.isLinked,
            activeThumbColor: AppColors.brandMain,
            onChanged: (v) => _onTogglePressed(context, m, v),
          ),
          const SizedBox(width: 8),
          Radio<String>(
            value: m.id,
            groupValue:
            _methods.firstWhereOrNull((mm) => mm.isDefault)?.id,
            onChanged: m.isLinked ? (v) => _setDefault(m.id) : null,
            activeColor: AppColors.brandMain,
          ),
        ],
      ),
    );
  }

  Future<void> _onTogglePressed(
      BuildContext context, _Method method, bool value) async {
    if (!value) {
      // linked → unlink (toggle off)
      _toggleLinked(method.id, false);
      return;
    }

    // currently unlinked, user wants to link → form/field দেখাও
    final bool? success = await _showLinkDialog(context, method);

    if (success == true) {
      // demo: আসল ডাটাবেজে সেভ না করেও এখন শুধু linked করে দিচ্ছি
      _toggleLinked(method.id, true);
    }
  }

  Future<bool?> _showLinkDialog(BuildContext context, _Method method) {
    final TextEditingController controller = TextEditingController();

    String label;
    String hint;

    if (method.id == 'bkash' || method.id == 'nagad') {
      label = '${method.name} number';
      hint = '01XXXXXXXXX';
    } else {
      label = 'Card last 4 digits';
      hint = '1234';
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link ${method.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                method.id == 'bkash'
                    ? 'Enter your active bKash number to link with FINDUS.'
                    : method.id == 'nagad'
                    ? 'Enter your active Nagad number to link with FINDUS.'
                    : 'Enter your card identifier to link with FINDUS.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // demo: শুধু খালি না কিনা দেখি
                      if (controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid value.'),
                          ),
                        );
                        return;
                      }
                      // ভবিষ্যতে এখানে backend call করে verify করা যাবে
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Link'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Method {
  _Method({
    required this.id,
    required this.name,
    required this.icon,
    this.isLinked = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final IconData icon;
  bool isLinked;
  bool isDefault;
}

// ছোট helper – firstWhereOrNull (null safety)
extension _FirstWhereOrNull<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}