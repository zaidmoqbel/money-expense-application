import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/savings_goals_screen.dart';
import 'screens/installments_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'widgets/bottom_nav.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider()..loadAllData(),
      child: MaterialApp(
        title: 'Smart Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.success,
            error: AppColors.error,
            surface: AppColors.cardBackground,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.cardBackground,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showAddButtons = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SavingsGoalsScreen(),
    const InstallmentsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _showAddButtons = false; // Hide buttons when switching tabs
    });
  }

  void _toggleAddButtons() {
    setState(() {
      _showAddButtons = !_showAddButtons;
    });
  }

  void _showAddTransactionModal(String type) {
    setState(() {
      _showAddButtons = false; // Hide buttons after selection
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(initialType: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: _currentIndex == 0 ? _buildAddButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_showAddButtons) ...[
            // Income button
            Positioned(
              bottom: 140,
              right: 0,
              child: GestureDetector(
                onTap: () => _showAddTransactionModal('income'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: const Icon(
                    Icons.call_received,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Expense button
            Positioned(
              bottom: 80,
              right: 0,
              child: GestureDetector(
                onTap: () => _showAddTransactionModal('expense'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: const Icon(
                    Icons.call_made,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
          Container(
            height: 50,
            width: 50,
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              onPressed: _toggleAddButtons,
              backgroundColor: AppColors.primary,
              elevation: 3,
              child: Icon(
                _showAddButtons ? Icons.close : Icons.add,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
