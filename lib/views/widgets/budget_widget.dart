import 'package:flutter/material.dart';
import '../../services/budget_service.dart';

/// A widget that allows users to set, view, and manage their monthly budget.
/// 
/// This widget provides functionality to:
/// - Set a new monthly budget
/// - Edit an existing budget
/// - View budget progress with visual indicators
/// - Clear/delete the current budget
/// - Display budget status messages and warnings
class BudgetWidget extends StatefulWidget {
  /// Total expenses for the current period
  final double totalExpenses;
  
  /// Callback function triggered when budget is changed (set, updated, or cleared)
  final VoidCallback? onBudgetChanged;

  const BudgetWidget({
    super.key,
    required this.totalExpenses,
    this.onBudgetChanged,
  });

  @override
  State<BudgetWidget> createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends State<BudgetWidget> {
  // Controllers and state variables
  final TextEditingController _budgetController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  /// Sets or updates the monthly budget with the entered amount
  void _setBudget() {
    final amount = double.tryParse(_budgetController.text);
    if (amount != null && amount > 0) {
      // Update budget in service
      BudgetService.setBudget(amount);
      
      // Reset UI state
      setState(() {
        _isEditing = false;
      });
      _budgetController.clear();
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monthly budget set to €${amount.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Notify parent components about budget change
      widget.onBudgetChanged?.call();
    }
  }

  /// Clears the current budget and resets the budget system
  void _clearBudget() {
    // Remove budget from service
    BudgetService.clearBudget();
    
    // Trigger UI rebuild
    setState(() {});
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget cleared'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // Notify parent components about budget change
    widget.onBudgetChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Get current budget status and progress
    final budgetProgress = BudgetService.getBudgetProgress(widget.totalExpenses);
    final hasBudget = budgetProgress['hasBudget'] as bool;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER SECTION ===
            _buildHeader(hasBudget),
            const SizedBox(height: 20),

            // === MAIN CONTENT ===
            if (!hasBudget || _isEditing) 
              // Show budget input form
              _buildBudgetForm()
            else 
              // Show budget progress and status
              _buildBudgetProgress(budgetProgress),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and optional delete button
  Widget _buildHeader(bool hasBudget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Monthly Budget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        // Delete button (only shown when budget exists and not editing)
        if (hasBudget && !_isEditing)
          IconButton(
            onPressed: _clearBudget,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Budget',
          ),
      ],
    );
  }

  /// Builds the budget input form for setting or editing budget
  Widget _buildBudgetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form title
        Text(
          _isEditing ? 'Update your monthly budget:' : 'Set your monthly budget:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Input row with text field and buttons
        Row(
          children: [
            // Budget amount input
            Expanded(
              child: TextField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  prefixText: '€',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '1000.00',
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _setBudget(),
              ),
            ),
            const SizedBox(width: 12),
            
            // Set/Update button
            ElevatedButton(
              onPressed: _setBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text(_isEditing ? 'Update' : 'Set Budget'),
            ),
            
            // Cancel button (only shown when editing)
            if (_isEditing) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                  _budgetController.clear();
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Builds the budget progress display with status indicators
  Widget _buildBudgetProgress(Map<String, dynamic> budgetProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === BUDGET SUMMARY ===
        _buildBudgetSummary(budgetProgress),
        const SizedBox(height: 16),

        // === PROGRESS BAR ===
        _buildProgressBar(budgetProgress),

        // === STATUS MESSAGES ===
        _buildStatusMessage(budgetProgress),
      ],
    );
  }

  /// Builds the budget summary section with amounts and edit button
  Widget _buildBudgetSummary(Map<String, dynamic> budgetProgress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Budget and spending amounts
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget: €${budgetProgress['budgetAmount'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Spent: €${budgetProgress['spent'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        // Edit button
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Builds the progress bar with remaining amount and percentage
  Widget _buildProgressBar(Map<String, dynamic> budgetProgress) {
    final isOverBudget = budgetProgress['isOverBudget'] as bool;
    final percentage = budgetProgress['percentage'] as double;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOverBudget 
                  ? 'Over Budget by €${(-budgetProgress['remaining']).toStringAsFixed(2)}'
                  : 'Remaining: €${budgetProgress['remaining'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(isOverBudget, percentage),
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  /// Builds status messages based on budget progress
  Widget _buildStatusMessage(Map<String, dynamic> budgetProgress) {
    final isOverBudget = budgetProgress['isOverBudget'] as bool;
    final percentage = budgetProgress['percentage'] as double;

    if (isOverBudget) {
      // Over budget warning
      return _buildStatusCard(
        color: Colors.red,
        icon: Icons.warning_amber,
        message: 'You\'ve exceeded your monthly budget. Consider reviewing your expenses.',
      );
    } else if (percentage > 0.8) {
      // Approaching budget limit warning
      return _buildStatusCard(
        color: Colors.orange,
        icon: Icons.info_outline,
        message: 'You\'re approaching your monthly budget limit. Keep an eye on your spending.',
      );
    }
    
    // No status message needed
    return const SizedBox.shrink();
  }

  /// Helper method to build status cards with consistent styling
  Widget _buildStatusCard({
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _getIconColor(color), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Gets the appropriate icon color based on the main color
  Color _getIconColor(Color color) {
    if (color == Colors.red) return Colors.red[700]!;
    if (color == Colors.orange) return Colors.orange[700]!;
    return color;
  }

  /// Determines the appropriate color for the progress bar
  Color _getProgressColor(bool isOverBudget, double percentage) {
    if (isOverBudget) {
      return Colors.red;
    } else if (percentage > 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
