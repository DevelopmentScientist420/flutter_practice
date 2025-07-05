import '../models/expense.dart';
import '../models/saving_goal.dart';

class SavingGoalService {
  // Calculate saving suggestions based on spending patterns
  static SavingSuggestion calculateSavingSuggestion(List<MonthlyExpense> monthlyExpenses) {
    if (monthlyExpenses.isEmpty) {
      return SavingSuggestion(
        suggestedMonthlySaving: 0.0,
        averageMonthlyExpense: 0.0,
        averageMonthlyIncome: 0.0,
        potentialSaving: 0.0,
        reasoning: 'No spending data available to calculate suggestions.',
      );
    }

    // Calculate averages
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    int monthCount = monthlyExpenses.length;

    for (final monthly in monthlyExpenses) {
      for (final expense in monthly.expenses) {
        if (expense.amount < 0) {
          totalExpenses += expense.amount.abs();
        } else {
          totalIncome += expense.amount;
        }
      }
    }

    final averageMonthlyExpense = totalExpenses / monthCount;
    final averageMonthlyIncome = totalIncome / monthCount;
    final averageNetIncome = averageMonthlyIncome - averageMonthlyExpense;

    // Calculate suggestion based on different scenarios
    double suggestedSaving;
    String reasoning;

    if (averageNetIncome <= 0) {
      suggestedSaving = 0.0;
      reasoning = 'Your expenses exceed your income. Focus on reducing expenses before setting savings goals.';
    } else if (averageNetIncome < 100) {
      suggestedSaving = averageNetIncome * 0.5;
      reasoning = 'Start small with ${(averageNetIncome * 0.5).toStringAsFixed(0)}€/month (50% of surplus).';
    } else if (averageNetIncome < 500) {
      suggestedSaving = averageNetIncome * 0.6;
      reasoning = 'Save ${(averageNetIncome * 0.6).toStringAsFixed(0)}€/month (60% of surplus) for steady progress.';
    } else if (averageNetIncome < 1000) {
      suggestedSaving = averageNetIncome * 0.7;
      reasoning = 'Save ${(averageNetIncome * 0.7).toStringAsFixed(0)}€/month (70% of surplus) - you\'re doing well!';
    } else {
      suggestedSaving = averageNetIncome * 0.8;
      reasoning = 'Save ${(averageNetIncome * 0.8).toStringAsFixed(0)}€/month (80% of surplus) - excellent financial position!';
    }

    return SavingSuggestion(
      suggestedMonthlySaving: suggestedSaving,
      averageMonthlyExpense: averageMonthlyExpense,
      averageMonthlyIncome: averageMonthlyIncome,
      potentialSaving: averageNetIncome,
      reasoning: reasoning,
    );
  }

  // Predefined goal categories
  static const List<String> goalCategories = [
    'Emergency Fund',
    'Vacation',
    'New Car',
    'Home Down Payment',
    'Education',
    'Electronics',
    'Investment',
    'Debt Payoff',
    'Wedding',
    'Retirement',
    'Health & Fitness',
    'Other',
  ];

  // Suggested goal amounts based on category
  static Map<String, List<double>> getSuggestedAmounts() {
    return {
      'Emergency Fund': [1000, 3000, 5000, 10000],
      'Vacation': [500, 1500, 3000, 5000],
      'New Car': [5000, 15000, 25000, 40000],
      'Home Down Payment': [20000, 50000, 100000, 200000],
      'Education': [2000, 5000, 15000, 30000],
      'Electronics': [200, 500, 1000, 2000],
      'Investment': [1000, 5000, 10000, 25000],
      'Debt Payoff': [1000, 5000, 10000, 20000],
      'Wedding': [5000, 15000, 30000, 50000],
      'Retirement': [10000, 50000, 100000, 500000],
      'Health & Fitness': [300, 1000, 3000, 5000],
      'Other': [500, 1000, 5000, 10000],
    };
  }

  // Generate a unique ID for saving goals
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Validate saving goal input
  static String? validateGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
  }) {
    if (name.trim().isEmpty) {
      return 'Goal name cannot be empty';
    }
    
    if (targetAmount <= 0) {
      return 'Target amount must be greater than 0';
    }
    
    if (targetDate.isBefore(DateTime.now())) {
      return 'Target date must be in the future';
    }
    
    return null; // No validation errors
  }
}
