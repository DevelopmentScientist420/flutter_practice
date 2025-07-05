import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'widgets/charts/expense_pie_chart.dart';
import 'widgets/monthly_breakdown_view.dart';

class ExpenseAnalysisView extends StatefulWidget {
  const ExpenseAnalysisView({super.key});

  @override
  State<ExpenseAnalysisView> createState() => _ExpenseAnalysisViewState();
}

class _ExpenseAnalysisViewState extends State<ExpenseAnalysisView> {
  List<Expense> _allExpenses = [];
  List<MonthlyExpense> _monthlyExpenses = [];
  Map<String, double> _typeData = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = 'Loading...';
  Completer<void>? _loadingCompleter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        backgroundColor: Colors.cyan[50],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadCsvFile,
        icon: const Icon(Icons.upload_file),
        label: const Text('Load CSV'),
        backgroundColor: Colors.cyan,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _loadingMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your file...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cancelLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[700],
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    if (_allExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No expenses loaded',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click the button below to load a CSV file',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCard(),
          if (_typeData.isNotEmpty || _monthlyExpenses.isNotEmpty)
            _buildAnalyticsSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalExpenses = _allExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate average monthly from all expenses (simple division by number of months with data)
    double averageMonthly = 0.0;
    if (_allExpenses.isNotEmpty) {
      // Get date range
      final dates = _allExpenses.map((e) => e.date).toList();
      dates.sort();
      final earliestDate = dates.first;
      final latestDate = dates.last;
      
      // Calculate number of months
      int monthsDiff = (latestDate.year - earliestDate.year) * 12 + 
                      (latestDate.month - earliestDate.month) + 1;
      
      averageMonthly = monthsDiff > 0 ? totalExpenses / monthsDiff : totalExpenses;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Expenses',
                  '\$${totalExpenses.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Average Monthly',
                  '\$${averageMonthly.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Total Records',
                  '${_allExpenses.length}',
                  Icons.receipt,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _loadCsvFile() async {
    _loadingCompleter = Completer<void>();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = 'Selecting file...';
    });

    try {
      // Add timeout to prevent indefinite loading
      await Future.any([
        _performCsvLoad(),
        Future.delayed(const Duration(seconds: 30), () {
          throw Exception('File loading timed out after 30 seconds. Please try a smaller file.');
        }),
        _loadingCompleter!.future, // Allow cancellation
      ]);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        // User cancelled - don't show error
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _cancelLoading() {
    if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
      _loadingCompleter!.completeError('Loading cancelled by user');
    }
  }

  Future<void> _performCsvLoad() async {
    // Update loading message for different stages
    setState(() {
      _loadingMessage = 'Reading CSV file...';
    });
    
    // For web, use the combined pick and parse method
    List<Expense> expenses = await ExpenseService.pickAndParseCsvFile();
    
    setState(() {
      _loadingMessage = 'Analyzing data (${expenses.length} records)...';
    });
    
    // Add small delays to prevent UI blocking and show progress
    await Future.delayed(const Duration(milliseconds: 100));
    
    Map<String, double> typeData = ExpenseService.getCategoryBreakdown(expenses);
    List<MonthlyExpense> monthlyExpenses = ExpenseService.getLastThreeMonthsExpenses(expenses);
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    setState(() {
      _allExpenses = expenses;
      _typeData = typeData;
      _monthlyExpenses = monthlyExpenses;
      _isLoading = false;
    });
  }

  Widget _buildAnalyticsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On wider screens (desktop/tablet landscape), show side by side
        // On narrower screens (mobile/tablet portrait), stack vertically
        bool isWideScreen = constraints.maxWidth > 600;
        
        if (isWideScreen) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pie Chart Section
                if (_typeData.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: ExpensePieChart(categoryData: _typeData),
                  ),
                
                // Add spacing only if both charts exist
                if (_typeData.isNotEmpty && _monthlyExpenses.isNotEmpty)
                  const SizedBox(width: 16),
                
                // Monthly Breakdown Section
                if (_monthlyExpenses.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: MonthlyBreakdownView(monthlyExpenses: _monthlyExpenses),
                  ),
              ],
            ),
          );
        } else {
          // Mobile layout - stack vertically with proper spacing
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_typeData.isNotEmpty)
                  ExpensePieChart(categoryData: _typeData),
                if (_typeData.isNotEmpty && _monthlyExpenses.isNotEmpty)
                  const SizedBox(height: 16),
                if (_monthlyExpenses.isNotEmpty)
                  MonthlyBreakdownView(monthlyExpenses: _monthlyExpenses),
              ],
            ),
          );
        }
      },
    );
  }
}
