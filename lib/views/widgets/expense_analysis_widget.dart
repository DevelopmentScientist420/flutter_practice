import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../widgets/charts/expense_pie_chart.dart';
import '../widgets/monthly_breakdown_view.dart';
import '../widgets/transactions_table.dart';
import '../widgets/savings_goals_widget.dart';
import '../widgets/spending_recommendations_widget.dart';
import '../widgets/spending_alerts_widget.dart';
import '../widgets/budget_widget.dart';

class ExpenseAnalysisWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onDataChanged;
  
  const ExpenseAnalysisWidget({
    super.key,
    this.onDataChanged,
  });

  @override
  State<ExpenseAnalysisWidget> createState() => _ExpenseAnalysisWidgetState();
}

class _ExpenseAnalysisWidgetState extends State<ExpenseAnalysisWidget> {
  List<Expense> _allExpenses = [];
  List<MonthlyExpense> _monthlyExpenses = [];
  Map<String, double> _typeData = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = 'Loading...';
  Completer<void>? _loadingCompleter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Expense Analysis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyze your spending patterns and track your financial health',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Load CSV Button
              ElevatedButton.icon(
                onPressed: _loadCsvFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Load CSV File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Content Section
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        height: 300,
        child: Center(
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
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 300,
        child: Center(
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
        ),
      );
    }

    if (_allExpenses.isEmpty) {
      return Container(
        height: 300,
        child: Center(
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
                'Click the button above to load a CSV file',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // Static dashboard - no carousel
    return Column(
      children: [
        // Spending alerts widget (at the top)
        if (_allExpenses.isNotEmpty && _monthlyExpenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SpendingAlertsWidget(
              expenses: _allExpenses,
              monthlyExpenses: _monthlyExpenses,
            ),
          ),
        
        // Summary card
        _buildSummaryCard(),
        
        // Budget widget
        if (_allExpenses.isNotEmpty)
          BudgetWidget(
            totalExpenses: _allExpenses
                .where((expense) => expense.amount < 0)
                .fold(0.0, (sum, expense) => sum + expense.amount.abs()),
          ),
        
        // Analytics section (charts)
        if (_typeData.isNotEmpty || _monthlyExpenses.isNotEmpty)
          _buildAnalyticsSection(),
        
        // Savings goals widget
        if (_monthlyExpenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SavingsGoalsWidget(monthlyExpenses: _monthlyExpenses),
          ),
        
        // Spending recommendations widget (with carousel)
        if (_allExpenses.isNotEmpty && _monthlyExpenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SpendingRecommendationsWidget(
              expenses: _allExpenses,
              monthlyExpenses: _monthlyExpenses,
            ),
          ),
        
        // Transactions table
        if (_allExpenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TransactionsTable(expenses: _allExpenses),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    // Calculate total expenses (only debits - negative amounts, displayed as positive)
    double totalExpenses = _allExpenses
        .where((expense) => expense.amount < 0)
        .fold(0.0, (sum, expense) => sum + expense.amount.abs());
    
    // Calculate total income (only credits - positive amounts)
    double totalIncome = _allExpenses
        .where((expense) => expense.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate net amount (income - expenses)
    double netAmount = totalIncome - totalExpenses;

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
                  '€${totalExpenses.toStringAsFixed(2)}',
                  Icons.trending_down,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Total Income',
                  '€${totalIncome.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Net Amount',
                  '€${netAmount.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  netAmount >= 0 ? Colors.green : Colors.red,
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

    // Notify parent about the data change
    _notifyDataChanged();
  }

  Map<String, dynamic> get financialSummary {
    if (_allExpenses.isEmpty) return {};
    
    // Calculate total expenses (only debits - negative amounts, displayed as positive)
    double totalExpenses = _allExpenses
        .where((expense) => expense.amount < 0)
        .fold(0.0, (sum, expense) => sum + expense.amount.abs());
    
    // Calculate total income (only credits - positive amounts)
    double totalIncome = _allExpenses
        .where((expense) => expense.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    
    // Calculate net amount (income - expenses)
    double netAmount = totalIncome - totalExpenses;
    
    // Get recent transactions (last 5)
    List<String> recentTransactions = _allExpenses
        .take(5)
        .map((e) => "${e.description} (€${e.amount.abs().toStringAsFixed(2)})")
        .toList();
    
    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'netAmount': netAmount,
      'categoryBreakdown': Map<String, double>.from(_typeData),
      'recentTransactions': recentTransactions,
    };
  }

  void _notifyDataChanged() {
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(financialSummary);
    }
  }
}