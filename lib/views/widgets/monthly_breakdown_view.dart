import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import 'charts/expense_line_chart.dart';

class MonthlyBreakdownView extends StatelessWidget {
  final List<MonthlyExpense> monthlyExpenses;

  const MonthlyBreakdownView({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyExpenses.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(0), // Remove margin since parent will handle spacing
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Breakdown (Last 3 Months)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No monthly data available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Load a CSV file to see your monthly expenses',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(0), // Remove margin since parent will handle spacing
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Breakdown (Last 3 Months)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add the line chart
            SizedBox(
              height: 280,
              child: ExpenseLineChart(monthlyExpenses: monthlyExpenses),
            ),
            const SizedBox(height: 16),
            ..._buildMonthlyItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthlyItems() {
    final DateFormat monthFormat = DateFormat('MMMM yyyy');
    
    // Sort by month (most recent first for better UX)
    final sortedExpenses = List<MonthlyExpense>.from(monthlyExpenses)
      ..sort((a, b) => b.month.compareTo(a.month));

    return sortedExpenses.map((monthly) {
      // Calculate expense and income separately
      double totalExpenses = 0.0;
      double totalIncome = 0.0;
      int expenseCount = 0;
      int incomeCount = 0;

      for (final expense in monthly.expenses) {
        if (expense.amount < 0) {
          totalExpenses += expense.amount.abs();
          expenseCount++;
        } else {
          totalIncome += expense.amount;
          incomeCount++;
        }
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          title: Text(
            monthFormat.format(monthly.month),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Net: €${(totalIncome - totalExpenses).toStringAsFixed(2)} | '
            '${monthly.expenses.length} transactions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryColumn(
                        'Expenses',
                        '€${totalExpenses.toStringAsFixed(2)}',
                        '$expenseCount transactions',
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                      _buildSummaryColumn(
                        'Income',
                        '€${totalIncome.toStringAsFixed(2)}',
                        '$incomeCount transactions',
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                      _buildSummaryColumn(
                        'Net',
                        '€${(totalIncome - totalExpenses).toStringAsFixed(2)}',
                        '${monthly.expenses.length} total',
                        (totalIncome - totalExpenses) >= 0 ? Colors.green : Colors.red,
                        Icons.balance,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Top expenses (if we have expense data)
                  if (expenseCount > 0) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Top Expenses:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildTopExpenses(monthly.expenses),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryColumn(String title, String amount, String subtitle, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTopExpenses(List<Expense> expenses) {
    // Get expenses only (negative amounts) and sort by amount (highest first)
    final expensesList = expenses
        .where((e) => e.amount < 0)
        .toList()
      ..sort((a, b) => a.amount.compareTo(b.amount)); // Most negative first

    // Take top 3 expenses
    final topExpenses = expensesList.take(3).toList();

    if (topExpenses.isEmpty) {
      return [
        const Text(
          'No expenses found for this month',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ];
    }

    return topExpenses.map((expense) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                expense.description,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '€${expense.amount.abs().toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
