import 'package:flutter/material.dart';

class EcoColors {
  static const primary = Color(0xFF67C587);
  static const secondary = Color(0xFF2F6B4F);
  static const accent = Color(0xFFF5C84C);
  static const background = Color(0xFFF9FAF7);
  static const text = Color(0xFF1F1F1F);
  static const muted = Color(0xFF7D8580);
  static const card = Colors.white;
  static const line = Color(0xFFE8ECE8);
  static const danger = Color(0xFFE66B5B);
}

class EcoRadius {
  static const double card = 20;
  static const double large = 28;
  static const double pill = 999;
}

class EcoShadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
}

class EcoCard extends StatelessWidget {
  const EcoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = EcoColors.card,
    this.radius = EcoRadius.card,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: EcoShadow.soft,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class EcoSectionHeader extends StatelessWidget {
  const EcoSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTapTrailing,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTapTrailing,
            child: Text(
              trailing!,
              style: const TextStyle(
                color: EcoColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class EcoPill extends StatelessWidget {
  const EcoPill({
    super.key,
    required this.label,
    this.icon,
    this.background = const Color(0xFFEAF6EF),
    this.foreground = EcoColors.secondary,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(EcoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EcoStatTile extends StatelessWidget {
  const EcoStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = EcoColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
