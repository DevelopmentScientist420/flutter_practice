import 'package:flutter/material.dart' hide NavigationBar;
import 'package:bank_app/views/widgets/navigation/navigation_bar.dart';
import 'package:bank_app/views/widgets/footer/footer.dart';
import 'package:bank_app/views/widgets/expense_analysis_widget.dart';
import 'package:bank_app/views/widgets/chatbot_widget.dart';
import 'package:bank_app/services/ollama_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isChatbotOpen = false;
  String? _financialContext;

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  void _onFinancialDataChanged(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      final context = OllamaService.buildFinancialContext(
        totalExpenses: data['totalExpenses']?.toDouble(),
        totalIncome: data['totalIncome']?.toDouble(),
        netAmount: data['netAmount']?.toDouble(),
        categoryBreakdown: data['categoryBreakdown']?.cast<String, double>(),
        recentTransactions: data['recentTransactions']?.cast<String>(),
      );
      
      setState(() {
        _financialContext = context;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              NavigationBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            children: [
                              // Expense Analysis Widget
                              ExpenseAnalysisWidget(
                                onDataChanged: _onFinancialDataChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer
                      const Footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Chatbot widget overlay
          ChatbotWidget(
            isVisible: _isChatbotOpen,
            onClose: _toggleChatbot,
            financialContext: _financialContext,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChatbot,
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        elevation: 8,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isChatbotOpen ? Icons.close : Icons.chat,
            key: ValueKey(_isChatbotOpen),
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}