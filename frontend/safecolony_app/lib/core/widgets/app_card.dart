import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;

  final EdgeInsets padding;

  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x11000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: card,
    );
  }
}