import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/expense.dart';
import '../../services/alert_service.dart';

class SpendingAlertsWidget extends StatefulWidget {
  final List<Expense> expenses;
  final List<MonthlyExpense> monthlyExpenses;

  const SpendingAlertsWidget({
    super.key,
    required this.expenses,
    required this.monthlyExpenses,
  });

  @override
  State<SpendingAlertsWidget> createState() => _SpendingAlertsWidgetState();
}

class _SpendingAlertsWidgetState extends State<SpendingAlertsWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _carouselTimer;
  int _currentAlertIndex = 0;
  List<SpendingAlert> _alerts = [];

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
    
    _generateAlerts();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SpendingAlertsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expenses != oldWidget.expenses || 
        widget.monthlyExpenses != oldWidget.monthlyExpenses) {
      _generateAlerts();
    }
  }

  // Public method to refresh alerts when budget changes
  void refreshAlerts() {
    _generateAlerts();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateAlerts() {
    _alerts = AlertService.generateAlerts(
      widget.expenses,
      widget.monthlyExpenses,
    );
    
    if (_alerts.isNotEmpty && _alerts.length > 1) {
      _startCarousel();
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    if (_alerts.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {
            _currentAlertIndex = (_currentAlertIndex + 1) % _alerts.length;
          });
          _pageController.animateToPage(
            _currentAlertIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alerts.isEmpty) {
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
                  Icon(Icons.notifications_outlined, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Spending Alerts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.green[900]!.withValues(alpha: 0.3)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green[400]!.withValues(alpha: 0.5)
                        : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 32,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.green[400]
                            : Colors.green[600],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All good! No alerts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.green[300]
                                  : Colors.green[700],
                            ),
                          ),
                          Text(
                            'Your spending is within normal limits',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.green[400]
                                  : Colors.green[600],
                            ),
                          ),
                        ],
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
                Icon(_getAlertIcon(_alerts.first.type), color: _getAlertColor(_alerts.first.type), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Spending Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAlertColor(_alerts.first.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getAlertColor(_alerts.first.type).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_alerts.length} alert${_alerts.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getAlertColor(_alerts.first.type),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),              Text(
                'Smart monitoring of your spending patterns',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _alerts.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentAlertIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAlertCard(_alerts[index]),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Page indicators
            if (_alerts.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _alerts.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentAlertIndex
                          ? _getAlertColor(_alerts.first.type)
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SpendingAlert alert) {
    final alertColor = _getAlertColor(alert.type);
    final alertIcon = _getAlertIcon(alert.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important: minimize height
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Reduced padding
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  alertIcon,
                  size: 14, // Reduced size
                  color: alertColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Reduced size
                    color: alertColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getAlertTypeText(alert.type),
                  style: TextStyle(
                    fontSize: 9, // Reduced size
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Reduced spacing
          Flexible( // Use Flexible instead of fixed space
            child:            Text(
              alert.message,
              style: TextStyle(
                fontSize: 12, // Reduced size
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (alert.actionSuggestion != null) ...[
            const SizedBox(height: 4), // Reduced spacing
            Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[900]!.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[400]!.withValues(alpha: 0.4)
                      : Colors.blue.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 12, // Reduced size
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[400]
                        : Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.actionSuggestion!,
                      style: TextStyle(
                        fontSize: 10, // Reduced size
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (alert.threshold != null && alert.currentValue != null) ...[
            const SizedBox(height: 4), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: €${alert.currentValue!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 9, // Reduced size
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                if (alert.threshold! > 0)
                  Text(
                    'Budget: €${alert.threshold!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 9, // Reduced size
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getAlertColor(AlertType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (type) {
      case AlertType.danger:
        return isDark ? Colors.red[400]! : Colors.red[600]!;
      case AlertType.warning:
        return isDark ? Colors.orange[400]! : Colors.orange[600]!;
      case AlertType.info:
        return isDark ? Colors.blue[400]! : Colors.blue[600]!;
      case AlertType.success:
        return isDark ? Colors.green[400]! : Colors.green[600]!;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.danger:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_outlined;
      case AlertType.info:
        return Icons.info_outlined;
      case AlertType.success:
        return Icons.check_circle_outline;
    }
  }

  String _getAlertTypeText(AlertType type) {
    switch (type) {
      case AlertType.danger:
        return 'URGENT';
      case AlertType.warning:
        return 'WARNING';
      case AlertType.info:
        return 'INFO';
      case AlertType.success:
        return 'GOOD';
    }
  }
}
