import 'package:flutter/material.dart' hide NavigationBar;
import 'package:bank_app/views/widgets/navigation/navigation_bar.dart';
import 'package:bank_app/views/widgets/footer/footer.dart';
import 'package:bank_app/views/widgets/expense_analysis_widget.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
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
                          const ExpenseAnalysisWidget(),
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
    );
  }
}