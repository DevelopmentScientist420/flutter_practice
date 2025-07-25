import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/expense.dart';
import '../../services/recommendation_service.dart';

class SpendingRecommendationsWidget extends StatefulWidget {
  final List<Expense> expenses;
  final List<MonthlyExpense> monthlyExpenses;

  const SpendingRecommendationsWidget({
    super.key,
    required this.expenses,
    required this.monthlyExpenses,
  });

  @override
  State<SpendingRecommendationsWidget> createState() => _SpendingRecommendationsWidgetState();
}

class _SpendingRecommendationsWidgetState extends State<SpendingRecommendationsWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _carouselTimer;
  int _currentRecommendationIndex = 0;
  List<SpendingRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _generateRecommendations();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SpendingRecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expenses != oldWidget.expenses || 
        widget.monthlyExpenses != oldWidget.monthlyExpenses) {
      _generateRecommendations();
    }
  }

  // Public method to refresh recommendations when budget changes
  void refreshRecommendations() {
    _generateRecommendations();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateRecommendations() {
    _recommendations = RecommendationService.generateRecommendations(
      widget.expenses,
      widget.monthlyExpenses,
    );
    
    if (_recommendations.isNotEmpty) {
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    if (_recommendations.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() {
            _currentRecommendationIndex = (_currentRecommendationIndex + 1) % _recommendations.length;
          });
          _pageController.animateToPage(
            _currentRecommendationIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recommendations.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Spending Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Great job! Your spending looks optimized.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Load more transaction data to get personalized recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
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
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Spending Recommendations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),              Text(
                'AI-powered suggestions to optimize your spending',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 185,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _recommendations.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentRecommendationIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildRecommendationCard(_recommendations[index]),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Page indicators
            if (_recommendations.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _recommendations.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentRecommendationIndex
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange[400]
                              : Colors.orange[600]
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[300],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Total savings potential
            _buildTotalSavingsPotential(_recommendations),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(SpendingRecommendation recommendation) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    final typeIcon = _getTypeIcon(recommendation.type);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: priorityColor.withValues(alpha: 0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: minimize height
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced padding
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    size: 16, // Reduced size
                    color: priorityColor,
                  ),
                ),
                const SizedBox(width: 10), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15, // Reduced size
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        recommendation.description,
                        style: TextStyle(
                          fontSize: 12, // Reduced size
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                        maxLines: 1, // Reduced to 1 line
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[900]!.withValues(alpha: 0.4)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 9, // Reduced size
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[300]
                              : Colors.green[700],
                        ),
                      ),
                      Text(
                        '€${recommendation.potentialSavings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14, // Reduced size
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[300]
                              : Colors.green[700],
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 8, // Reduced size
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[400]
                              : Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[900]!.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[400]!.withValues(alpha: 0.4)
                      : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 14, // Reduced size
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[400]
                        : Colors.blue[600],
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  Expanded(
                    child: Text(
                      recommendation.actionSuggestion,
                      style: TextStyle(
                        fontSize: 11, // Reduced size
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child:                  Text(
                    'Current: €${recommendation.currentMonthlySpend.toStringAsFixed(0)}/mo',
                    style: TextStyle(
                      fontSize: 10, // Reduced size
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Flexible(
                  child:                  Text(
                    'Target: ${(recommendation.suggestedReduction * 100).round()}% reduction',
                    style: TextStyle(
                      fontSize: 10, // Reduced size
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSavingsPotential(List<SpendingRecommendation> recommendations) {
    final totalSavings = recommendations.fold<double>(
      0.0,
      (sum, rec) => sum + rec.potentialSavings,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? Colors.green[900]!.withValues(alpha: 0.4)
                : Colors.green.withValues(alpha: 0.1),
            Theme.of(context).brightness == Brightness.dark
                ? Colors.blue[900]!.withValues(alpha: 0.4)
                : Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[400]!.withValues(alpha: 0.5)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[400]
                : Colors.green[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Savings Potential',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Following all recommendations could save you €${totalSavings.toStringAsFixed(0)} per month',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[800]
                  : Colors.green[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '€${(totalSavings * 12).toStringAsFixed(0)}/year',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (priority) {
      case 1:
        return isDark ? Colors.red[400]! : Colors.red[600]!;
      case 2:
        return isDark ? Colors.orange[400]! : Colors.orange[600]!;
      case 3:
        return isDark ? Colors.blue[400]! : Colors.blue[600]!;
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  IconData _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.highSpend:
        return Icons.trending_up;
      case RecommendationType.frequency:
        return Icons.repeat;
      case RecommendationType.trending:
        return Icons.show_chart;
      case RecommendationType.opportunity:
        return Icons.lightbulb_outline;
    }
  }
}
