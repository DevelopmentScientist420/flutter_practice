import 'dart:convert';
import 'package:http/http.dart' as http;
import 'budget_service.dart';

class OllamaService {
  static const String _baseUrl = 'http://localhost:11434';
  static const String _defaultModel = 'phi3:mini';
  
  /// Sends a message to Ollama and returns the response
  static Future<String> sendMessage(String message, {String? context}) async {
    try {
      final prompt = _buildFinancialPrompt(message, context);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
            'max_tokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response']?.toString().trim() ?? 
               'Sorry, I couldn\'t generate a response.';
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('No host specified')) {
        return 'I\'m having trouble connecting to my AI brain. Please make sure Ollama is running on localhost:11434.\n\nIn the meantime, I can still help with basic financial questions!';
      }
      return 'Sorry, I encountered an error: ${e.toString()}. Let me try to help with a basic response instead.';
    }
  }

  /// Builds a financial-focused prompt for the LLM
  static String _buildFinancialPrompt(String userMessage, String? context) {
    final systemPrompt = '''You are a helpful financial assistant chatbot for a personal finance app. Your role is to:

1. Help users understand their spending patterns
2. Provide budgeting advice and tips
3. Suggest ways to save money
4. Explain financial concepts in simple terms
5. Encourage good financial habits

Keep responses:
- Concise (under 150 words)
- Practical and actionable
- Friendly and encouraging
- Focused on personal finance

${context != null ? 'User Context: $context\n' : ''}
User Question: $userMessage

Response:''';

    return systemPrompt;
  }

  /// Checks if Ollama is available
  static Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Gets available models from Ollama
  static Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final models = jsonResponse['models'] as List?;
        
        return models?.map((model) => model['name'].toString()).toList() ?? [];
      }
    } catch (e) {
      // Return empty list if can't fetch models
    }
    
    return [];
  }

  /// Builds context from user's financial data
  static String buildFinancialContext({
    double? totalExpenses,
    double? totalIncome,
    double? netAmount,
    Map<String, double>? categoryBreakdown,
    List<String>? recentTransactions,
  }) {
    final context = StringBuffer();
    
    if (totalExpenses != null) {
      context.writeln('Total Expenses: €${totalExpenses.toStringAsFixed(2)}');
    }
    
    if (totalIncome != null) {
      context.writeln('Total Income: €${totalIncome.toStringAsFixed(2)}');
    }
    
    if (netAmount != null) {
      context.writeln('Net Amount: €${netAmount.toStringAsFixed(2)}');
    }

    // Add budget information
    final budget = BudgetService.getCurrentBudget();
    if (budget != null && totalExpenses != null) {
      final budgetProgress = BudgetService.getBudgetProgress(totalExpenses);
      final percentage = budgetProgress['percentage'] as double;
      final remaining = budgetProgress['remaining'] as double;
      final isOverBudget = budgetProgress['isOverBudget'] as bool;
      
      context.writeln('Monthly Budget: €${budget.amount.toStringAsFixed(2)}');
      context.writeln('Budget Usage: ${(percentage * 100).toStringAsFixed(1)}%');
      if (isOverBudget) {
        context.writeln('Budget Status: OVER BUDGET by €${(-remaining).toStringAsFixed(2)}');
      } else {
        context.writeln('Budget Remaining: €${remaining.toStringAsFixed(2)}');
      }
    }
    
    if (categoryBreakdown != null && categoryBreakdown.isNotEmpty) {
      context.writeln('Spending by category:');
      categoryBreakdown.entries.take(5).forEach((entry) {
        context.writeln('- ${entry.key}: €${entry.value.toStringAsFixed(2)}');
      });
    }
    
    if (recentTransactions != null && recentTransactions.isNotEmpty) {
      context.writeln('Recent transactions: ${recentTransactions.take(3).join(', ')}');
    }
    
    return context.toString();
  }
}
