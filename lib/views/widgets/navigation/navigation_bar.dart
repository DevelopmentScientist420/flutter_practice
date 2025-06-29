import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                height: 80,
                width: 150,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("TEST BANK", style: TextStyle(fontSize: 24),),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  NavBarItem('Home'),
                  SizedBox(width: 60,),
                  NavBarItem('About'),
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
  const NavBarItem(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 18),);
  }
}