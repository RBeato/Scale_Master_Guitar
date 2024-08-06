import 'package:flutter/material.dart';

class Utils {
  /// Shows a bottom sheet with the provided widget content
  static void showSheet(BuildContext context, WidgetBuilder builder) {
    showModalBottomSheet(
      context: context,
      builder: builder,
      isScrollControlled: true,
    );
  }

  /// Shows a snackbar with the provided message
  static void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
