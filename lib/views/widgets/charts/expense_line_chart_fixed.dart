import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/expense.dart';

class ExpenseLineChart extends StatefulWidget {
  final List<MonthlyExpense> monthlyExpenses;

  const ExpenseLineChart({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  State<ExpenseLineChart> createState() => _ExpenseLineChartState();
}

class _ExpenseLineChartState extends State<ExpenseLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyExpenses.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.all(0),
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'No spending data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    // Sort monthly expenses by date
    final sortedExpenses = List<MonthlyExpense>.from(widget.monthlyExpenses)
      ..sort((a, b) => a.month.compareTo(b.month));

    // Create data points for the line chart
    final spots = <FlSpot>[];
    final monthLabels = <String>[];
    
    for (int i = 0; i < sortedExpenses.length; i++) {
      final expense = sortedExpenses[i];
      
      // Calculate total expenses (only negative amounts, converted to positive)
      double totalExpenses = 0.0;
      for (final exp in expense.expenses) {
        if (exp.amount < 0) {
          totalExpenses += exp.amount.abs();
        }
      }
      
      spots.add(FlSpot(i.toDouble(), totalExpenses));
      monthLabels.add(DateFormat('MMM').format(expense.month));
    }

    // Calculate better Y-axis bounds
    if (spots.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.all(0),
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'No spending data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // Add some padding to the Y-axis (10% on each side)
    final yRange = maxY - minY;
    final paddedMinY = (minY - yRange * 0.1).clamp(0.0, double.infinity);
    final paddedMaxY = maxY + yRange * 0.1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (paddedMaxY - paddedMinY) / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
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
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= 0 && value.toInt() < monthLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    monthLabels[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (paddedMaxY - paddedMinY) / 4,
                            reservedSize: 45,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value >= 1000) {
                                return Text(
                                  '€${(value / 1000).toStringAsFixed(1)}k',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                );
                              } else {
                                return Text(
                                  '€${value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      minX: 0,
                      maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 2,
                      minY: paddedMinY,
                      maxY: paddedMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots.map((spot) => FlSpot(
                            spot.x,
                            spot.y * _animation.value,
                          )).toList(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withValues(alpha: 0.8),
                              Colors.blue.withValues(alpha: 0.8),
                            ],
                          ),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: Colors.cyan,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withValues(alpha: 0.15),
                                Colors.cyan.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.grey[800]!,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final flSpot = barSpot;
                              final monthIndex = flSpot.x.toInt();
                              if (monthIndex >= 0 && monthIndex < sortedExpenses.length) {
                                final expense = sortedExpenses[monthIndex];
                                
                                // Calculate total expenses for tooltip
                                double totalExpenses = 0.0;
                                for (final exp in expense.expenses) {
                                  if (exp.amount < 0) {
                                    totalExpenses += exp.amount.abs();
                                  }
                                }
                                
                                return LineTooltipItem(
                                  '${DateFormat('MMM yyyy').format(expense.month)}\n€${totalExpenses.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
