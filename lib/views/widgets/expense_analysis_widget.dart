import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import 'charts/expense_pie_chart.dart';
import 'monthly_breakdown_view.dart';
import 'transactions_table.dart';
import 'savings_goals_widget.dart';
import 'spending_recommendations_widget.dart';
import 'spending_alerts_widget.dart';
import 'budget_widget.dart';

/// Main widget for expense analysis dashboard
/// 
/// This widget orchestrates the entire expense analysis interface including:
/// - File loading and data processing
/// - Multiple analysis widgets (charts, tables, alerts, recommendations)
/// - Budget management integration
/// - Data change notifications for parent components
class ExpenseAnalysisWidget extends StatefulWidget {
  /// Callback triggered when financial data changes (for chatbot context)
  final ValueChanged<Map<String, dynamic>>? onDataChanged;
  
  const ExpenseAnalysisWidget({
    super.key,
    this.onDataChanged,
  });

  @override
  State<ExpenseAnalysisWidget> createState() => _ExpenseAnalysisWidgetState();
}

class _ExpenseAnalysisWidgetState extends State<ExpenseAnalysisWidget> {
  // === DATA STATE ===
  /// All loaded expenses from the CSV file
  List<Expense> _allExpenses = [];
  
  /// Monthly expense summaries for trend analysis
  List<MonthlyExpense> _monthlyExpenses = [];
  
  /// Expense breakdown by category/type
  Map<String, double> _typeData = {};
  
  // === UI STATE ===
  /// Whether the app is currently loading data
  bool _isLoading = false;
  
  /// Current error message (null if no error)
  String? _errorMessage;
  
  /// Loading progress message
  String _loadingMessage = 'Loading...';
  
  /// Completer for handling loading cancellation
  Completer<void>? _loadingCompleter;

  // === WIDGET KEYS FOR BUDGET CHANGE NOTIFICATIONS ===
  /// Key for spending alerts widget to trigger refresh
  final GlobalKey _alertsKey = GlobalKey();
  
  /// Key for recommendations widget to trigger refresh
  final GlobalKey _recommendationsKey = GlobalKey();
  
  /// Key for savings goals widget to trigger refresh
  final GlobalKey _savingsGoalsKey = GlobalKey();

  /// Handles budget changes and refreshes dependent widgets
  void _onBudgetChanged() {
    // Refresh all budget-dependent widgets when budget is set/updated/cleared
    final alertsState = _alertsKey.currentState as dynamic;
    final recommendationsState = _recommendationsKey.currentState as dynamic;
    final savingsGoalsState = _savingsGoalsKey.currentState as dynamic;
    
    // Call refresh methods if widgets are available
    alertsState?.refreshAlerts();
    recommendationsState?.refreshRecommendations();
    savingsGoalsState?.refreshSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === HEADER SECTION ===
        _buildHeaderSection(),
        
        // === MAIN CONTENT SECTION ===
        _buildContent(),
      ],
    );
  }

  /// Builds the header section with title and upload button
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Title and description
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
    );
  }
  /// Builds the main content area based on current state
  Widget _buildContent() {
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

  /// Builds the loading view with progress indicators
  Widget _buildLoadingView() {
    return SizedBox(
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

  /// Builds the error view with error message and dismiss button
  Widget _buildErrorView() {
    return SizedBox(
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

  /// Builds the empty view when no data is loaded
  Widget _buildEmptyView() {
    return SizedBox(
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
          ],
        ),
      ),
    );
  }

  /// Builds the main analytics view with all dashboard components
  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Spending alerts widget (at the top for priority)
          if (_allExpenses.isNotEmpty && _monthlyExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpendingAlertsWidget(
                key: _alertsKey,
                expenses: _allExpenses,
                monthlyExpenses: _monthlyExpenses,
              ),
            ),
          
          // Financial summary card
          _buildSummaryCard(),
          
          // Budget management widget
          if (_allExpenses.isNotEmpty)
            BudgetWidget(
              totalExpenses: _allExpenses
                  .where((expense) => expense.amount < 0)
                  .fold(0.0, (sum, expense) => sum + expense.amount.abs()),
              onBudgetChanged: _onBudgetChanged,
            ),
          
          // Analytics section (charts and visualizations)
          if (_typeData.isNotEmpty || _monthlyExpenses.isNotEmpty)
            _buildAnalyticsSection(),
          
          // Savings goals widget
          if (_monthlyExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SavingsGoalsWidget(
                key: _savingsGoalsKey,
                monthlyExpenses: _monthlyExpenses,
              ),
            ),
          
          // Spending recommendations widget
          if (_allExpenses.isNotEmpty && _monthlyExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpendingRecommendationsWidget(
                key: _recommendationsKey,
                expenses: _allExpenses,
                monthlyExpenses: _monthlyExpenses,
              ),
            ),
          
          // Detailed transactions table
          if (_allExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TransactionsTable(expenses: _allExpenses),
            ),
        ],
      ),
    );
  }

  /// Builds the financial summary card with key metrics
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
            // Card title
            const Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary metrics row
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

  /// Builds individual summary items for the summary card
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
          textAlign: TextAlign.center,
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

  /// Builds the analytics section with charts and visualizations
  Widget _buildAnalyticsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout: side-by-side on wide screens, stacked on narrow screens
        bool isWideScreen = constraints.maxWidth > 600;
        
        if (isWideScreen) {
          // Desktop/tablet landscape layout
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
                
                // Spacing between charts
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
          // Mobile/tablet portrait layout
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

  // === FILE LOADING METHODS ===

  /// Initiates CSV file loading process
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

  /// Performs the actual CSV file loading and data processing
  Future<void> _performCsvLoad() async {
    // Update loading message for different stages
    setState(() {
      _loadingMessage = 'Reading CSV file...';
    });
    
    // Load and parse CSV file
    List<Expense> expenses = await ExpenseService.pickAndParseCsvFile();
    
    setState(() {
      _loadingMessage = 'Analyzing data (${expenses.length} records)...';
    });
    
    // Add small delays to prevent UI blocking and show progress
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Process data for analytics
    Map<String, double> typeData = ExpenseService.getCategoryBreakdown(expenses);
    List<MonthlyExpense> monthlyExpenses = ExpenseService.getLastThreeMonthsExpenses(expenses);
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Update state with processed data
    setState(() {
      _allExpenses = expenses;
      _typeData = typeData;
      _monthlyExpenses = monthlyExpenses;
      _isLoading = false;
    });

    // Notify parent about the data change
    _notifyDataChanged();
  }

  // === DATA MANAGEMENT ===

  /// Gets a summary of financial data for external use (e.g., chatbot)
  Map<String, dynamic> get financialSummary {
    if (_allExpenses.isEmpty) return {};
    
    // Calculate key metrics
    double totalExpenses = _allExpenses
        .where((expense) => expense.amount < 0)
        .fold(0.0, (sum, expense) => sum + expense.amount.abs());
    
    double totalIncome = _allExpenses
        .where((expense) => expense.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    
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
      'recordCount': _allExpenses.length,
    };
  }

  /// Notifies parent widget about data changes
  void _notifyDataChanged() {
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(financialSummary);
    }
  }
}