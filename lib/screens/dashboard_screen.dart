import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/transaction_card.dart';
import '../models/transaction.dart';
import '../models/app_settings.dart';
import '../screens/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filterType = 'all'; // all, income, expense

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final balance = provider.calculateBalance();
        final income = provider.calculateTotalIncome();
        final expense = provider.calculateTotalExpense();
        final filteredTransactions = provider.getFilteredTransactions(_filterType);
        final yearlyGoal = provider.settings.yearlyExpenseGoal;
        final yearlyProgress = yearlyGoal > 0 ? (expense / yearlyGoal).clamp(0.0, 1.0) : 0.0;

        // DEBUG: Print transaction count
        print('📊 Dashboard - Total transactions: ${provider.transactions.length}');
        print('💰 Balance: ${Provider.of<AppProvider>(context, listen: false).getCurrencySymbol()}${balance.toStringAsFixed(2)}');
        print('📈 Income: \$${income.toStringAsFixed(2)}');
        print('📉 Expense: ${Provider.of<AppProvider>(context, listen: false).getCurrencySymbol()}${expense.toStringAsFixed(2)}');
        print('🔍 Filtered transactions: ${filteredTransactions.length}');

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Yearly Expense Goal Card
                  _buildYearlyGoalCard(expense, yearlyGoal, yearlyProgress),
                  const SizedBox(height: 20),

                  // Balance Overview Card
                  _buildBalanceCard(balance, income, expense),
                  const SizedBox(height: 20),

                  // Filter Buttons
                  _buildFilterButtons(),
                  const SizedBox(height: 16),

                  // Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${filteredTransactions.length} total',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transaction List
                  filteredTransactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTransactions.take(10).length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return TransactionCard(
                              transaction: transaction,
                              onTap: () => _showTransactionDetails(transaction),
                              onEdit: () => _editTransaction(transaction),
                              onDelete: () => _deleteTransaction(transaction),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Expense Tracker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Track your finances easily',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyGoalCard(double currentExpense, double yearlyGoal, double progress) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return GestureDetector(
      onTap: yearlyGoal > 0 ? () => _showYearlyGoalDialog() : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yearly Expense Goal',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (yearlyGoal == 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Not set yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showYearlyGoalDialog,
                              icon: const Icon(Icons.flag, size: 16),
                              label: const Text('Set Goal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          currencyFormat.format(yearlyGoal),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (yearlyGoal > 0)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (yearlyGoal > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.error : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currencyFormat.format(currentExpense)} spent',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Tap to edit',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Income',
                  income,
                  Icons.arrow_upward,
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildBalanceItem(
                  'Expense',
                  expense,
                  Icons.arrow_downward,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon, Color color) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

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
                color: Colors.white.withOpacity(0.8),
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
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Row(
      children: [
        _buildFilterButton('All', 'all'),
        const SizedBox(width: 8),
        _buildFilterButton('Income', 'income'),
        const SizedBox(width: 8),
        _buildFilterButton('Expense', 'expense'),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add your first transaction',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryExpenses(List transactions) {
    final Map<String, double> categoryExpenses = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryExpenses;
  }

  Map<String, double> _calculateCategoryIncome(List transactions) {
    final Map<String, double> categoryIncome = {};

    for (var transaction in transactions) {
      if (transaction.type == 'income') {
        categoryIncome[transaction.category] =
            (categoryIncome[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryIncome;
  }

  void _editTransaction(TransactionModel transaction) {
    // Show add transaction screen with pre-filled data for editing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
    );
  }

  void _deleteTransaction(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AppProvider>(context, listen: false).deleteTransaction(transaction.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted successfully')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 2);
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with type and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: transaction.type == 'income' ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        transaction.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: transaction.type == 'income' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '${transaction.type == 'income' ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: transaction.type == 'income' ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category
                _buildDetailRow('Category', transaction.category, Icons.category),
                const SizedBox(height: 16),

                // Account (Cash/Credit)
                _buildDetailRow('Payment Method', transaction.account, Icons.account_balance_wallet),
                const SizedBox(height: 16),

                // Date
                _buildDetailRow('Date', dateFormat.format(DateTime.parse(transaction.date)), Icons.calendar_today),
                const SizedBox(height: 16),

                // Time (from createdAt)
                _buildDetailRow('Time', timeFormat.format(DateTime.parse(transaction.createdAt)), Icons.access_time),
                const SizedBox(height: 16),

                // Notes (if available)
                if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                  _buildDetailRow('Notes', transaction.notes!, Icons.notes),
                  const SizedBox(height: 16),
                ],

                // Transaction ID
                _buildDetailRow('Transaction ID', transaction.id, Icons.tag),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showYearlyGoalDialog() {
    final controller = TextEditingController(
      text: Provider.of<AppProvider>(context, listen: false).settings.yearlyExpenseGoal.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Your Yearly Expense Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How much do you think you will spend this year?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter amount',
                  prefixText: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0.0;
                Provider.of<AppProvider>(context, listen: false).updateSettings(
                  AppSettings(
                    currency: Provider.of<AppProvider>(context, listen: false).settings.currency,
                    darkMode: Provider.of<AppProvider>(context, listen: false).settings.darkMode,
                    notifications: Provider.of<AppProvider>(context, listen: false).settings.notifications,
                    reminderDays: Provider.of<AppProvider>(context, listen: false).settings.reminderDays,
                    yearlyExpenseGoal: amount,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Yearly goal ${amount > 0 ? 'updated' : 'cleared'} successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Goal'),
            ),
          ],
        );
      },
    );
  }
}
