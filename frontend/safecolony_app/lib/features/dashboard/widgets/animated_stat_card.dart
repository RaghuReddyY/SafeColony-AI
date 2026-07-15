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

    return MouseRegion(

      onEnter: (_) => setState(() => hover = true),

      onExit: (_) => setState(() => hover = false),

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 250),

        curve: Curves.easeOut,

        transform: Matrix4.identity()
          ..translate(
            0.0,
            hover ? -8.0 : 0.0,
          ),

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(28),

          gradient: LinearGradient(

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [

              widget.color,

              widget.color.withValues(
                alpha: .75,
              ),
            ],
          ),

          boxShadow: [

            BoxShadow(

              color: widget.color.withValues(
                alpha: .35,
              ),

              blurRadius: hover ? 30 : 18,

              offset: const Offset(
                0,
                14,
              ),
            ),
          ],
        ),

        child: Padding(

          padding: const EdgeInsets.all(22),

          child: Column(

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
                        alpha: .20,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),

                    child: Icon(
                      widget.icon,
                      color: Colors.white,
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
                          BorderRadius.circular(
                        25,
                      ),
                    ),

                    child: const Text(

                      "+12%",

                      style: TextStyle(

                        color: Colors.white,

                        fontWeight:
                            FontWeight.bold,

                        fontSize: 12,
                      ),
                    ),
                  )
                ],
              ),

              const Spacer(),

              Text(

                widget.value,

                style: const TextStyle(

                  color: Colors.white,

                  fontSize: 42,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(

                widget.title,

                style: const TextStyle(

                  color: Colors.white70,

                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 12),

              Row(

                children: const [

                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 18,
                  ),

                  SizedBox(width: 6),

                  Text(

                    "Compared to yesterday",

                    style: TextStyle(

                      color: Colors.white70,

                      fontSize: 12,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}