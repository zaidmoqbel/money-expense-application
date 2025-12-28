import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import 'account_transactions_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  IconData _getAccountIcon(String accountType) {
    final type = accountType.toLowerCase();
    if (type.contains('cash')) {
      return Icons.money;
    } else if (type.contains('credit') || type.contains('card')) {
      return Icons.credit_card;
    } else if (type.contains('debit')) {
      return Icons.account_balance_wallet;
    } else if (type.contains('bank') || type.contains('transfer')) {
      return Icons.account_balance;
    } else if (type.contains('wallet')) {
      return Icons.account_balance_wallet;
    } else {
      return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final accountData = _calculateAccountData(provider.transactions);

          return Column(
            children: [
              // Summary Card
              if (accountData.isNotEmpty) _buildSummaryCard(context, accountData),
              const SizedBox(height: 20),

              // Accounts List
              Expanded(
                child: accountData.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: accountData.length,
                      itemBuilder: (context, index) {
                        final account = accountData.keys.elementAt(index);
                        final data = accountData[account]!;
                        return _buildAccountCard(context, account, data);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, AccountData> accountData) {
    final totalIncome = accountData.values.fold(0.0, (sum, data) => sum + data.income);
    final totalExpense = accountData.values.fold(0.0, (sum, data) => sum + data.expense);
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white.withOpacity(0.9),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Income',
                  totalIncome,
                  AppColors.success,
                  currencyFormat,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Expense',
                  totalExpense,
                  AppColors.warning,
                  currencyFormat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${accountData.length} Active Accounts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, NumberFormat currencyFormat) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Account Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add transactions to see account details',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, String accountType, AccountData data) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);
    final balance = data.income - data.expense;

    return GestureDetector(
      onTap: () => _showAccountOptionsDialog(context, accountType),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getAccountIcon(accountType),
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.transactionCount} transactions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Balance',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    currencyFormat.format(balance),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: balance >= 0 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Income and Expense details
          Row(
            children: [
              Expanded(
                child: _buildAccountDetailItem(
                  'Income',
                  data.income,
                  Icons.arrow_upward,
                  AppColors.success,
                  currencyFormat,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildAccountDetailItem(
                  'Expense',
                  data.expense,
                  Icons.arrow_downward,
                  AppColors.warning,
                  currencyFormat,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  void _showAccountOptionsDialog(BuildContext context, String accountType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('$accountType Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Transaction History'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountTransactionsScreen(account: accountType),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transfer Money'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  final allAccounts = _calculateAccountData(provider.transactions).keys.toList();
                  _showTransferDialog(context, provider, accountType, allAccounts);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountDetailItem(String label, double amount, IconData icon, Color color, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Map<String, AccountData> _calculateAccountData(List transactions) {
    final Map<String, AccountData> accountData = {};

    for (var transaction in transactions) {
      final account = transaction.account;
      if (!accountData.containsKey(account)) {
        accountData[account] = AccountData(
          income: 0.0,
          expense: 0.0,
          transactionCount: 0,
        );
      }

      final data = accountData[account]!;
      if (transaction.type == 'income') {
        accountData[account] = AccountData(
          income: data.income + transaction.amount,
          expense: data.expense,
          transactionCount: data.transactionCount + 1,
        );
      } else {
        accountData[account] = AccountData(
          income: data.income,
          expense: data.expense + transaction.amount,
          transactionCount: data.transactionCount + 1,
        );
      }
    }

    return accountData;
  }

  void _showTransferDialog(BuildContext context, AppProvider provider, String fromAccount, List<String> allAccounts) {
    // Include default account types plus existing accounts
    final defaultAccounts = ['Cash', 'Credit Card', 'Debit Card', 'Bank Account', 'Wallet'];
    final availableAccounts = {...defaultAccounts, ...allAccounts}.toList();
    String? selectedToAccount = availableAccounts.isNotEmpty ? availableAccounts.first : null;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Transfer from $fromAccount'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedToAccount,
                      decoration: const InputDecoration(
                        labelText: 'To Account',
                        border: OutlineInputBorder(),
                      ),
                      items: availableAccounts.map((account) {
                        return DropdownMenuItem(
                          value: account,
                          child: Text(account),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedToAccount = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: const OutlineInputBorder(),
                        prefixText: provider.getCurrencySymbol(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedToAccount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a destination account')),
                      );
                      return;
                    }

                    if (selectedToAccount == fromAccount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot transfer to the same account')),
                      );
                      return;
                    }

                    final amountText = amountController.text.trim();
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an amount')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid positive amount')),
                      );
                      return;
                    }

                    try {
                      await provider.transferBetweenAccounts(
                        fromAccount,
                        selectedToAccount!,
                        amount,
                        notesController.text.trim(),
                      );

                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully transferred ${provider.getCurrencySymbol()}$amount from $fromAccount to $selectedToAccount')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transfer failed: $e')),
                      );
                    }
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AccountData {
  final double income;
  final double expense;
  final int transactionCount;

  AccountData({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });
}
