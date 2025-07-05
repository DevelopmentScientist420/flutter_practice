import '../models/expense.dart';
import '../services/budget_service.dart';

enum AlertType {
  warning,
  danger,
  info,
  success,
}

enum AlertCategory {
  budget,
  spending,
  trend,
  goal,
}

class SpendingAlert {
  final String title;
  final String message;
  final AlertType type;
  final AlertCategory category;
  final double? threshold;
  final double? currentValue;
  final String? actionSuggestion;
  final DateTime timestamp;

  SpendingAlert({
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.threshold,
    this.currentValue,
    this.actionSuggestion,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AlertService {
  // Default monthly budgets by category (in euros)
  static const Map<String, double> _defaultBudgets = {
    'Food & Dining': 300.0,
    'Shopping': 200.0,
    'Transportation': 150.0,
    'Entertainment': 100.0,
    'Bills & Utilities': 250.0,
    'Healthcare': 80.0,
    'Travel': 150.0,
    'Education': 50.0,
    'Personal Care': 60.0,
    'Other': 100.0,
  };

  static List<SpendingAlert> generateAlerts(
    List<Expense> expenses,
    List<MonthlyExpense> monthlyExpenses,
  ) {
    List<SpendingAlert> alerts = [];

    // Get current month's expenses
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((expense) {
      return expense.date.year == now.year && 
             expense.date.month == now.month &&
             expense.amount < 0; // Only expenses, not income
    }).toList();

    // Generate budget alerts
    alerts.addAll(_generateBudgetAlerts(currentMonthExpenses));

    // Generate spending trend alerts
    alerts.addAll(_generateTrendAlerts(monthlyExpenses));

    // Generate frequency alerts
    alerts.addAll(_generateFrequencyAlerts(currentMonthExpenses));

    // Generate high transaction alerts
    alerts.addAll(_generateHighTransactionAlerts(currentMonthExpenses));

    // Sort alerts by priority (danger > warning > info > success)
    alerts.sort((a, b) {
      final priorityOrder = {
        AlertType.danger: 0,
        AlertType.warning: 1,
        AlertType.info: 2,
        AlertType.success: 3,
      };
      return priorityOrder[a.type]!.compareTo(priorityOrder[b.type]!);
    });

    return alerts;
  }

  static List<SpendingAlert> _generateBudgetAlerts(List<Expense> currentMonthExpenses) {
    List<SpendingAlert> alerts = [];

    // Get the user's monthly budget
    final budget = BudgetService.getCurrentBudget();
    if (budget == null) {
      return alerts; // No budget set, no budget alerts
    }

    // Calculate total monthly spending
    final totalSpent = currentMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount.abs());
    final budgetProgress = BudgetService.getBudgetProgress(totalSpent);
    
    final percentage = budgetProgress['percentage'] as double;
    final remaining = budgetProgress['remaining'] as double;
    final isOverBudget = budgetProgress['isOverBudget'] as bool;

    // Generate budget alerts based on spending progress
    if (isOverBudget) {
      alerts.add(SpendingAlert(
        title: 'Monthly Budget Exceeded!',
        message: 'You\'ve exceeded your monthly budget of €${budget.amount.toStringAsFixed(0)} by €${(-remaining).toStringAsFixed(0)}.',
        type: AlertType.danger,
        category: AlertCategory.budget,
        threshold: budget.amount,
        currentValue: totalSpent,
        actionSuggestion: 'Review your recent expenses and consider cutting back on non-essential spending.',
      ));
    } else if (percentage >= 0.9) {
      alerts.add(SpendingAlert(
        title: 'Budget Alert - 90% Used',
        message: 'You\'ve used ${(percentage * 100).toStringAsFixed(0)}% of your monthly budget. Only €${remaining.toStringAsFixed(0)} remaining.',
        type: AlertType.warning,
        category: AlertCategory.budget,
        threshold: budget.amount,
        currentValue: totalSpent,
        actionSuggestion: 'Be mindful of spending for the rest of the month to stay within budget.',
      ));
    } else if (percentage >= 0.75) {
      alerts.add(SpendingAlert(
        title: 'Budget Warning - 75% Used',
        message: 'You\'ve used ${(percentage * 100).toStringAsFixed(0)}% of your monthly budget. €${remaining.toStringAsFixed(0)} remaining.',
        type: AlertType.info,
        category: AlertCategory.budget,
        threshold: budget.amount,
        currentValue: totalSpent,
        actionSuggestion: 'You\'re on track but keep monitoring your spending.',
      ));
    }

    // Also check category-wise spending against default budgets if over budget
    if (isOverBudget) {
      Map<String, double> categorySpending = {};
      for (var expense in currentMonthExpenses) {
        categorySpending[expense.type] = 
            (categorySpending[expense.type] ?? 0.0) + expense.amount.abs();
      }

      // Find top spending categories
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedCategories.take(2)) { // Top 2 categories
        final category = entry.key;
        final spent = entry.value;
        final categoryBudget = _defaultBudgets[category] ?? 100.0;
        
        if (spent > categoryBudget) {
          alerts.add(SpendingAlert(
            title: 'High $category Spending',
            message: 'Your $category spending (€${spent.toStringAsFixed(0)}) is contributing to your budget overage.',
            type: AlertType.info,
            category: AlertCategory.spending,
            threshold: categoryBudget,
            currentValue: spent,
            actionSuggestion: 'Consider reducing $category expenses next month.',
          ));
        }
      }
    }

    return alerts;
  }

  static List<SpendingAlert> _generateTrendAlerts(List<MonthlyExpense> monthlyExpenses) {
    List<SpendingAlert> alerts = [];

    if (monthlyExpenses.length < 2) return alerts;

    // Compare last two months
    final currentMonth = monthlyExpenses.first;
    final previousMonth = monthlyExpenses[1];

    final increase = ((currentMonth.totalAmount - previousMonth.totalAmount) / previousMonth.totalAmount) * 100;

    if (increase > 20) {
      alerts.add(SpendingAlert(
        title: 'Spending Spike!',
        message: 'Your spending increased by ${increase.toStringAsFixed(0)}% compared to last month (€${currentMonth.totalAmount.toStringAsFixed(0)} vs €${previousMonth.totalAmount.toStringAsFixed(0)}).',
        type: AlertType.danger,
        category: AlertCategory.trend,
        threshold: previousMonth.totalAmount,
        currentValue: currentMonth.totalAmount,
        actionSuggestion: 'Review your recent large purchases and consider ways to reduce spending.',
      ));
    } else if (increase > 10) {
      alerts.add(SpendingAlert(
        title: 'Spending Increase',
        message: 'Your spending is up ${increase.toStringAsFixed(0)}% from last month.',
        type: AlertType.warning,
        category: AlertCategory.trend,
        threshold: previousMonth.totalAmount,
        currentValue: currentMonth.totalAmount,
        actionSuggestion: 'Monitor your spending to avoid it becoming a trend.',
      ));
    } else if (increase < -10) {
      alerts.add(SpendingAlert(
        title: 'Great Savings!',
        message: 'You\'ve reduced spending by ${(-increase).toStringAsFixed(0)}% compared to last month!',
        type: AlertType.success,
        category: AlertCategory.trend,
        threshold: previousMonth.totalAmount,
        currentValue: currentMonth.totalAmount,
        actionSuggestion: 'Keep up the good work with your spending discipline!',
      ));
    }

    return alerts;
  }

  static List<SpendingAlert> _generateFrequencyAlerts(List<Expense> currentMonthExpenses) {
    List<SpendingAlert> alerts = [];

    // Count transactions by category (using type field)
    Map<String, int> categoryFrequency = {};
    for (var expense in currentMonthExpenses) {
      categoryFrequency[expense.type] = 
          (categoryFrequency[expense.type] ?? 0) + 1;
    }

    // Check for high frequency categories
    for (var entry in categoryFrequency.entries) {
      final category = entry.key;
      final count = entry.value;

      if (category == 'Food & Dining' && count > 50) {
        alerts.add(SpendingAlert(
          title: 'Frequent Dining',
          message: 'You\'ve made $count food purchases this month.',
          type: AlertType.warning,
          category: AlertCategory.spending,
          currentValue: count.toDouble(),
          actionSuggestion: 'Consider meal planning or cooking at home more often.',
        ));
      } else if (category == 'Shopping' && count > 20) {
        alerts.add(SpendingAlert(
          title: 'Shopping Spree',
          message: 'You\'ve made $count shopping transactions this month.',
          type: AlertType.warning,
          category: AlertCategory.spending,
          currentValue: count.toDouble(),
          actionSuggestion: 'Try to consolidate purchases or implement a shopping list.',
        ));
      }
    }

    return alerts;
  }

  static List<SpendingAlert> _generateHighTransactionAlerts(List<Expense> currentMonthExpenses) {
    List<SpendingAlert> alerts = [];

    // Find unusually large transactions (over €200)
    final largeTransactions = currentMonthExpenses
        .where((expense) => expense.amount.abs() > 200)
        .toList();

    if (largeTransactions.length > 3) {
      final totalLarge = largeTransactions.fold(0.0, (sum, expense) => sum + expense.amount.abs());
      alerts.add(SpendingAlert(
        title: 'Large Transactions',
        message: 'You\'ve made ${largeTransactions.length} transactions over €200 this month, totaling €${totalLarge.toStringAsFixed(0)}.',
        type: AlertType.info,
        category: AlertCategory.spending,
        currentValue: totalLarge,
        actionSuggestion: 'Review these large purchases to ensure they align with your financial goals.',
      ));
    }

    // Check for single very large transaction (over €500)
    final veryLargeTransaction = currentMonthExpenses
        .where((expense) => expense.amount.abs() > 500)
        .fold(0.0, (max, expense) => expense.amount.abs() > max ? expense.amount.abs() : max);

    if (veryLargeTransaction > 500) {
      alerts.add(SpendingAlert(
        title: 'Large Purchase Alert',
        message: 'You made a purchase of €${veryLargeTransaction.toStringAsFixed(0)} this month.',
        type: AlertType.warning,
        category: AlertCategory.spending,
        currentValue: veryLargeTransaction,
        actionSuggestion: 'Ensure this purchase fits within your monthly budget and financial plan.',
      ));
    }

    return alerts;
  }
}
