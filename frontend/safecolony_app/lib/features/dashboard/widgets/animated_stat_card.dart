import 'package:flutter/material.dart';

class AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<AnimatedStatCard> createState() =>
      _AnimatedStatCardState();
}

class _AnimatedStatCardState
    extends State<AnimatedStatCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool desktop = width > 900;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        transform: Matrix4.translationValues(
          0,
          hover ? -6 : 0,
          0,
        ),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          gradient: LinearGradient(
            colors: [
              widget.color,
              widget.color.withValues(alpha: .80),
            ],
          ),

          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .25),
              blurRadius: hover ? 22 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Row(
                children: [

                  Container(
                    padding:
                        const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: .18,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),

                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: desktop ? 24 : 20,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: .18,
                      ),
                      borderRadius:
                          BorderRadius.circular(30),
                    ),

                    child: const Text(
                      "+12%",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              Text(
                widget.value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 40 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: desktop ? 17 : 15,
                ),
              ),

              Row(
                children: [

                  const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      "Compared to yesterday",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize:
                            desktop ? 12 : 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}