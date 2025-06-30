import 'package:flutter/material.dart' hide NavigationBar;
import 'package:bank_app/views/widgets/navigation/navigation_bar.dart';
import 'package:bank_app/views/widgets/posts/posts_list.dart';
import 'package:bank_app/views/widgets/footer/footer.dart';

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
                          // Header section
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  'Latest Posts',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Discover the latest articles and insights from our community',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Posts list with constrained height
                          SizedBox(
                            height: MediaQuery.of(context).size.height - 300, // Adjust based on header/nav height
                            child: const PostsList(),
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
    );
  }
}