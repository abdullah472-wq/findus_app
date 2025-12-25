import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WalletTransactionHistoryScreen extends StatefulWidget {
  const WalletTransactionHistoryScreen({super.key});

  @override
  State<WalletTransactionHistoryScreen> createState() =>
      _WalletTransactionHistoryScreenState();
}

class _WalletTransactionHistoryScreenState
    extends State<WalletTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _filterType = 'all'; // all / income / expense
  List<_Tx> _allTx = [];
  List<_Tx> _visibleTx = [];

  @override
  void initState() {
    super.initState();
    _allTx = [
      _Tx(
        title: 'Payment to Rahim (Driver)',
        date: 'Today, 10:30 AM',
        amount: -150,
        method: 'bKash',
        icon: FontAwesomeIcons.car,
      ),
      _Tx(
        title: 'Earnings from Gardening',
        date: 'Yesterday, 4:00 PM',
        amount: 500,
        method: 'Wallet',
        icon: FontAwesomeIcons.leaf,
      ),
      _Tx(
        title: 'Added via bKash',
        date: '24 Oct, 2023',
        amount: 1000,
        method: 'bKash',
        icon: FontAwesomeIcons.mobileScreenButton,
      ),
      _Tx(
        title: 'Payment to Electrician',
        date: '20 Oct, 2023',
        amount: -400,
        method: 'Wallet',
        icon: FontAwesomeIcons.bolt,
      ),
    ];
    _applyFilters();
  }

  void _applyFilters() {
    String q = _searchController.text.trim().toLowerCase();
    setState(() {
      _visibleTx = _allTx.where((tx) {
        if (_filterType == 'income' && tx.amount <= 0) return false;
        if (_filterType == 'expense' && tx.amount >= 0) return false;
        if (q.isNotEmpty &&
            !tx.title.toLowerCase().contains(q) &&
            !tx.method.toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _setFilter(String type) {
    _filterType = type;
    _applyFilters();
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
          'Wallet transactions',
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _visibleTx.length,
              itemBuilder: (_, i) => _buildTxItem(_visibleTx[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search by title or method (bKash, Wallet...)',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildChip('All', 'all'),
        const SizedBox(width: 8),
        _buildChip('Income', 'income'),
        const SizedBox(width: 8),
        _buildChip('Expense', 'expense'),
      ],
    );
  }

  Widget _buildChip(String label, String value) {
    final bool selected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setFilter(value),
      selectedColor: AppColors.brandMain,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.brandDark,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTxItem(_Tx tx) {
    final isIncome = tx.amount > 0;
    final amountText =
        '${isIncome ? '+ ' : '- '}৳ ${tx.amount.abs().toStringAsFixed(0)}';

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
              tx.icon,
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
                  tx.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Method: ${tx.method}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountText,
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

class _Tx {
  _Tx({
    required this.title,
    required this.date,
    required this.amount,
    required this.method,
    required this.icon,
  });

  final String title;
  final String date;
  final double amount;
  final String method;
  final IconData icon;
}