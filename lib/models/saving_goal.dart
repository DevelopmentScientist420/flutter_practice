class SavingGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdDate;
  final String category;
  final String? description;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdDate,
    required this.category,
    this.description,
  });

  SavingGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdDate,
    String? category,
    String? description,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdDate: createdDate ?? this.createdDate,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  double get progressPercentage => 
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  double get requiredMonthlySaving {
    final monthsRemaining = daysRemaining / 30.0;
    if (monthsRemaining <= 0) return remainingAmount;
    return remainingAmount / monthsRemaining;
  }

  bool get isAchieved => currentAmount >= targetAmount;

  @override
  String toString() {
    return 'SavingGoal(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, targetDate: $targetDate, category: $category)';
  }
}

class SavingSuggestion {
  final double suggestedMonthlySaving;
  final double averageMonthlyExpense;
  final double averageMonthlyIncome;
  final double potentialSaving;
  final String reasoning;

  SavingSuggestion({
    required this.suggestedMonthlySaving,
    required this.averageMonthlyExpense,
    required this.averageMonthlyIncome,
    required this.potentialSaving,
    required this.reasoning,
  });
}
