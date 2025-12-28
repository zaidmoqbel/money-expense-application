import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/installment.dart';
import '../models/app_settings.dart';
import '../helpers/database_helper.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // State
  List<TransactionModel> _transactions = [];
  List<SavingsGoal> _savingsGoals = [];
  List<Installment> _installments = [];
  AppSettings _settings = AppSettings(
    currency: 'usd',
    darkMode: false,
    notifications: true,
    reminderDays: '3',
    yearlyExpenseGoal: 22500,
  );

  bool _isLoading = false;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<Installment> get installments => _installments;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  // ==================== INITIALIZATION ====================

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getAllTransactions();
      _savingsGoals = await _dbHelper.getAllSavingsGoals();
      _installments = await _dbHelper.getAllInstallments();
      _settings = await _dbHelper.getSettings();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== TRANSACTION METHODS ====================

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      print('➕ Adding transaction: ${transaction.type} - ${getCurrencySymbol()}${transaction.amount}');
      await _dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      print('✅ Transaction added to list. Total: ${_transactions.length}');
      notifyListeners();
      print('🔔 Listeners notified');
    } catch (e) {
      debugPrint('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _dbHelper.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dbHelper.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Transfer money between accounts
  Future<void> transferBetweenAccounts(
    String fromAccount,
    String toAccount,
    double amount,
    String notes,
  ) async {
    if (fromAccount == toAccount) {
      throw Exception('Cannot transfer to the same account');
    }

    if (amount <= 0) {
      throw Exception('Transfer amount must be positive');
    }

    // Calculate balance for fromAccount
    double fromAccountBalance = 0.0;
    for (var transaction in _transactions) {
      if (transaction.account == fromAccount && transaction.category != 'Transfer') {
        if (transaction.type == 'income') {
          fromAccountBalance += transaction.amount;
        } else {
          fromAccountBalance -= transaction.amount;
        }
      }
    }

    if (fromAccountBalance < amount) {
      throw Exception('Insufficient funds in $fromAccount account');
    }

    try {
      // Create expense transaction from source account
      final expenseTransaction = TransactionModel(
        id: TransactionModel.generateId(),
        type: 'expense',
        amount: amount,
        category: 'Transfer',
        account: fromAccount,
        date: DateTime.now().toIso8601String().split('T')[0],
        notes: notes.isNotEmpty ? 'Transfer to $toAccount: $notes' : 'Transfer to $toAccount',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Create income transaction to destination account
      final incomeTransaction = TransactionModel(
        id: TransactionModel.generateId(),
        type: 'income',
        amount: amount,
        category: 'Transfer',
        account: toAccount,
        date: DateTime.now().toIso8601String().split('T')[0],
        notes: notes.isNotEmpty ? 'Transfer from $fromAccount: $notes' : 'Transfer from $fromAccount',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Use database transaction to ensure both transactions are added atomically
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.insert('transactions', expenseTransaction.toMap());
        await txn.insert('transactions', incomeTransaction.toMap());
      });

      // Add to local list and notify listeners
      _transactions.insert(0, expenseTransaction);
      _transactions.insert(0, incomeTransaction);
      notifyListeners();

    } catch (e) {
      debugPrint('Error transferring between accounts: $e');
      rethrow;
    }
  }

  // Get filtered transactions
  List<TransactionModel> getFilteredTransactions(String filter) {
    if (filter == 'all') {
      return _transactions;
    }
    return _transactions.where((t) => t.type == filter).toList();
  }

  // Calculate total balance
  double calculateBalance() {
    double income = 0;
    double expense = 0;

    for (var transaction in _transactions) {
      // Exclude transfers from balance calculation as they are internal movements
      if (transaction.category == 'Transfer') continue;

      if (transaction.type == 'income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    return income - expense;
  }

  // Calculate total income
  double calculateTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income' && t.category != 'Transfer')
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Calculate total expense
  double calculateTotalExpense() {
    return _transactions
        .where((t) => t.type == 'expense' && t.category != 'Transfer')
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get transactions by date range
  List<TransactionModel> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _transactions.where((t) {
      final date = DateTime.parse(t.date);
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get category-wise expenses
  Map<String, double> getCategoryExpenses() {
    final Map<String, double> categoryTotals = {};

    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  // ==================== SAVINGS GOAL METHODS ====================

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    try {
      await _dbHelper.insertSavingsGoal(goal);
      _savingsGoals.add(goal);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
      rethrow;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      await _dbHelper.updateSavingsGoal(goal);
      final index = _savingsGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _savingsGoals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      rethrow;
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    try {
      await _dbHelper.deleteSavingsGoal(id);
      _savingsGoals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      rethrow;
    }
  }

  // Add funds to savings goal
  Future<void> addFundsToGoal(String id, double amount) async {
    final goal = _savingsGoals.firstWhere((g) => g.id == id);
    final updatedGoal = SavingsGoal(
      id: goal.id,
      name: goal.name,
      target: goal.target,
      saved: goal.saved + amount,
      color: goal.color,
      icon: goal.icon,
      createdAt: goal.createdAt,
    );
    await updateSavingsGoal(updatedGoal);
  }

  // Withdraw funds from savings goal
  Future<void> withdrawFundsFromGoal(String id, double amount) async {
    final goal = _savingsGoals.firstWhere((g) => g.id == id);
    final updatedGoal = SavingsGoal(
      id: goal.id,
      name: goal.name,
      target: goal.target,
      saved: (goal.saved - amount).clamp(0, goal.target),
      color: goal.color,
      icon: goal.icon,
      createdAt: goal.createdAt,
    );
    await updateSavingsGoal(updatedGoal);
  }

  // ==================== INSTALLMENT METHODS ====================

  Future<void> addInstallment(Installment installment) async {
    try {
      await _dbHelper.insertInstallment(installment);
      _installments.add(installment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding installment: $e');
      rethrow;
    }
  }

  Future<void> updateInstallment(Installment installment) async {
    try {
      await _dbHelper.updateInstallment(installment);
      final index = _installments.indexWhere((i) => i.id == installment.id);
      if (index != -1) {
        _installments[index] = installment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating installment: $e');
      rethrow;
    }
  }

  Future<void> deleteInstallment(String id) async {
    try {
      await _dbHelper.deleteInstallment(id);
      _installments.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting installment: $e');
      rethrow;
    }
  }

  // Mark installment as paid
  Future<void> markInstallmentAsPaid(String id) async {
    final installment = _installments.firstWhere((i) => i.id == id);
    final newPaidInstallments = installment.paidInstallments + 1;
    
    final updatedInstallment = Installment(
      id: installment.id,
      bankName: installment.bankName,
      totalAmount: installment.totalAmount,
      monthlyInstallment: installment.monthlyInstallment,
      paidInstallments: newPaidInstallments,
      totalInstallments: installment.totalInstallments,
      dueDate: installment.dueDate,
      status: newPaidInstallments >= installment.totalInstallments ? 'paid' : 'upcoming',
      color: installment.color,
      logo: installment.logo,
      createdAt: installment.createdAt,
    );

    await updateInstallment(updatedInstallment);
  }

  // Get total remaining installment amount
  double getTotalRemainingInstallments() {
    return _installments
        .where((i) => i.status == 'upcoming')
        .fold(0, (sum, i) => sum + i.remainingAmount);
  }

  // ==================== SETTINGS METHODS ====================

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _dbHelper.updateSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings: $e');
      rethrow;
    }
  }

  // Get total saved amount in savings goals
  double getTotalSavedInGoals() {
    return _savingsGoals.fold(0, (sum, goal) => sum + goal.saved);
  }

  // ==================== UTILITY METHODS ====================

  // Get currency symbol based on settings
  String getCurrencySymbol() {
    switch (_settings.currency) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'jpy':
        return '¥';
      case 'try':
        return '₺';
      case 'jod':
        return 'د.أ';
      default:
        return '\$';
    }
  }

  // Exchange rates relative to USD (approximate rates)
  static const Map<String, double> _exchangeRates = {
    'usd': 1.0,
    'eur': 0.85,
    'gbp': 0.73,
    'jpy': 110.0,
    'try': 42.0,
    'jod': 0.71,
  };

  // Convert amount from one currency to another
  double convertAmount(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    // Convert to USD first, then to target currency
    final usdAmount = amount / _exchangeRates[fromCurrency]!;
    return usdAmount * _exchangeRates[toCurrency]!;
  }

  // Convert all data to new currency when currency setting changes
  Future<void> convertAllDataToNewCurrency(String newCurrency) async {
    final oldCurrency = _settings.currency;
    if (oldCurrency == newCurrency) return;

    try {
      // Convert transactions
      for (var transaction in _transactions) {
        final convertedAmount = convertAmount(transaction.amount, oldCurrency, newCurrency);
        final updatedTransaction = transaction.copyWith(amount: convertedAmount);
        await updateTransaction(updatedTransaction);
      }

      // Convert savings goals
      for (var goal in _savingsGoals) {
        final convertedTarget = convertAmount(goal.target, oldCurrency, newCurrency);
        final convertedSaved = convertAmount(goal.saved, oldCurrency, newCurrency);
        final updatedGoal = SavingsGoal(
          id: goal.id,
          name: goal.name,
          target: convertedTarget,
          saved: convertedSaved,
          color: goal.color,
          icon: goal.icon,
          createdAt: goal.createdAt,
        );
        await updateSavingsGoal(updatedGoal);
      }

      // Convert installments
      for (var installment in _installments) {
        final convertedTotal = convertAmount(installment.totalAmount, oldCurrency, newCurrency);
        final convertedMonthly = convertAmount(installment.monthlyInstallment, oldCurrency, newCurrency);
        final updatedInstallment = Installment(
          id: installment.id,
          bankName: installment.bankName,
          totalAmount: convertedTotal,
          monthlyInstallment: convertedMonthly,
          paidInstallments: installment.paidInstallments,
          totalInstallments: installment.totalInstallments,
          dueDate: installment.dueDate,
          status: installment.status,
          color: installment.color,
          logo: installment.logo,
          createdAt: installment.createdAt,
        );
        await updateInstallment(updatedInstallment);
      }

      // Convert yearly expense goal
      final convertedGoal = convertAmount(_settings.yearlyExpenseGoal, oldCurrency, newCurrency);
      await updateSettings(AppSettings(
        currency: newCurrency,
        darkMode: _settings.darkMode,
        notifications: _settings.notifications,
        reminderDays: _settings.reminderDays,
        yearlyExpenseGoal: convertedGoal,
      ));

    } catch (e) {
      debugPrint('Error converting data to new currency: $e');
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      await _dbHelper.deleteAllData();
      _transactions.clear();
      _savingsGoals.clear();
      _installments.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all data: $e');
      rethrow;
    }
  }

  // ==================== CATEGORY METHODS ====================

  Future<List<String>> getCategoriesByType(String type) async {
    try {
      return await _dbHelper.getCategoriesByType(type);
    } catch (e) {
      debugPrint('Error getting categories: $e');
      // Return default categories if database fails
      if (type == 'expense') {
        return ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Healthcare'];
      } else {
        return ['Salary', 'Freelance', 'Investment', 'Gift'];
      }
    }
  }

  Future<void> addCategory(String name, String type) async {
    try {
      await _dbHelper.insertCategory(name, type);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> removeCategory(String name, String type) async {
    try {
      // Check if category is in use
      final isInUse = await _dbHelper.isCategoryInUse(name, type);
      if (isInUse) {
        throw Exception('Cannot delete category that is currently in use');
      }

      await _dbHelper.deleteCategory(name, type);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing category: $e');
      rethrow;
    }
  }
}
