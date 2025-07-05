import '../models/expense.dart';
import 'expense_service.dart';
import 'budget_service.dart';

class SpendingRecommendation {
  final String category;
  final double currentMonthlySpend;
  final double suggestedReduction;
  final double potentialSavings;
  final String description;
  final String actionSuggestion;
  final RecommendationType type;
  final int priority; // 1 = high, 2 = medium, 3 = low

  SpendingRecommendation({
    required this.category,
    required this.currentMonthlySpend,
    required this.suggestedReduction,
    required this.potentialSavings,
    required this.description,
    required this.actionSuggestion,
    required this.type,
    required this.priority,
  });
}

enum RecommendationType {
  highSpend,    // Categories with unusually high spending
  frequency,    // Too frequent transactions in a category
  trending,     // Spending is increasing over time
  opportunity   // General optimization opportunities
}

class RecommendationService {
  /// Generates spending recommendations based on expense data
  static List<SpendingRecommendation> generateRecommendations(
    List<Expense> expenses,
    List<MonthlyExpense> monthlyExpenses,
  ) {
    final recommendations = <SpendingRecommendation>[];

    // Get category breakdown for analysis
    final categoryBreakdown = ExpenseService.getCategoryBreakdown(expenses);
    
    // Calculate average monthly spending per category
    final monthlyAverages = _calculateMonthlyAverages(monthlyExpenses);
    
    // Generate budget-specific recommendations first (highest priority)
    recommendations.addAll(_generateBudgetRecommendations(expenses));
    
    // Generate different types of recommendations
    recommendations.addAll(_generateHighSpendRecommendations(categoryBreakdown, monthlyAverages));
    recommendations.addAll(_generateFrequencyRecommendations(expenses, monthlyAverages));
    recommendations.addAll(_generateTrendingRecommendations(monthlyExpenses));
    recommendations.addAll(_generateOpportunityRecommendations(categoryBreakdown, monthlyAverages));

    // Sort by priority (high to low) and potential savings (high to low)
    recommendations.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority);
      }
      return b.potentialSavings.compareTo(a.potentialSavings);
    });

    // Return top 5 recommendations
    return recommendations.take(5).toList();
  }

  /// Calculate average monthly spending per category
  static Map<String, double> _calculateMonthlyAverages(List<MonthlyExpense> monthlyExpenses) {
    if (monthlyExpenses.isEmpty) return {};

    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final monthly in monthlyExpenses) {
      final categoryBreakdown = ExpenseService.getCategoryBreakdown(monthly.expenses);
      for (final entry in categoryBreakdown.entries) {
        categoryTotals.update(entry.key, (value) => value + entry.value, ifAbsent: () => entry.value);
        categoryCounts.update(entry.key, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final monthlyAverages = <String, double>{};
    for (final category in categoryTotals.keys) {
      monthlyAverages[category] = categoryTotals[category]! / monthlyExpenses.length;
    }

    return monthlyAverages;
  }

  /// Generate recommendations for categories with high spending
  static List<SpendingRecommendation> _generateHighSpendRecommendations(
    Map<String, double> categoryBreakdown,
    Map<String, double> monthlyAverages,
  ) {
    final recommendations = <SpendingRecommendation>[];
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedCategories.length && i < 3; i++) {
      final entry = sortedCategories[i];
      final category = entry.key;
      final monthlySpend = monthlyAverages[category] ?? 0;

      if (monthlySpend > 100) { // Only recommend for categories with significant spending
        final reductionPercentage = _getReductionPercentage(category, monthlySpend);
        final potentialSavings = monthlySpend * reductionPercentage;

        recommendations.add(SpendingRecommendation(
          category: category,
          currentMonthlySpend: monthlySpend,
          suggestedReduction: reductionPercentage,
          potentialSavings: potentialSavings,
          description: 'Your ${category.toLowerCase()} spending is above average',
          actionSuggestion: _getActionSuggestion(category, reductionPercentage),
          type: RecommendationType.highSpend,
          priority: i == 0 ? 1 : 2, // Highest category gets priority 1
        ));
      }
    }

    return recommendations;
  }

  /// Generate recommendations based on transaction frequency
  static List<SpendingRecommendation> _generateFrequencyRecommendations(
    List<Expense> expenses,
    Map<String, double> monthlyAverages,
  ) {
    final recommendations = <SpendingRecommendation>[];
    final categoryFrequency = <String, int>{};

    // Count transactions per category in the last month
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    final recentExpenses = expenses.where((e) => 
      e.date.isAfter(lastMonth) && e.amount < 0
    ).toList();

    for (final expense in recentExpenses) {
      final category = ExpenseService.categorizeExpense(expense.description);
      categoryFrequency.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    // Look for categories with high frequency
    for (final entry in categoryFrequency.entries) {
      final category = entry.key;
      final frequency = entry.value;
      final monthlySpend = monthlyAverages[category] ?? 0;

      if (frequency > 10 && monthlySpend > 50) { // More than 10 transactions and significant spending
        final potentialSavings = monthlySpend * 0.1; // 10% reduction from frequency optimization

        recommendations.add(SpendingRecommendation(
          category: category,
          currentMonthlySpend: monthlySpend,
          suggestedReduction: 0.1,
          potentialSavings: potentialSavings,
          description: 'You made $frequency ${category.toLowerCase()} transactions last month',
          actionSuggestion: 'Consider consolidating purchases or setting a weekly budget',
          type: RecommendationType.frequency,
          priority: 2,
        ));
      }
    }

    return recommendations;
  }

  /// Generate recommendations based on spending trends
  static List<SpendingRecommendation> _generateTrendingRecommendations(
    List<MonthlyExpense> monthlyExpenses,
  ) {
    final recommendations = <SpendingRecommendation>[];
    
    if (monthlyExpenses.length < 2) return recommendations;

    // Sort by month
    final sortedMonthly = List<MonthlyExpense>.from(monthlyExpenses)
      ..sort((a, b) => a.month.compareTo(b.month));

    // Analyze trends for each category
    final categoryTrends = <String, List<double>>{};
    
    for (final monthly in sortedMonthly) {
      final categoryBreakdown = ExpenseService.getCategoryBreakdown(monthly.expenses);
      for (final entry in categoryBreakdown.entries) {
        categoryTrends.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }

    for (final entry in categoryTrends.entries) {
      final category = entry.key;
      final values = entry.value;
      
      if (values.length >= 2) {
        final recentSpend = values.last;
        final previousSpend = values[values.length - 2];
        
        // Check if spending increased by more than 20%
        if (recentSpend > previousSpend * 1.2 && recentSpend > 50) {
          final increase = recentSpend - previousSpend;
          final potentialSavings = increase * 0.5; // Save half of the increase

          recommendations.add(SpendingRecommendation(
            category: category,
            currentMonthlySpend: recentSpend,
            suggestedReduction: (increase / recentSpend) * 0.5,
            potentialSavings: potentialSavings,
            description: 'Your ${category.toLowerCase()} spending increased by €${increase.toStringAsFixed(2)} last month',
            actionSuggestion: 'Review recent purchases and identify unnecessary expenses',
            type: RecommendationType.trending,
            priority: 1,
          ));
        }
      }
    }

    return recommendations;
  }

  /// Generate general opportunity recommendations
  static List<SpendingRecommendation> _generateOpportunityRecommendations(
    Map<String, double> categoryBreakdown,
    Map<String, double> monthlyAverages,
  ) {
    final recommendations = <SpendingRecommendation>[];

    // Specific opportunities based on category analysis
    final opportunities = {
      'Food & Dining': {
        'threshold': 200.0,
        'reduction': 0.15,
        'action': 'Cook at home more often and limit restaurant visits to 2-3 times per week'
      },
      'Entertainment': {
        'threshold': 100.0,
        'reduction': 0.2,
        'action': 'Look for free activities and cancel unused subscriptions'
      },
      'Shopping': {
        'threshold': 150.0,
        'reduction': 0.1,
        'action': 'Create a shopping list and wait 24 hours before non-essential purchases'
      },
      'Transportation': {
        'threshold': 80.0,
        'reduction': 0.15,
        'action': 'Consider carpooling, public transport, or walking for short distances'
      },
    };

    for (final entry in opportunities.entries) {
      final category = entry.key;
      final config = entry.value;
      final monthlySpend = monthlyAverages[category] ?? 0;
      final threshold = config['threshold'] as double;
      final reduction = config['reduction'] as double;
      final action = config['action'] as String;

      if (monthlySpend > threshold) {
        final potentialSavings = monthlySpend * reduction;

        recommendations.add(SpendingRecommendation(
          category: category,
          currentMonthlySpend: monthlySpend,
          suggestedReduction: reduction,
          potentialSavings: potentialSavings,
          description: 'Optimize your ${category.toLowerCase()} spending',
          actionSuggestion: action,
          type: RecommendationType.opportunity,
          priority: 3,
        ));
      }
    }

    return recommendations;
  }

  /// Get appropriate reduction percentage based on category and spending amount
  static double _getReductionPercentage(String category, double monthlySpend) {
    switch (category) {
      case 'Food & Dining':
        return monthlySpend > 300 ? 0.2 : 0.15;
      case 'Entertainment':
        return monthlySpend > 200 ? 0.25 : 0.2;
      case 'Shopping':
        return monthlySpend > 250 ? 0.15 : 0.1;
      case 'Transportation':
        return 0.15;
      case 'Digital Services':
        return 0.3; // Often have unused subscriptions
      default:
        return 0.1;
    }
  }

  /// Get specific action suggestion for each category
  static String _getActionSuggestion(String category, double reductionPercentage) {
    final percentage = (reductionPercentage * 100).round();
    
    switch (category) {
      case 'Food & Dining':
        return 'Reducing delivery orders by $percentage% could save you this amount';
      case 'Entertainment':
        return 'Review subscriptions and limit entertainment expenses by $percentage%';
      case 'Shopping':
        return 'Implementing a 24-hour wait rule for non-essentials could reduce spending by $percentage%';
      case 'Transportation':
        return 'Using alternative transport methods $percentage% of the time could achieve these savings';
      case 'Digital Services':
        return 'Cancel unused subscriptions to reduce spending by $percentage%';
      case 'Transfers & Fees':
        return 'Optimize your banking and transfer methods to reduce fees by $percentage%';
      default:
        return 'Reducing $category spending by $percentage% could achieve these savings';
    }
  }

  /// Generate budget-specific recommendations
  static List<SpendingRecommendation> _generateBudgetRecommendations(List<Expense> expenses) {
    final recommendations = <SpendingRecommendation>[];
    
    // Get current budget
    final budget = BudgetService.getCurrentBudget();
    if (budget == null) {
      return recommendations; // No budget set, no budget recommendations
    }

    // Calculate current month's expenses
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((expense) {
      return expense.date.year == now.year && 
             expense.date.month == now.month &&
             expense.amount < 0; // Only expenses
    }).toList();

    final totalSpent = currentMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount.abs());
    final budgetProgress = BudgetService.getBudgetProgress(totalSpent);
    
    final percentage = budgetProgress['percentage'] as double;
    final remaining = budgetProgress['remaining'] as double;
    final isOverBudget = budgetProgress['isOverBudget'] as bool;

    if (isOverBudget) {
      // Recommend budget adjustments when over budget
      final overage = -remaining;
      recommendations.add(SpendingRecommendation(
        category: 'Budget Management',
        currentMonthlySpend: totalSpent,
        suggestedReduction: overage / totalSpent,
        potentialSavings: overage,
        description: 'You\'ve exceeded your monthly budget',
        actionSuggestion: 'Reduce spending by €${overage.toStringAsFixed(0)} to get back on track next month',
        type: RecommendationType.highSpend,
        priority: 1,
      ));
    } else if (percentage > 0.8) {
      // Recommend careful spending when approaching budget limit
      recommendations.add(SpendingRecommendation(
        category: 'Budget Management',
        currentMonthlySpend: totalSpent,
        suggestedReduction: 0.1,
        potentialSavings: remaining * 0.5,
        description: 'You\'re approaching your monthly budget limit',
        actionSuggestion: 'Be mindful of spending to stay within your €${budget.amount.toStringAsFixed(0)} budget',
        type: RecommendationType.opportunity,
        priority: 2,
      ));
    } else if (percentage < 0.5) {
      // Recommend increasing savings when well under budget
      final surplus = remaining;
      recommendations.add(SpendingRecommendation(
        category: 'Savings Opportunity',
        currentMonthlySpend: totalSpent,
        suggestedReduction: 0.0,
        potentialSavings: surplus * 0.8,
        description: 'You\'re doing great staying under budget!',
        actionSuggestion: 'Consider saving an extra €${(surplus * 0.8).toStringAsFixed(0)} this month',
        type: RecommendationType.opportunity,
        priority: 3,
      ));
    }

    return recommendations;
  }
}
