import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';

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
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateSettings(AppSettings(
                        currency: value,
                        darkMode: settings.darkMode,
                        notifications: settings.notifications,
                        reminderDays: settings.reminderDays,
                        yearlyExpenseGoal: settings.yearlyExpenseGoal,
                      ));
                      Navigator.pop(context);
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
              title: const Text('Yearly Expense Goal'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target amount',
                  prefixText: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(),
                ),
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
                  child: const Text('Save'),
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
      onTap: () {
        // TODO: Implement export functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export feature coming soon!')),
        );
      },
    );
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
