// lib/core/widgets/aether_card.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent card container used across all feature sections.
class AetherCard extends StatelessWidget {
  const AetherCard({
    required this.child,
    super.key,
    this.accentColor,
    this.padding,
  });

  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.3) ?? AppTheme.borderSubtle,
        ),
        boxShadow: accentColor != null
            ? <BoxShadow>[
                BoxShadow(
                  color: accentColor!.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }
}

/// Section header with optional accent line.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    super.key,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accentColor,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Pulsing status dot indicator.
class StatusDot extends StatefulWidget {
  const StatusDot({
    required this.color,
    super.key,
    this.size = 8,
  });

  final Color color;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pulse.value),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.color.withValues(alpha: _pulse.value * 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
