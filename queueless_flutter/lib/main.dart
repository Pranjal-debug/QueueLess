import 'package:flutter/material.dart';

import 'client.dart';
import 'design_system/app_theme.dart';
import 'screens/customer_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/staff_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QueueLess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final Widget _customerTab;
  Widget? _staffTab;

  @override
  void initState() {
    super.initState();
    _customerTab = const CustomerScreen();
  }

  void _selectTab(int index) {
    if (index == 1 && _staffTab == null) {
      // Keep protected staff content out of the tree until the user explicitly
      // opens Staff. SignInScreen remains the authorization gate.
      _staffTab = const SignInScreen(child: StaffScreen());
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _customerTab,
          _staffTab ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Join queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Staff',
          ),
        ],
      ),
    );
  }
}
