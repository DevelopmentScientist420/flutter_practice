import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/budget_service.dart';
import 'widgets/charts/expense_pie_chart.dart';
import 'widgets/monthly_breakdown_view.dart';
import 'widgets/transactions_table.dart';
import 'widgets/budget_widget.dart';

/// Main view for expense analysis and financial data visualization.
/// 
/// This widget provides comprehensive financial analysis functionality including:
/// - CSV file loading and parsing
/// - Expense categorization and breakdown
/// - Monthly spending trends
/// - Budget tracking and progress
/// - Transaction history display
/// - Visual charts and analytics
/// 
/// The view handles different states: loading, error, empty data, and full analytics display.
class ExpenseAnalysisView extends StatefulWidget {
  const ExpenseAnalysisView({super.key});

  @override
  State<ExpenseAnalysisView> createState() => _ExpenseAnalysisViewState();
}

class _ExpenseAnalysisViewState extends State<ExpenseAnalysisView> {
  // === DATA STORAGE ===
  /// All loaded expenses from the CSV file
  List<Expense> _allExpenses = [];
  
  /// Monthly expense summaries for the last three months
  List<MonthlyExpense> _monthlyExpenses = [];
  
  /// Expense breakdown by category/type
  Map<String, double> _typeData = {};

  // === UI STATE MANAGEMENT ===
  /// Whether the app is currently loading data
  bool _isLoading = false;
  
  /// Current error message to display (null if no error)
  String? _errorMessage;
  
  /// Message to show during loading process
  String _loadingMessage = 'Loading...';
  
  /// Completer to handle loading cancellation
  Completer<void>? _loadingCompleter;

  // === MAIN BUILD METHOD ===
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

  // === BODY CONTENT BUILDER ===
  /// Builds the main body content based on current application state
  Widget _buildBody() {
    // Show loading screen during data processing
    if (_isLoading) {
      return _buildLoadingView();
    }

    // Show error message if something went wrong
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    // Show empty state when no data is loaded
    if (_allExpenses.isEmpty) {
      return _buildEmptyView();
    }

    // Show main analytics content when data is available
    return _buildAnalyticsView();
  }

  // === VIEW STATE BUILDERS ===
  /// Builds the loading view with progress indicator and cancel option
  Widget _buildLoadingView() {
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

  /// Builds the error view with error message and dismiss button
  Widget _buildErrorView() {
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

  /// Builds the empty state view when no data is loaded
  Widget _buildEmptyView() {
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
            'Click the button below to load the CSV data file given by your bank.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Builds the main analytics view with all data visualizations
  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Financial summary with totals and budget progress
          _buildSummaryCard(),
          
          // Charts and analytics (pie chart and monthly breakdown)
          if (_typeData.isNotEmpty || _monthlyExpenses.isNotEmpty)
            _buildAnalyticsSection(),
          
          // Detailed transactions table
          if (_allExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TransactionsTable(expenses: _allExpenses),
            ),
          
          // Budget management widget
          if (_allExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: BudgetWidget(
                totalExpenses: _calculateTotalExpenses(),
                onBudgetChanged: _onBudgetChanged,
              ),
            ),
        ],
      ),
    );
  }

  // === HELPER METHODS ===
  /// Calculates total expenses (only negative amounts, displayed as positive)
  double _calculateTotalExpenses() {
    return _allExpenses
        .where((expense) => expense.amount < 0)
        .fold(0.0, (sum, expense) => sum + expense.amount.abs());
  }

  /// Calculates total income (only positive amounts)
  double _calculateTotalIncome() {
    return _allExpenses
        .where((expense) => expense.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Callback method for when budget changes occur
  void _onBudgetChanged() {
    // Trigger a rebuild to update any budget-dependent UI elements
    setState(() {});
  }

  // === SUMMARY CARD BUILDER ===
  /// Builds the financial summary card with totals and budget progress
  Widget _buildSummaryCard() {
    // Calculate financial totals
    double totalExpenses = _calculateTotalExpenses();
    double totalIncome = _calculateTotalIncome();
    double netAmount = totalIncome - totalExpenses;
    
    // Get budget progress information
    final budgetProgress = BudgetService.getBudgetProgress(totalExpenses);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Financial summary row
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
            
            // Budget progress section (only shown if budget is set)
            if (budgetProgress['hasBudget'])
              _buildBudgetProgressSection(budgetProgress),
          ],
        ),
      ),
    );
  }

  /// Builds a summary item with icon, title, and value
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

  /// Builds the budget progress section within the summary card
  Widget _buildBudgetProgressSection(Map<String, dynamic> budgetProgress) {
    final isOverBudget = budgetProgress['isOverBudget'] as bool;
    
    return Column(
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        
        // Budget progress header
        Row(
          children: [
            Icon(
              isOverBudget ? Icons.warning_amber_rounded : Icons.trending_flat,
              color: isOverBudget ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Monthly Budget Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Progress bar
        LinearProgressIndicator(
          value: (budgetProgress['percentage'] as double).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverBudget ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        
        // Budget amounts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: €${budgetProgress['spent'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Budget: €${budgetProgress['budgetAmount'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        
        // Status message
        if (isOverBudget)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Over budget by €${(budgetProgress['spent'] - budgetProgress['budgetAmount']).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Remaining: €${budgetProgress['remaining'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // === ANALYTICS SECTION BUILDER ===
  /// Builds the analytics section with charts
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

  // === CSV FILE LOADING ===
  /// Initiates the CSV file loading process with timeout and cancellation support
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

  /// Cancels the current loading operation
  void _cancelLoading() {
    if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
      _loadingCompleter!.completeError('Loading cancelled by user');
    }
  }

  /// Performs the actual CSV loading and data processing
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
}
