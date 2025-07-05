class MonthlyBudget {
  final String category;
  final double budgetAmount;
  final double currentSpent;
  final DateTime month;
  final bool isOverBudget;

  MonthlyBudget({
    required this.category,
    required this.budgetAmount,
    required this.currentSpent,
    required this.month,
  }) : isOverBudget = currentSpent > budgetAmount;

  double get remainingBudget => budgetAmount - currentSpent;
  double get percentageUsed => budgetAmount > 0 ? (currentSpent / budgetAmount) * 100 : 0;
  
  BudgetStatus get status {
    if (percentageUsed <= 70) return BudgetStatus.good;
    if (percentageUsed <= 90) return BudgetStatus.warning;
    return BudgetStatus.exceeded;
  }
}

enum BudgetStatus {
  good,
  warning,
  exceeded,
}

class BudgetSettings {
  final Map<String, double> categoryBudgets;
  final double totalMonthlyBudget;
  final DateTime lastUpdated;

  BudgetSettings({
    required this.categoryBudgets,
    required this.totalMonthlyBudget,
    required this.lastUpdated,
  });

  factory BudgetSettings.defaultBudgets() {
    return BudgetSettings(
      categoryBudgets: {
        'Food & Dining': 400.0,
        'Transportation': 200.0,
        'Entertainment': 150.0,
        'Shopping': 300.0,
        'Digital Services': 50.0,
        'Health & Fitness': 100.0,
        'Utilities': 150.0,
        'Groceries': 250.0,
        'Other': 100.0,
      },
      totalMonthlyBudget: 1700.0,
      lastUpdated: DateTime.now(),
    );
  }
}
