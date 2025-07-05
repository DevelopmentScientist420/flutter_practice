import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.cyan[50],
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                height: 80,
                width: 250,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("MONEY SAVER", style: TextStyle(fontSize: 24),),
                ),
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