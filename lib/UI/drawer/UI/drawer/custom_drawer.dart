import 'package:flutter/material.dart';

import '../../../../constants/styles.dart';
import 'drawer_page.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Colors.black87,
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
