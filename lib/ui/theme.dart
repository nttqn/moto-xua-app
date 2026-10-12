import 'package:flutter/material.dart';

import '../services/progress.dart';
import '../services/sound_service.dart';

/// Old shop-sign colours: lime-wash cream, flag red, enamel yellow, teal.
const paper = Color(0xFFF3E9D2);
const paperDark = Color(0xFFE4D5B3);
const ink = Color(0xFF3A2A1E);
const signRed = Color(0xFFB3261E);
const signYellow = Color(0xFFF0C24B);
const signTeal = Color(0xFF1E6B6B);
const signBlue = Color(0xFF1F4E8C);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnam',
    colorScheme: ColorScheme.fromSeed(
      seedColor: signRed,
      surface: paper,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: paper,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: signRed,
      foregroundColor: Color(0xFFFFF3C4),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Bungee',
        fontSize: 20,
        color: Color(0xFFFFF3C4),
      ),
    ),
  );
}

const TextStyle signText = TextStyle(fontFamily: 'Bungee', height: 1.1);

String money(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return '$out đ';
}

/// A painted wooden signboard that presses in when tapped.
class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = signRed,
    this.textColor = const Color(0xFFFFF3C4),
    this.icon,
    this.sub,
    this.fontSize = 20,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final String? sub;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final face = enabled ? color : const Color(0xFF9A9284);
    return Material(
      color: face,
      borderRadius: BorderRadius.circular(10),
      elevation: enabled ? 4 : 0,
      shadowColor: Colors.black,
      child: InkWell(
        onTap: enabled
            ? () {
                SoundService.instance.play(Sfx.click);
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.25), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: fontSize + 6),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: signText.copyWith(
                        color: textColor,
                        fontSize: fontSize,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wallet, kept current wherever it is shown.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: signYellow, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.paid, color: signYellow, size: 18),
            const SizedBox(width: 6),
            Text(
              money(Progress.instance.coins),
              style: const TextStyle(
                color: Color(0xFFFFF3C4),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars(this.count, {super.key, this.size = 18});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < count ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < count ? const Color(0xFFE0A21A) : ink.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
