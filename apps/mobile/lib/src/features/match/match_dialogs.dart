import 'package:flutter/material.dart';

/// Presentation-only match menus. Callbacks remain owned by MatchScreen.
class MatchDialogs {
  const MatchDialogs._();

  static Future<String?> showMoreMenu(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF17120B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Color(0xFFFFC857)),
              title: const Text('Restart match'),
              onTap: () => Navigator.of(sheetContext).pop('restart'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Color(0xFFFFC857)),
              title: const Text('Exit match'),
              onTap: () => Navigator.of(sheetContext).pop('exit'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> confirmRestart(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF17120B),
        title: const Text('Restart this match?'),
        content:
            const Text('The current local match progress will be replaced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('RESTART'),
          ),
        ],
      ),
    );
  }
}
