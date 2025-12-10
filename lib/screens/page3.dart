import 'package:flutter/material.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person, size: 72),
          SizedBox(height: 12),
          Text('Profil', style: TextStyle(fontSize: 22)),
          SizedBox(height: 12),
          Text('Nom : Ibtissame Aouraghe'),
          SizedBox(height: 6),
          Text('Email : i.aouraghe@gmail.com'),
        ],
      ),
    );
  }
}
