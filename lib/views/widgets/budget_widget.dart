import 'package:flutter/material.dart';
import '../../services/budget_service.dart';

class BudgetWidget extends StatefulWidget {
  final double totalExpenses;

  const BudgetWidget({
    super.key,
    required this.totalExpenses,
  });

  @override
  State<BudgetWidget> createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends State<BudgetWidget> {
  final TextEditingController _budgetController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _setBudget() {
    final amount = double.tryParse(_budgetController.text);
    if (amount != null && amount > 0) {
      BudgetService.setBudget(amount);
      setState(() {
        _isEditing = false;
      });
      _budgetController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monthly budget set to €${amount.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearBudget() {
    BudgetService.clearBudget();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                if (hasBudget && !_isEditing)
                  IconButton(
                    onPressed: _clearBudget,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Clear Budget',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (!hasBudget || _isEditing) ...[
              // Set Budget Section
              Text(
                _isEditing ? 'Update your monthly budget:' : 'Set your monthly budget:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                  ElevatedButton(
                    onPressed: _setBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text(_isEditing ? 'Update' : 'Set Budget'),
                  ),
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
            ] else ...[
              // Budget Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budgetProgress['isOverBudget'] 
                            ? 'Over Budget by €${(-budgetProgress['remaining']).toStringAsFixed(2)}'
                            : 'Remaining: €${budgetProgress['remaining'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: budgetProgress['isOverBudget'] ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        '${(budgetProgress['percentage'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: budgetProgress['isOverBudget'] ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (budgetProgress['percentage'] as double).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budgetProgress['isOverBudget'] 
                          ? Colors.red
                          : budgetProgress['percentage'] > 0.8 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),

              // Budget Status Message
              if (budgetProgress['isOverBudget']) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'You\'ve exceeded your monthly budget. Consider reviewing your expenses.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (budgetProgress['percentage'] > 0.8) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'You\'re approaching your monthly budget limit. Keep an eye on your spending.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
