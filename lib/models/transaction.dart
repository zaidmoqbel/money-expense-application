/// Transaction Model
///
/// This class represents a financial transaction (income or expense).
/// It includes methods to convert to/from database format.
import 'dart:math';

class TransactionModel {
  // Properties
  final String id;              // Unique identifier
  final String type;            // 'income' or 'expense'
  final double amount;          // Transaction amount
  final String category;        // Category (Food, Transport, etc.)
  final String account;         // Payment method (Cash, Card, etc.)
  final String date;            // Date in YYYY-MM-DD format
  final String? notes;          // Optional notes
  final String createdAt;       // Timestamp when created

  // Constructor
  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.account,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  /// Convert model to Map for database storage
  /// 
  /// SQLite stores data as key-value maps, so we need to convert
  /// our object into a Map<String, dynamic> format.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'account': account,
      'date': date,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  /// Create model from Map (from database)
  /// 
  /// This factory constructor takes a Map from the database
  /// and creates a TransactionModel object from it.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      account: map['account'] as String,
      date: map['date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  /// Generate unique ID for new transaction
  ///
  /// Creates a unique ID using timestamp and random number.
  /// Format: txn-1234567890-1234
  static String generateId() {
    return 'txn-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }

  /// Create a copy of this transaction with modified fields
  /// 
  /// Useful for updating specific fields without modifying
  /// the original object (immutability pattern).
  TransactionModel copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? account,
    String? date,
    String? notes,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      account: account ?? this.account,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// String representation for debugging
  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, category: $category)';
  }
}
