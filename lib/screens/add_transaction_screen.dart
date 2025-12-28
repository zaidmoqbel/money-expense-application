import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  final TransactionModel? transactionToEdit;
  const AddTransactionScreen({super.key, this.initialType, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _transactionType = 'expense';
  final _amountController = TextEditingController();
  String? _selectedCategory;
  final _customCategoryController = TextEditingController();
  String? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();

  List<String> _categories = [];
  bool _isLoadingCategories = true;

  final List<String> _accounts = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Mobile Wallet',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      // Editing existing transaction
      final transaction = widget.transactionToEdit!;
      _transactionType = transaction.type;
      _amountController.text = transaction.amount.toString();
      _selectedCategory = transaction.category;
      _selectedAccount = transaction.account;
      _selectedDate = DateTime.parse(transaction.date);
      _notesController.text = transaction.notes ?? '';
    } else if (widget.initialType != null) {
      _transactionType = widget.initialType!;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final categories = await provider.getCategoriesByType(_transactionType);
      // Ensure "Others" is always available
      if (!categories.contains('Others')) {
        categories.add('Others');
      }
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      // Fallback to default categories if database fails
      setState(() {
        _categories = _transactionType == 'expense'
            ? ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Healthcare', 'Others']
            : ['Salary', 'Freelance', 'Investment', 'Gift', 'Others'];
        _isLoadingCategories = false;
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate category
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // Validate custom category
    if (_selectedCategory == 'Others' &&
        _customCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom category name')),
      );
      return;
    }

    // Validate account
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (widget.transactionToEdit != null) {
      // Editing existing transaction
      final updatedTransaction = TransactionModel(
        id: widget.transactionToEdit!.id,
        type: _transactionType,
        amount: double.parse(_amountController.text),
        category: _selectedCategory == 'Others'
            ? _customCategoryController.text
            : _selectedCategory!,
        account: _selectedAccount!,
        date: _selectedDate.toString().split(' ')[0],
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.transactionToEdit!.createdAt,
      );

      provider.updateTransaction(updatedTransaction);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Adding new transaction
      final transaction = TransactionModel(
        id: TransactionModel.generateId(),
        type: _transactionType,
        amount: double.parse(_amountController.text),
        category: _selectedCategory == 'Others'
            ? _customCategoryController.text
            : _selectedCategory!,
        account: _selectedAccount!,
        date: _selectedDate.toString().split(' ')[0],
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now().toIso8601String(),
      );

      provider.addTransaction(transaction);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_transactionType == "income" ? "Income" : "Expense"} added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Income/Expense Toggle
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeButton(
                                    'Expense',
                                    'expense',
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTypeButton(
                                    'Income',
                                    'income',
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Amount
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Category Dropdown
                            _isLoadingCategories
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.grey[50],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Loading categories...'),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: 'Category',
                                      prefixIcon: const Icon(Icons.category),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: _categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    },
                                  ),
                            const SizedBox(height: 16),

                            // Custom Category (if Others selected)
                            if (_selectedCategory == 'Others')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: _customCategoryController,
                                  decoration: InputDecoration(
                                    labelText: 'Custom Category Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ),

                            // Account Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedAccount,
                              decoration: InputDecoration(
                                labelText: 'Account',
                                prefixIcon: const Icon(Icons.account_balance_wallet),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _accounts.map((account) {
                                return DropdownMenuItem(
                                  value: account,
                                  child: Text(account),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccount = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Date Picker
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Notes (Optional)',
                                prefixIcon: const Icon(Icons.notes),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save Button
                            ElevatedButton(
                              onPressed: _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Save Transaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, Color color) {
    final isSelected = _transactionType == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _transactionType = value;
          _selectedCategory = null; // Reset category when switching type
        });
        _loadCategories(); // Reload categories for new type
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
