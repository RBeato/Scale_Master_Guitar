import 'package:flutter/material.dart';

import '../../../../constants/styles.dart';
import 'drawer_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color(0xFF1C2128),
        elevation: 20.0,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 20,
                  color: settingsTextColor,
                ),
              ),
            ),
            const DrawerPage(),
          ],
        ));
  }
}
