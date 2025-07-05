import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const ExpensePieChart({
    super.key,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty data case
    if (categoryData.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(0), // Remove margin since parent will handle spacing
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expenses by Category',
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
                        Icons.pie_chart,
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
                        'Load a CSV file to see expense breakdown',
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
              'Expenses by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0, // Remove spacing to ensure visibility
                      centerSpaceRadius: 30, // Reduced center space
                      sections: _generatePieChartSections(),
                      startDegreeOffset: -90, // Start from top
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Handle touch events if needed
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildHorizontalLegend(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    if (categoryData.isEmpty) {
      return [];
    }
    
    // All data should now be positive from the improved service
    double total = categoryData.values.reduce((a, b) => a + b);
    if (total <= 0) {
      return [];
    }
    
    List<String> types = categoryData.keys.toList();
    
    final sections = types.asMap().entries.map((entry) {
      int index = entry.key;
      String type = entry.value;
      double amount = categoryData[type]!;
      double percentage = (amount / total) * 100;
      
      return PieChartSectionData(
        color: _getColor(index),
        value: amount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '', // Only show percentage if > 5%
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 2,
        ),
      );
    }).toList();
    
    return sections;
  }

  Widget _buildHorizontalLegend() {
    if (categoryData.isEmpty) {
      return const Text(
        'No expense data to display',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      );
    }

    // Create legend items
    List<Widget> legendItems = categoryData.entries.toList().asMap().entries.map((entry) {
      int index = entry.key;
      String type = entry.value.key;
      double amount = entry.value.value;
      
      return Container(
        margin: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getColor(index),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '€${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    // Use Wrap to automatically handle overflow to new lines
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: legendItems,
    );
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF1E88E5), // Blue
      Color(0xFF43A047), // Green  
      Color(0xFFFF9800), // Orange
      Color(0xFF8E24AA), // Purple
      Color(0xFFE53935), // Red
      Color(0xFF00ACC1), // Cyan
      Color(0xFFFFB300), // Amber
      Color(0xFF3949AB), // Indigo
      Color(0xFFAD1457), // Pink
      Color(0xFF546E7A), // Blue Grey
    ];
    return colors[index % colors.length];
  }
}
