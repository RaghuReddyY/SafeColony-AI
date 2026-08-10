import 'package:flutter/material.dart';

class ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<ActionTile> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width > 900;

    return MouseRegion(
      onEnter: (_) {
        if (desktop) {
          setState(() => hovering = true);
        }
      },
      onExit: (_) {
        if (desktop) {
          setState(() => hovering = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        transform: Matrix4.identity()
          ..translate(
            0.0,
            hovering ? -3.0 : 0.0,
          ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: hovering
                ? widget.color.withOpacity(.35)
                : Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                hovering ? .12 : .05,
              ),
              blurRadius: hovering ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            child: Row(
              children: [

                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(.12),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}