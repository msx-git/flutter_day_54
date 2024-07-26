import 'package:flutter/material.dart';

class ShowErrorDialog extends StatelessWidget {
  final String errorText;

  const ShowErrorDialog({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(errorText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}