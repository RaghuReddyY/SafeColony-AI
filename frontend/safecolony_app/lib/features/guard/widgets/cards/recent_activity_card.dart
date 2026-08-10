import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final String icon;
  final String title;
  final String time;

  const RecentActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
  });

  IconData _icon() {
    switch (icon.toLowerCase()) {
      case "login":
        return Icons.login_rounded;

      case "logout":
        return Icons.logout_rounded;

      case "verified":
        return Icons.verified_rounded;

      case "delivery":
        return Icons.inventory_2_rounded;

      case "visitor":
        return Icons.people_alt_rounded;

      case "scan":
        return Icons.qr_code_scanner_rounded;

      default:
        return Icons.history_rounded;
    }
  }

  Color _color() {
    switch (icon.toLowerCase()) {
      case "login":
        return Colors.green;

      case "logout":
        return Colors.red;

      case "verified":
        return Colors.blue;

      case "delivery":
        return Colors.orange;

      case "visitor":
        return Colors.indigo;

      case "scan":
        return Colors.deepPurple;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Card(
      elevation: .6,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            children: [

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon(),
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [

                        Icon(
                          Icons.schedule,
                          color:
                              Colors.grey.shade600,
                          size: 15,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}