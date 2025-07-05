import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.cyan),
              SizedBox(width: 8),
              Text('About Money Saver'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Money Saver - Personal Finance Manager',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildFeatureItem('📊', 'Expense Analysis & Visualization'),
                _buildFeatureItem('💰', 'Budget Management & Tracking'),
                _buildFeatureItem('🎯', 'Savings Goals & Progress'),
                _buildFeatureItem('🔔', 'Smart Spending Alerts'),
                _buildFeatureItem('💡', 'AI-Powered Recommendations'),
                _buildFeatureItem('🤖', 'Financial Assistant Chatbot'),
                _buildFeatureItem('📈', 'Monthly & Category Breakdowns'),
                const SizedBox(height: 12),
                const Text(
                  'Upload your bank CSV file to get started with personalized financial insights!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      height: 100,
      width: double.infinity,
      color: isDark ? Colors.grey[850] : Colors.cyan[50],
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 24.0, 
        vertical: 12.0
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Logo/Brand - Responsive
              Expanded(
                flex: isMobile ? 3 : 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "MONEY SAVER", 
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              ),
              
              // Action buttons - More compact on mobile
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Information icon
                  IconButton(
                    onPressed: () => _showInfoDialog(context),
                    icon: Icon(
                      Icons.info_outline,
                      color: isDark ? Colors.cyan : Colors.grey[700],
                      size: isMobile ? 20 : 24,
                    ),
                    tooltip: 'App Information',
                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 40,
                      minHeight: isMobile ? 32 : 40,
                    ),
                  ),
                  
                  // Theme toggle - Compact on mobile
                  if (!isMobile) ...[
                    Icon(
                      Icons.light_mode,
                      color: !isDark ? Colors.orange : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: Colors.cyan,
                    inactiveThumbColor: Colors.orange,
                    materialTapTargetSize: isMobile 
                        ? MaterialTapTargetSize.shrinkWrap 
                        : MaterialTapTargetSize.padded,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.dark_mode,
                      color: isDark ? Colors.cyan : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  
  const NavBarItem(this.title, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 18,
          color: onTap != null ? Colors.blue[700] : Colors.grey[800],
        ),
      ),
    );
  }
}