import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/installment.dart';
import '../models/app_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // CHANGED FROM 1 TO 2 - This will trigger database upgrade
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    print('🔨 Creating database tables...');
    
    // Transactions table
    await db.execute('''\
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        account TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    print('✅ Transactions table created');

    // Savings Goals table
    await db.execute('''\
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target REAL NOT NULL,
        saved REAL NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    print('✅ Savings goals table created');

    // Installments table
    await db.execute('''\
      CREATE TABLE installments (
        id TEXT PRIMARY KEY,
        bankName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        monthlyInstallment REAL NOT NULL,
        paidInstallments INTEGER NOT NULL,
        totalInstallments INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        color TEXT NOT NULL,
        logo TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    print('✅ Installments table created');

    // Settings table
    await db.execute('''\
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        currency TEXT NOT NULL,
        darkMode INTEGER NOT NULL,
        notifications INTEGER NOT NULL,
        reminderDays TEXT NOT NULL,
        yearlyExpenseGoal REAL NOT NULL
      )
    ''');
    print('✅ Settings table created');

    // Insert default settings
    await db.insert('settings', {
      'id': 1,
      'currency': 'usd',
      'darkMode': 0,
      'notifications': 1,
      'reminderDays': '3',
      'yearlyExpenseGoal': 22500.0,
    });
    print('✅ Default settings inserted');
    print('🎉 Database setup complete!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('⚡ Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      print('🗑️  Dropping old tables...');
      
      // Drop all old tables
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS savings_goals');
      await db.execute('DROP TABLE IF EXISTS installments');
      await db.execute('DROP TABLE IF EXISTS settings');
      
      print('✅ Old tables dropped');
      
      // Recreate with correct schema
      await _createDB(db, newVersion);
    }
  }

  // ==================== TRANSACTION CRUD ====================

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<TransactionModel> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Get transactions by type
  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // ==================== SAVINGS GOAL CRUD ====================

  Future<List<SavingsGoal>> getAllSavingsGoals() async {
    final db = await database;
    final result = await db.query(
      'savings_goals',
      orderBy: 'createdAt DESC',
    );

    return result.map((json) => SavingsGoal.fromMap(json)).toList();
  }

  Future<SavingsGoal> insertSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    await db.insert('savings_goals', goal.toMap());
    return goal;
  }

  Future<int> updateSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    return db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingsGoal(String id) async {
    final db = await database;
    return await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== INSTALLMENT CRUD ====================

  Future<List<Installment>> getAllInstallments() async {
    final db = await database;
    final result = await db.query(
      'installments',
      orderBy: 'dueDate ASC',
    );

    return result.map((json) => Installment.fromMap(json)).toList();
  }

  Future<Installment> insertInstallment(Installment installment) async {
    final db = await database;
    await db.insert('installments', installment.toMap());
    return installment;
  }

  Future<int> updateInstallment(Installment installment) async {
    final db = await database;
    return db.update(
      'installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  Future<int> deleteInstallment(String id) async {
    final db = await database;
    return await db.delete(
      'installments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SETTINGS CRUD ====================

  Future<AppSettings> getSettings() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      return AppSettings.fromMap(result.first);
    }

    // Return default settings if not found
    return AppSettings(
      currency: 'usd',
      darkMode: false,
      notifications: true,
      reminderDays: '3',
      yearlyExpenseGoal: 22500,
    );
  }

  Future<int> updateSettings(AppSettings settings) async {
    final db = await database;
    return db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ==================== UTILITY METHODS ====================

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('savings_goals');
    await db.delete('installments');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}