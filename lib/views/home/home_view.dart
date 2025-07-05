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
  // Constants
  static const double _maxContentWidth = 1200.0;
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _fabIconSize = 28.0;
  static const double _fabElevation = 8.0;

  // State variables
  bool _isChatbotOpen = false;
  String? _financialContext;

  // Methods
  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  void _onFinancialDataChanged(Map<String, dynamic> data) {
    if (data.isEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainContent(),
          _buildChatbotOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        NavigationBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxContentWidth),
                    child: ExpenseAnalysisWidget(
                      onDataChanged: _onFinancialDataChanged,
                    ),
                  ),
                ),
                const Footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatbotOverlay() {
    return ChatbotWidget(
      isVisible: _isChatbotOpen,
      onClose: _toggleChatbot,
      financialContext: _financialContext,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _toggleChatbot,
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.white,
      elevation: _fabElevation,
      child: AnimatedSwitcher(
        duration: _animationDuration,
        child: Icon(
          _isChatbotOpen ? Icons.close : Icons.chat,
          key: ValueKey(_isChatbotOpen),
          size: _fabIconSize,
        ),
      ),
    );
  }
}