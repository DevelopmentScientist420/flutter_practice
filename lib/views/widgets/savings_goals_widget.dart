import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/saving_goal.dart';
import '../../services/saving_goal_service.dart';

class SavingsGoalsWidget extends StatefulWidget {
  final List<MonthlyExpense> monthlyExpenses;

  const SavingsGoalsWidget({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  State<SavingsGoalsWidget> createState() => _SavingsGoalsWidgetState();
}

class _SavingsGoalsWidgetState extends State<SavingsGoalsWidget> {
  final List<SavingGoal> _savingGoals = [];
  SavingSuggestion? _suggestion;
  bool _showAddGoalForm = false;

  @override
  void initState() {
    super.initState();
    _calculateSuggestion();
  }

  @override
  void didUpdateWidget(SavingsGoalsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.monthlyExpenses != oldWidget.monthlyExpenses) {
      _calculateSuggestion();
    }
  }

  void _calculateSuggestion() {
    setState(() {
      _suggestion = SavingGoalService.calculateSavingSuggestion(widget.monthlyExpenses);
    });
  }

  void _addSavingGoal(SavingGoal goal) {
    setState(() {
      _savingGoals.add(goal);
      _showAddGoalForm = false;
    });
  }

  void _removeSavingGoal(String goalId) {
    setState(() {
      _savingGoals.removeWhere((goal) => goal.id == goalId);
    });
  }

  void _updateGoalProgress(String goalId, double amount) {
    setState(() {
      final index = _savingGoals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        _savingGoals[index] = _savingGoals[index].copyWith(
          currentAmount: (_savingGoals[index].currentAmount + amount).clamp(0, _savingGoals[index].targetAmount),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Goals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddGoalForm = !_showAddGoalForm;
                    });
                  },
                  icon: Icon(_showAddGoalForm ? Icons.close : Icons.add),
                  label: Text(_showAddGoalForm ? 'Cancel' : 'Add Goal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Savings suggestion card
            if (_suggestion != null) ...[
              _buildSuggestionCard(_suggestion!),
              const SizedBox(height: 16),
            ],
            
            // Add goal form
            if (_showAddGoalForm) ...[
              _AddGoalForm(
                onAddGoal: _addSavingGoal,
                suggestion: _suggestion,
              ),
              const SizedBox(height: 16),
            ],
            
            // Goals list
            if (_savingGoals.isEmpty && !_showAddGoalForm)
              _buildEmptyState()
            else
              ..._savingGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalCard(goal),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(SavingSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.cyan[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Savings Recommendation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestion.suggestedMonthlySaving > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '€${suggestion.suggestedMonthlySaving.toStringAsFixed(0)}/month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.reasoning,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Avg Income',
                  '€${suggestion.averageMonthlyIncome.toStringAsFixed(0)}',
                  Colors.green,
                ),
                _buildStatItem(
                  'Avg Expenses',
                  '€${suggestion.averageMonthlyExpense.toStringAsFixed(0)}',
                  Colors.red,
                ),
                _buildStatItem(
                  'Net Surplus',
                  '€${suggestion.potentialSaving.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ],
            ),
          ] else ...[
            Text(
              suggestion.reasoning,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(SavingGoal goal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      goal.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showAddFundsDialog(goal),
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.green,
                    tooltip: 'Add funds',
                  ),
                  IconButton(
                    onPressed: () => _removeSavingGoal(goal.id),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Delete goal',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '€${goal.currentAmount.toStringAsFixed(0)} / €${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: goal.isAchieved ? Colors.green : Colors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: goal.progressPercentage / 100,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isAchieved ? Colors.green : Colors.cyan,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Goal details
          Row(
            children: [
              Expanded(
                child: _buildGoalDetail(
                  'Target Date',
                  DateFormat('dd/MM/yyyy').format(goal.targetDate),
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildGoalDetail(
                  'Days Left',
                  '${goal.daysRemaining}',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildGoalDetail(
                  'Monthly Need',
                  '€${goal.requiredMonthlySaving.toStringAsFixed(0)}',
                  Icons.savings,
                ),
              ),
            ],
          ),
          
          if (goal.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              goal.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No savings goals yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              'Click "Add Goal" to create your first savings goal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsDialog(SavingGoal goal) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Funds to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current amount: €${goal.currentAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to add',
                hintText: '0.00',
                prefixText: '€',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                _updateGoalProgress(goal.id, amount);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AddGoalForm extends StatefulWidget {
  final Function(SavingGoal) onAddGoal;
  final SavingSuggestion? suggestion;

  const _AddGoalForm({
    required this.onAddGoal,
    this.suggestion,
  });

  @override
  State<_AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends State<_AddGoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = SavingGoalService.goalCategories.first;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  
  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Savings Goal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Goal name and category
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g., Summer Vacation',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Please enter a goal name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: SavingGoalService.goalCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount and suggested amounts
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    hintText: '0.00',
                    prefixText: '€',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Suggested amounts
                const Text(
                  'Suggested amounts:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: SavingGoalService.getSuggestedAmounts()[_selectedCategory]?.map((amount) {
                    return ActionChip(
                      label: Text('€${amount.toStringAsFixed(0)}'),
                      onPressed: () {
                        _amountController.text = amount.toStringAsFixed(0);
                      },
                      backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.cyan.withValues(alpha: 0.3)),
                    );
                  }).toList() ?? [],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Target date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
                );
                if (date != null) {
                  setState(() {
                    _targetDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_targetDate)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add details about your goal...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createGoal() {
    if (_formKey.currentState?.validate() ?? false) {
      final goal = SavingGoal(
        id: SavingGoalService.generateId(),
        name: _nameController.text.trim(),
        targetAmount: double.parse(_amountController.text),
        targetDate: _targetDate,
        createdDate: DateTime.now(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );
      
      widget.onAddGoal(goal);
    }
  }
}
