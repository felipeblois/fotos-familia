import 'package:flutter/material.dart';

import '../config/app_config.dart';

class DeveloperCreditOverlay extends StatelessWidget {
  const DeveloperCreditOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          right: 10,
          bottom: 6,
          child: IgnorePointer(child: DeveloperCredit()),
        ),
      ],
    );
  }
}

class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.44)
        : Colors.black.withOpacity(0.38);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (brightness == Brightness.dark ? Colors.black : Colors.white)
              .withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            AppConfig.developerCredit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
