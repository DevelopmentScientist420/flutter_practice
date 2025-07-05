import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Container(
      height: 100,
      width: double.infinity,
      color: isDark ? Colors.grey[850] : Colors.cyan[50],
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Logo/Brand
              SizedBox(
                height: 80,
                width: 250,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "MONEY SAVER", 
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              ),
              
              // Theme toggle
              Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    color: !isDark ? Colors.orange : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: Colors.cyan,
                    inactiveThumbColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.dark_mode,
                    color: isDark ? Colors.cyan : Colors.grey[600],
                    size: 20,
                  ),
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