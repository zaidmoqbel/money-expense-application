import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final settings = provider.settings;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // App Settings Section
              _buildSectionHeader('App Settings'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildCurrencyTile(context, settings, provider),
                const Divider(height: 1),
                _buildNotificationsTile(settings, provider),
                const Divider(height: 1),
                _buildReminderDaysTile(context, settings, provider),
              ]),
              const SizedBox(height: 24),

              // Financial Goals Section
              _buildSectionHeader('Financial Goals'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildYearlyGoalTile(context, settings, provider),
              ]),
              const SizedBox(height: 24),

              // Data Management Section
              _buildSectionHeader('Data Management'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildExportDataTile(context),
                const Divider(height: 1),
                _buildClearDataTile(context, provider),
              ]),
              const SizedBox(height: 24),

              // Category Management Section
              _buildSectionHeader('Category Management'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildManageCategoriesTile(context, provider),
              ]),
              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildAboutTile(context),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildCurrencyTile(
    BuildContext context,
    AppSettings settings,
    AppProvider provider,
  ) {
    final currencies = {
      'usd': '\$ USD',
      'eur': '€ EUR',
      'gbp': '£ GBP',
      'jpy': '¥ JPY',
      'try': '₺ TRY',
      'jod': 'د.أ JOD',
    };

    return ListTile(
      leading: const Icon(Icons.attach_money, color: AppColors.primary),
      title: const Text('Currency'),
      subtitle: Text(currencies[settings.currency] ?? 'USD'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Currency'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: currencies.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: settings.currency,
                  onChanged: (value) async {
                    if (value != null) {
                      try {
                        // Convert all data to the new currency (this also updates settings)
                        await provider.convertAllDataToNewCurrency(value);

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Currency changed successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error changing currency: $e')),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTile(AppSettings settings, AppProvider provider) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined, color: AppColors.primary),
      title: const Text('Notifications'),
      subtitle: const Text('Receive payment reminders'),
      value: settings.notifications,
      activeThumbColor: AppColors.primary,
      onChanged: (value) {
        provider.updateSettings(AppSettings(
          currency: settings.currency,
          darkMode: settings.darkMode,
          notifications: value,
          reminderDays: settings.reminderDays,
          yearlyExpenseGoal: settings.yearlyExpenseGoal,
        ));
      },
    );
  }

  Widget _buildReminderDaysTile(
    BuildContext context,
    AppSettings settings,
    AppProvider provider,
  ) {
    return ListTile(
      leading: const Icon(Icons.access_time, color: AppColors.primary),
      title: const Text('Reminder Days'),
      subtitle: Text('${settings.reminderDays} days before due date'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            final controller = TextEditingController(text: settings.reminderDays);
            
            return AlertDialog(
              title: const Text('Reminder Days'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days before due date',
                  suffix: Text('days'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.updateSettings(AppSettings(
                      currency: settings.currency,
                      darkMode: settings.darkMode,
                      notifications: settings.notifications,
                      reminderDays: controller.text,
                      yearlyExpenseGoal: settings.yearlyExpenseGoal,
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildYearlyGoalTile(
    BuildContext context,
    AppSettings settings,
    AppProvider provider,
  ) {
    return ListTile(
      leading: const Icon(Icons.flag_outlined, color: AppColors.primary),
      title: const Text('Yearly Expense Goal'),
      subtitle: Text('${Provider.of<AppProvider>(context, listen: false).getCurrencySymbol()}${settings.yearlyExpenseGoal.toStringAsFixed(0)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            final controller = TextEditingController(
              text: settings.yearlyExpenseGoal.toStringAsFixed(0),
            );

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
                    final amount = double.tryParse(controller.text) ?? settings.yearlyExpenseGoal;
                    provider.updateSettings(AppSettings(
                      currency: settings.currency,
                      darkMode: settings.darkMode,
                      notifications: settings.notifications,
                      reminderDays: settings.reminderDays,
                      yearlyExpenseGoal: amount,
                    ));
                    Navigator.pop(context);
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
      },
    );
  }

  Widget _buildExportDataTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.upload_outlined, color: AppColors.primary),
      title: const Text('Export Data'),
      subtitle: const Text('Export transactions as CSV'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _exportData(context),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final transactions = provider.transactions;

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
        return;
      }

      final filePath = await ExportService.exportTransactionsToCSV(transactions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions exported to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }

  Widget _buildClearDataTile(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: AppColors.error),
      title: const Text(
        'Clear All Data',
        style: TextStyle(color: AppColors.error),
      ),
      subtitle: const Text('Delete all transactions and goals'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              'Are you sure you want to delete all data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.deleteAllData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete All'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageCategoriesTile(BuildContext context, AppProvider provider) {
    return ListTile(
      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
      title: const Text('Manage Categories'),
      subtitle: const Text('Add or remove transaction categories'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _CategoryManagementDialog(provider: provider),
        );
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.primary),
      title: const Text('About'),
      subtitle: const Text('Version 1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'Smart Expense Tracker',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: AppColors.primary,
          ),
          children: [
            const Text(
              'A modern and minimal mobile finance tracker app for managing your expenses, savings goals, and installments.',
            ),
          ],
        );
      },
    );
  }
}

class _CategoryManagementDialog extends StatefulWidget {
  final AppProvider provider;

  const _CategoryManagementDialog({required this.provider});

  @override
  State<_CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<_CategoryManagementDialog> {
  final TextEditingController _newCategoryController = TextEditingController();
  String _selectedType = 'expense';
  List<String> _currentCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.provider.getCategoriesByType(_selectedType);
      setState(() {
        _currentCategories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  void _changeType(String type) {
    setState(() => _selectedType = type);
    _loadCategories();
  }

  Future<void> _addCategory() async {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isNotEmpty && !_currentCategories.contains(categoryName)) {
      try {
        await widget.provider.addCategory(categoryName, _selectedType);
        _newCategoryController.clear();
        await _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$categoryName" added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
      }
    } else if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists')),
      );
    }
  }

  Future<void> _removeCategory(String category) async {
    // Check if it's a default category
    final defaultCategories = _selectedType == 'expense'
        ? ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Healthcare']
        : ['Salary', 'Freelance', 'Investment', 'Gift'];

    if (defaultCategories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove default categories')),
      );
      return;
    }

    try {
      await widget.provider.removeCategory(category, _selectedType);
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$category" removed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _changeType('expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'expense' ? Colors.orange : Colors.grey[200],
                      foregroundColor: _selectedType == 'expense' ? Colors.white : Colors.grey[700],
                    ),
                    child: const Text('Expenses'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _changeType('income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'income' ? Colors.green : Colors.grey[200],
                      foregroundColor: _selectedType == 'income' ? Colors.white : Colors.grey[700],
                    ),
                    child: const Text('Income'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add New Category
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Categories
            const Text(
              'Current Categories:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currentCategories.length,
                itemBuilder: (context, index) {
                  final category = _currentCategories[index];
                  return ListTile(
                    title: Text(category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCategory(category),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }
}
