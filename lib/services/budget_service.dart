import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../models/monthly_budget.dart';

class BudgetService {
  static const String _storageKey = 'monthly_budget';
  static MonthlyBudget? _currentBudget;

  /// Gets the current monthly budget
  static MonthlyBudget? getCurrentBudget() {
    if (_currentBudget == null) {
      _loadBudgetFromStorage();
    }
    return _currentBudget;
  }

  /// Sets a new monthly budget
  static void setBudget(double amount) {
    _currentBudget = MonthlyBudget(
      amount: amount,
      createdDate: DateTime.now(),
    );
    _saveBudgetToStorage();
  }

  /// Calculates budget progress (spent amount vs budget)
  static Map<String, dynamic> getBudgetProgress(double totalExpenses) {
    final budget = getCurrentBudget();
    if (budget == null) {
      return {
        'hasBudget': false,
        'budgetAmount': 0.0,
        'spent': totalExpenses,
        'remaining': 0.0,
        'percentage': 0.0,
        'isOverBudget': false,
      };
    }

    final remaining = budget.amount - totalExpenses;
    final percentage = totalExpenses / budget.amount;
    final isOverBudget = totalExpenses > budget.amount;

    return {
      'hasBudget': true,
      'budgetAmount': budget.amount,
      'spent': totalExpenses,
      'remaining': remaining,
      'percentage': percentage,
      'isOverBudget': isOverBudget,
    };
  }

  /// Clears the current budget
  static void clearBudget() {
    _currentBudget = null;
    _clearBudgetFromStorage();
  }

  /// Saves budget to browser local storage (web only)
  static void _saveBudgetToStorage() {
    if (kIsWeb && _currentBudget != null) {
      try {
        final jsonData = jsonEncode(_currentBudget!.toJson());
        html.window.localStorage[_storageKey] = jsonData;
      } catch (e) {
        print('Error saving budget: $e');
      }
    }
  }

  /// Loads budget from browser local storage (web only)
  static void _loadBudgetFromStorage() {
    if (kIsWeb) {
      try {
        final jsonData = html.window.localStorage[_storageKey];
        if (jsonData != null) {
          final budgetData = jsonDecode(jsonData);
          _currentBudget = MonthlyBudget.fromJson(budgetData);
        }
      } catch (e) {
        print('Error loading budget: $e');
      }
    }
  }

  /// Clears budget from browser local storage (web only)
  static void _clearBudgetFromStorage() {
    if (kIsWeb) {
      try {
        html.window.localStorage.remove(_storageKey);
      } catch (e) {
        print('Error clearing budget: $e');
      }
    }
  }
}
