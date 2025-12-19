import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/sign_in_screen.dart';
import 'page1.dart';
import 'page2.dart';
import 'page3.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();

  final List<Widget> _pages = const [
    Page1(),
    Page2(),
    Page3(),
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  String _getUserInitials() {
    final user = _authService.currentUser;
    if (user?.email == null) return '?';
    final email = user!.email!;
    if (email.isEmpty) return '?';
    
    // Try to get first letter of name parts
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  String _getDisplayName() {
    final user = _authService.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Extract name from email (part before @)
    if (user?.email != null) {
      final emailParts = user!.email!.split('@');
      if (emailParts.isNotEmpty) {
        return emailParts[0]
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty 
                ? word[0].toUpperCase() + word.substring(1) 
                : '')
            .join(' ');
      }
    }
    return 'User';
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Sign out from Firebase
              await _authService.signOut();
              
              if (!mounted) return;
              
              // Navigate to sign-in and clear all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('CyberGuard AI')),

      // ------------------------- DRAWER ------------------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_getDisplayName()),
              accountEmail: Text(user?.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _getUserInitials(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.of(context).pop();
                _openSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmLogout();
              },
            ),
          ],
        ),
      ),

      // -------------------- BOTTOM NAV -------------------------
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),








      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
