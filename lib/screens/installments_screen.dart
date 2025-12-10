import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/installment.dart';
import '../theme/app_colors.dart';

class InstallmentsScreen extends StatelessWidget {
  const InstallmentsScreen({super.key});

  IconData _getInstallmentIcon(String bankName) {
    final name = bankName.toLowerCase();
    if (name.contains('credit') || name.contains('card')) {
      return Icons.credit_card;
    } else if (name.contains('car') || name.contains('auto') || name.contains('vehicle')) {
      return Icons.directions_car;
    } else if (name.contains('home') || name.contains('house') || name.contains('mortgage')) {
      return Icons.home;
    } else if (name.contains('phone') || name.contains('mobile')) {
      return Icons.phone_android;
    } else if (name.contains('loan') || name.contains('finance')) {
      return Icons.account_balance;
    } else if (name.contains('shopping') || name.contains('store') || name.contains('retail')) {
      return Icons.shopping_cart;
    } else if (name.contains('education') || name.contains('school') || name.contains('university')) {
      return Icons.school;
    } else if (name.contains('medical') || name.contains('health') || name.contains('hospital')) {
      return Icons.local_hospital;
    } else {
      return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installments & Credit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddInstallmentDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final installments = provider.installments;
          final totalRemaining = provider.getTotalRemainingInstallments();

          if (installments.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(context, totalRemaining, installments.length),
              
              // Installments List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: installments.length,
                  itemBuilder: (context, index) {
                    return _buildInstallmentCard(
                      context,
                      installments[index],
                      provider,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalRemaining, int count) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.warning, AppColors.warningDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: Colors.white.withOpacity(0.9),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Remaining',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalRemaining),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Active',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Add New Installment Plan Button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: () => _showAddInstallmentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Installment Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.warning,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
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
              Icons.credit_card_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Installments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your installment payments here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddInstallmentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Installment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(
    BuildContext context,
    Installment installment,
    AppProvider provider,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final progress = installment.paidInstallments / installment.totalInstallments;
    final color = AppColors.fromHex(installment.color);
    final isPaid = installment.status == 'paid';

    return Container(
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getInstallmentIcon(installment.bankName),
                    color: color,
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
                      installment.bankName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${dateFormat.format(DateTime.parse(installment.dueDate))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${installment.paidInstallments} of ${installment.totalInstallments} paid',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(installment.monthlyInstallment),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(installment.remainingAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              if (!isPaid)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.markInstallmentAsPaid(installment.id);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!isPaid) const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _confirmDelete(context, installment.id, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddInstallmentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final totalAmountController = TextEditingController();
    final monthlyController = TextEditingController();
    final installmentsController = TextEditingController();
    String selectedLogo = '🏦';
    String selectedColor = AppColors.toHex(AppColors.warning);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Installment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Bank/Store Name',
                  hintText: 'e.g., HSBC Credit Card',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Payment',
                  prefixText: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: installmentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Installments',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  totalAmountController.text.isNotEmpty &&
                  monthlyController.text.isNotEmpty &&
                  installmentsController.text.isNotEmpty) {
                final installment = Installment(
                  id: 'inst-${DateTime.now().millisecondsSinceEpoch}',
                  bankName: nameController.text,
                  totalAmount: double.parse(totalAmountController.text),
                  monthlyInstallment: double.parse(monthlyController.text),
                  paidInstallments: 0,
                  totalInstallments: int.parse(installmentsController.text),
                  dueDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                  status: 'upcoming',
                  color: selectedColor,
                  logo: selectedLogo,
                  createdAt: DateTime.now().toIso8601String(),
                );

                Provider.of<AppProvider>(context, listen: false).addInstallment(installment);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Installment'),
        content: const Text('Are you sure you want to delete this installment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteInstallment(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
