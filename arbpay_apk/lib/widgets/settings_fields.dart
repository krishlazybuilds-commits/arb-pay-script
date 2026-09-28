import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small uppercase label used to title a group of fields.
class SectionLabel extends StatelessWidget {
  final String text;
  final AppTheme t;
  const SectionLabel(this.text, this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: t.textSub,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// Themed text field used across settings and the profile editor.
class DarkField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final AppTheme t;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;

  const DarkField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.t,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        style: TextStyle(color: t.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.textSub, fontSize: 13),
          prefixIcon: Icon(icon, color: t.textDim, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

/// One half of the two-way payment-mode switch.
class ModeTab extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool selected;
  final bool isLeft;
  final AppTheme t;
  final VoidCallback onTap;

  const ModeTab({
    super.key,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.selected,
    required this.isLeft,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? t.yellowDim : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(13) : Radius.zero,
              right: isLeft ? Radius.zero : const Radius.circular(13),
            ),
            border: Border.all(
              color: selected
                  ? t.yellow.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? t.yellow : t.textDim, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  color: selected ? t.yellow : t.textSub,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
            const SizedBox(height: 3),
            Text(
              subLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? t.yellow.withValues(alpha: 0.6) : t.textDim,
                fontSize: 9,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
