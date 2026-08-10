import 'package:flutter/material.dart';

class AIInsightCard extends StatelessWidget {
  final String message;

  const AIInsightCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xffEEF4FF),
            Color(0xffF8FAFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.indigo.shade100,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth > 700;

            if (desktop) {
              return Row(
                children: [
                  _buildAvatar(),

                  const SizedBox(width: 24),

                  Expanded(
                    child: _buildContent(context),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildAvatar(),

                const SizedBox(height: 18),

                _buildContent(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff2563EB),
            Color(0xff4F46E5),
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.indigo,
            ),

            const SizedBox(width: 8),

            Text(
              "AI Security Assistant",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Row(
            children: [

              Icon(
                Icons.lightbulb,
                color: Colors.orange,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Recommendation: Monitor today's visitors carefully and verify every QR before allowing entry.",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}