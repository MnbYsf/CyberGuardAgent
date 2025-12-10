import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Paramètres de l\'application',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.palette),
              title: Text('Thème (non implémenté)'),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('À propos'),
            ),
          ],
        ),
      ),
    );
  }
}
