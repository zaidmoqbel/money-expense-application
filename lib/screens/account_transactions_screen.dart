import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class AccountTransactionsScreen extends StatefulWidget {
  final String account;

  const AccountTransactionsScreen({super.key, required this.account});

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  List _allTransactions = [];
  List _displayedTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    _allTransactions = provider.transactions
        .where((transaction) => transaction.account == widget.account)
        .toList()
      ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    _loadMoreTransactions();
  }

  void _loadMoreTransactions() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex < _allTransactions.length) {
      setState(() {
        _displayedTransactions.addAll(_allTransactions.sublist(startIndex, endIndex > _allTransactions.length ? _allTransactions.length : endIndex));
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account} Transactions'),
      ),
      body: _displayedTransactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions found for this account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _displayedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _displayedTransactions[index];
                      final isIncome = transaction.type == 'income';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isIncome ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isIncome ? Icons.call_received : Icons.call_made,
                                color: isIncome ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(DateTime.parse(transaction.date)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isIncome ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_displayedTransactions.length < _allTransactions.length)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: _loadMoreTransactions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Load More'),
                    ),
                  ),
              ],
            ),
    );
  }
}
