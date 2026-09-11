import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/claims_screen.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;

  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  Widget buildItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
  ) {
    final bool selected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: selected ? Colors.blue : Colors.black54),

      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),

      selected: selected,

      onTap: () => onItemSelected(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: Color(0xfff5f5f5)),

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 35,
              child: Icon(Icons.admin_panel_settings),
            ),

            const SizedBox(height: 15),

            const Text(
              "Expense Admin",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 40),

            buildItem(context, 0, Icons.dashboard, "Dashboard"),

            buildItem(context, 1, Icons.receipt_long, "Claims"),
          ],
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [DashboardScreen(), ClaimsScreen()];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });

                  Navigator.pop(context);
                },
              ),
            ),

      appBar: AppBar(title: const Text("Expense Admin")),

      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),

          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
