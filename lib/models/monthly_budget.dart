class MonthlyBudget {
  final double amount;
  final DateTime createdDate;

  MonthlyBudget({
    required this.amount,
    required this.createdDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      amount: json['amount']?.toDouble() ?? 0.0,
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
