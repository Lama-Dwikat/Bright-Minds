
import 'package:flutter/material.dart';
import'package:bright_minds/theme/theme.dart';
import 'package:bright_minds/screens/homePage.dart';

class navItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;

  const navItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
