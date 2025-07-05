import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_app/bank_app.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Money Saver',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeView(),
            },
          );
        },
      ),
    );
  }
}