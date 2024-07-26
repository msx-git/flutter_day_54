import 'package:flutter/material.dart';

class CustomZoomButton extends StatelessWidget {
  final void Function() onTap;
  final bool isZoomIn;

  const CustomZoomButton({
    super.key,
    required this.onTap,
    required this.isZoomIn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF13394E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isZoomIn ? Icons.add : Icons.remove,
          color: const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}