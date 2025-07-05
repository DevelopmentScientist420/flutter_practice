import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/expense.dart';

class ExpenseBarChart extends StatelessWidget {
  final List<MonthlyExpense> monthlyExpenses;

  const ExpenseBarChart({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty data case
    if (monthlyExpenses.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last 3 Months Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No expense data available',
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 3 Months Expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxAmount(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String monthName = _getMonthName(groupIndex);
                        return BarTooltipItem(
                          '$monthName\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '\$${rod.toY.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _getBottomTitles,
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: _getYAxisInterval(),
                        getTitlesWidget: _getLeftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _generateBarGroups(),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    if (monthlyExpenses.isEmpty) {
      return [];
    }
    
    return monthlyExpenses.asMap().entries.map((entry) {
      int index = entry.key;
      MonthlyExpense monthlyExpense = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthlyExpense.totalAmount,
            color: _getBarColor(index),
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getBarColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    int index = value.toInt();
    if (index >= 0 && index < monthlyExpenses.length) {
      String monthName = _getMonthName(index);
      return SideTitleWidget(
        meta: meta,
        space: 16,
        child: Text(monthName, style: style),
      );
    }
    return SideTitleWidget(
      meta: meta,
      child: const Text(''),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    
    return SideTitleWidget(
      meta: meta,
      child: Text('\$${value.toInt()}', style: style),
    );
  }

  String _getMonthName(int index) {
    if (index >= monthlyExpenses.length) return '';
    
    DateTime month = monthlyExpenses[index].month;
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month.month - 1];
  }

  double _getMaxAmount() {
    if (monthlyExpenses.isEmpty) return 1000;
    double max = monthlyExpenses
        .map((e) => e.totalAmount)
        .reduce((a, b) => a > b ? a : b);
    return max * 1.2; // Add 20% padding
  }

  double _getYAxisInterval() {
    double max = _getMaxAmount();
    return max / 5; // Show 5 intervals
  }
}
