import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../../features/settings/settings_screen.dart';

class GlobalSettingsButton extends StatelessWidget {
  const GlobalSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(buildAppRoute(const SettingsScreen()));
      },
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
    );
  }
}
