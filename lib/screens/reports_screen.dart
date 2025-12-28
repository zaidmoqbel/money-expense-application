import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../services/export_service.dart';
import '../theme/app_colors.dart';
import 'account_transactions_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 6; // months
  int? _touchedIndex;
  int _selectedMonth = 0; // 0 means all months
  int _selectedYear = 0; // 0 means all years
  final List<String> _selectedCategories = [];
  bool _showFilters = false;
  bool _showPieExpenses = true;
  bool _showExpenseChart = true; // true for expense, false for income

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Reports'),
            Text(
              'Analyze your spending patterns',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportToCSV(context),
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final filteredTransactions = _getFilteredTransactions(provider);

          // Calculate monthly data
          final monthlyData = _calculateMonthlyData(filteredTransactions, _selectedPeriod);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters
                if (_showFilters) _buildFiltersPanel(provider),
                const SizedBox(height: 24),

                // Period selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),

                // Income vs Expense Chart
                _buildIncomeExpenseChart(monthlyData),
                const SizedBox(height: 24),

                // Period Summary Boxes
                _buildPeriodSummaryBoxes(monthlyData),
                const SizedBox(height: 24),

                // Category Breakdown
                _buildCategoryBreakdown(provider, filteredTransactions),
                const SizedBox(height: 24),

                // Summary Stats
                _buildSummaryStats(monthlyData),
                const SizedBox(height: 24),

                // Accounts Overview
                _buildAccountsOverview(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0F766E)],
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
          const Text(
            'Comparison Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x00007267),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodButton('Last 3\nMonths', 3),
                const SizedBox(width: 12),
                _buildPeriodButton('Last 6\nMonths', 6),
                const SizedBox(width: 12),
                _buildPeriodButton('Last 12\nMonths', 12),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int months) {
    final isSelected = _selectedPeriod == months;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = months;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart(Map<String, Map<String, double>> monthlyData) {
    // Calculate responsive chart height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final chartHeight = (screenHeight * 0.3).clamp(150.0, 300.0); // 30% of screen height, min 150, max 300

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Showing last $_selectedPeriod Months',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(202, 31, 41, 55),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: _buildBarChart(monthlyData, chartHeight),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', AppColors.success),
              const SizedBox(width: 20),
              _buildLegendItem('Expense', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, Map<String, double>> monthlyData, double chartHeight) {
    final entries = monthlyData.entries.toList();
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    // Calculate trend indicators
    final trendIndicators = _calculateTrendIndicators(monthlyData);

    final maxHeight = _getMaxValue(monthlyData) * 1.2;
    final scaleFactor = chartHeight / maxHeight;
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Stack(
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxHeight,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < entries.length) {
                      final monthKey = entries[value.toInt()].key;
                      final trend = trendIndicators[monthKey];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              monthKey,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (trend != null && trend.isNotEmpty)
                              Text(
                                trend,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: trend.contains('+') ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data['income'] ?? 0,
                    color: AppColors.success,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: data['expense'] ?? 0,
                    color: AppColors.warning,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        // Add data labels on top of bars
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: entries.asMap().entries.map((entry) {
              final data = entry.value.value;
              final incomeValue = data['income'] ?? 0;
              final expenseValue = data['expense'] ?? 0;
              final incomeHeight = incomeValue * scaleFactor;
              final expenseHeight = expenseValue * scaleFactor;

              return SizedBox(
                width: 24, // Match bar width + some padding
                height: chartHeight,
                child: Stack(
                  children: [
                    if (incomeValue > 0)
                      Positioned(
                        top: chartHeight - incomeHeight - 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currencyFormat.format(incomeValue),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (expenseValue > 0)
                      Positioned(
                        top: chartHeight - expenseHeight - 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currencyFormat.format(expenseValue),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromARGB(255, 119, 123, 129),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSummaryBoxes(Map<String, Map<String, double>> monthlyData) {
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    double totalIncome = 0;
    double totalExpense = 0;

    for (var data in monthlyData.values) {
      totalIncome += data['income'] ?? 0;
      totalExpense += data['expense'] ?? 0;
    }

    final saved = totalIncome - totalExpense;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryBox('Income', currencyFormat.format(totalIncome), const Color(0xFF00a63e)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryBox('Expenses', currencyFormat.format(totalExpense), const Color(0xFFf54a00)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryBox('Saved', currencyFormat.format(saved), const Color(0xFF0F766E)),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFcbfbf1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFcbfbf1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(AppProvider provider, List filteredTransactions) {
    final categoryData = _showExpenseChart ? _calculateCategoryExpenses(filteredTransactions) : _calculateCategoryIncome(filteredTransactions);

    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);

    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    final pieSections = categoryData.entries.map((entry) {
      final percentage = entry.value / total;
      final color = AppColors.getCategoryColor(entry.key);
      return PieChartSectionData(
        value: percentage,
        color: color,
        radius: 60,
        showTitle: false,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_showExpenseChart ? 'Expense' : 'Income'} Categories',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_showExpenseChart ? Icons.money_off : Icons.attach_money),
                    onPressed: () {
                      setState(() {
                        _showExpenseChart = !_showExpenseChart;
                      });
                    },
                    tooltip: _showExpenseChart ? 'Show Income' : 'Show Expenses',
                  ),
                  IconButton(
                    icon: Icon(_showPieExpenses ? Icons.pie_chart : Icons.list),
                    onPressed: () {
                      setState(() {
                        _showPieExpenses = !_showPieExpenses;
                      });
                    },
                    tooltip: _showPieExpenses ? 'Show List' : 'Show Pie Chart',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showPieExpenses)
            Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: pieSections,
                          centerSpaceRadius: 25,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                        ),
                      ),
                      if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < categoryData.length)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(categoryData.entries.elementAt(_touchedIndex!).value / total * 100).toInt()}%',
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryData.entries.map((entry) {
                      final color = AppColors.getCategoryColor(entry.key);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              currencyFormat.format(entry.value),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryData.entries.map((entry) {
                final color = AppColors.getCategoryColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        currencyFormat.format(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(Map<String, Map<String, double>> monthlyData) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var data in monthlyData.values) {
      totalIncome += data['income'] ?? 0;
      totalExpense += data['expense'] ?? 0;
    }

    final avgIncome = monthlyData.isNotEmpty ? totalIncome / monthlyData.length : 0;
    final avgExpense = monthlyData.isNotEmpty ? totalExpense / monthlyData.length : 0;
    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Income', currencyFormat.format(totalIncome), AppColors.success),
          const SizedBox(height: 12),
          _buildStatRow('Total Expense', currencyFormat.format(totalExpense), AppColors.warning),
          const SizedBox(height: 12),
          _buildStatRow('Avg. Monthly Income', currencyFormat.format(avgIncome), AppColors.textSecondary),
          const SizedBox(height: 12),
          _buildStatRow('Avg. Monthly Expense', currencyFormat.format(avgExpense), AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Map<String, Map<String, double>> _calculateMonthlyData(List transactions, int months) {
    final Map<String, Map<String, double>> monthlyData = {};
    final dateFormat = DateFormat('MMM');
    
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      final monthKey = dateFormat.format(date);
      monthlyData[monthKey] = {'income': 0, 'expense': 0};
    }

    for (var transaction in transactions) {
      final date = DateTime.parse(transaction.date);
      final monthKey = dateFormat.format(date);
      
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey]![transaction.type] = 
            (monthlyData[monthKey]![transaction.type] ?? 0) + transaction.amount;
      }
    }

    return monthlyData;
  }

  double _getMaxValue(Map<String, Map<String, double>> monthlyData) {
    double max = 0;
    for (var data in monthlyData.values) {
      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max > 0 ? max : 100;
  }

  List _getFilteredTransactions(AppProvider provider) {
    List allTransactions = provider.transactions;

    // Filter by month and year
    if (_selectedMonth != 0 && _selectedYear != 0) {
      allTransactions = allTransactions.where((transaction) {
        final date = DateTime.parse(transaction.date);
        return date.month == _selectedMonth && date.year == _selectedYear;
      }).toList();
    }

    // Filter by categories
    if (_selectedCategories.isNotEmpty) {
      allTransactions = allTransactions.where((transaction) {
        return _selectedCategories.contains(transaction.category);
      }).toList();
    }

    return allTransactions;
  }

  Widget _buildFiltersPanel(AppProvider provider) {
    final allCategories = provider.transactions
        .map((t) => t.category)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('All Months')),
                    ...List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat('MMMM').format(DateTime(2023, month))),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('All Years')),
                    ...List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                backgroundColor: AppColors.cardBackground,
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = 0;
                      _selectedYear = 0;
                      _selectedCategories.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Clear Filters'),
                ),
              ),
            ],
          ),
        ],
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

  Map<String, String> _calculateTrendIndicators(Map<String, Map<String, double>> monthlyData) {
    final Map<String, String> trends = {};
    final entries = monthlyData.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final currentData = entries[i].value;
      final currentNet = (currentData['income'] ?? 0) - (currentData['expense'] ?? 0);

      if (i > 0) {
        final previousData = entries[i - 1].value;
        final previousNet = (previousData['income'] ?? 0) - (previousData['expense'] ?? 0);

        if (previousNet != 0) {
          final change = ((currentNet - previousNet) / previousNet.abs()) * 100;
          final sign = change >= 0 ? '+' : '';
          trends[entries[i].key] = '$sign${change.toStringAsFixed(0)}%';
        } else {
          trends[entries[i].key] = currentNet >= 0 ? '+∞%' : '-∞%';
        }
      } else {
        trends[entries[i].key] = ''; // No trend for first month
      }
    }

    return trends;
  }

  Widget _buildAccountsOverview(AppProvider provider) {
    final accountData = _calculateAccountData(provider.transactions);

    if (accountData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.currency(symbol: Provider.of<AppProvider>(context, listen: false).getCurrencySymbol(), decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accounts Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...accountData.entries.map((entry) {
            final accountType = entry.key;
            final data = entry.value;
            final balance = data.income - data.expense;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _showAccountOptionsDialog(context, accountType),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getAccountIcon(accountType),
                            color: AppColors.primary,
                            size: 20,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: balance >= 0 ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

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

  Future<void> _exportToCSV(BuildContext context) async {
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
