import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {

  final Widget child;

  const GlassContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),

        child: Container(

          decoration: BoxDecoration(

            color: Colors.white.withValues(
              alpha: .18,
            ),

            borderRadius:
                BorderRadius.circular(25),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: .25,
              ),
            ),

          ),

          child: child,
        ),
      ),
    );
  }
}