import 'package:flutter/material.dart';

class GuardHeroBanner extends StatelessWidget {
  final String greeting;
  final String guardName;
  final String colonyStatus;

  final int expectedVisitors;
  final int checkedInVisitors;
  final int deliveries;

  const GuardHeroBanner({
    super.key,
    required this.greeting,
    required this.guardName,
    required this.colonyStatus,
    required this.expectedVisitors,
    required this.checkedInVisitors,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth > 850;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xff2563EB),
                Color(0xff4F46E5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: desktop
              ? _desktopLayout()
              : _mobileLayout(),
        );
      },
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [

        const CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.security,
            size: 42,
            color: Color(0xff2563EB),
          ),
        ),

        const SizedBox(width: 24),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Welcome back, $guardName",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius:
                      BorderRadius.circular(25),
                ),
                child: Text(
                  "🟢 Colony Status : $colonyStatus",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Row(
          children: [

            _Stat(
              value: expectedVisitors.toString(),
              label: "Visitors",
            ),

            const SizedBox(width: 32),

            _Stat(
              value: checkedInVisitors.toString(),
              label: "Checked In",
            ),

            const SizedBox(width: 32),

            _Stat(
              value: deliveries.toString(),
              label: "Deliveries",
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.security,
                color: Color(0xff2563EB),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    guardName,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            "🟢 $colonyStatus",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [

            Expanded(
              child: _Stat(
                value:
                    expectedVisitors.toString(),
                label: "Visitors",
              ),
            ),

            Expanded(
              child: _Stat(
                value:
                    checkedInVisitors.toString(),
                label: "Inside",
              ),
            ),

            Expanded(
              child: _Stat(
                value: deliveries.toString(),
                label: "Delivery",
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}