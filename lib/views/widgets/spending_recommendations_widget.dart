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
            const SizedBox(height: 4),
            Text(
              'AI-powered suggestions to optimize your spending',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
                          ? Colors.orange[600]
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    size: 20,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '€${recommendation.potentialSavings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        '/month',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.actionSuggestion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: €${recommendation.currentMonthlySpend.toStringAsFixed(0)}/mo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Target: ${(recommendation.suggestedReduction * 100).round()}% reduction',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
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
            Colors.green.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings,
            color: Colors.green[700],
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
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[700],
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
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
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
