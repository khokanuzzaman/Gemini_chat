import 'package:flutter/material.dart';

import '../widgets/add_entry/add_entry_sheet.dart';

/// Kept so every existing caller (Home FAB, empty state, offline banner, chat…)
/// opens the new খরচ | আয় sheet without changes.
Future<void> showManualAddSheet(BuildContext context) =>
    showAddEntrySheet(context);
