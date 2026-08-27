import 'package:flutter/widgets.dart';

/// Phosphor icons, bundled directly.
///
/// The `phosphor_flutter` package does not compile on Flutter 3.44 (it extends
/// the now-`final` [IconData]), so we ship the Phosphor `.ttf` fonts as assets
/// and reference the glyphs by codepoint here — no subclassing. [PxIcon]
/// replicates Phosphor's duotone rendering (a faint secondary glyph stacked
/// under the main one).
class PxData {
  const PxData(this.icon, [this.secondaryIcon]);
  final IconData icon;
  final IconData? secondaryIcon; // duotone only
}

/// Renders a [PxData] — a plain glyph, or a two-tone duotone (secondary at 20%).
class PxIcon extends StatelessWidget {
  const PxIcon(this.data, {super.key, this.size, this.color});
  final PxData data;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final sec = data.secondaryIcon;
    if (sec == null) return Icon(data.icon, size: size, color: color);
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0.20, child: Icon(sec, size: size, color: color)),
        Icon(data.icon, size: size, color: color),
      ],
    );
  }
}

const _r = 'PhosphorRegular';
const _f = 'PhosphorFill';
const _d = 'PhosphorDuotone';

/// The Phosphor glyphs used across the app (matches the redesign spec).
class Px {
  Px._();

  // --- Fill (solid) ---
  static const playFill = PxData(IconData(0xe3d0, fontFamily: _f));
  static const playCircleFill = PxData(IconData(0xe3d2, fontFamily: _f));
  static const pauseFill = PxData(IconData(0xe39e, fontFamily: _f));
  static const skipBack = PxData(IconData(0xe5a4, fontFamily: _f));
  static const skipForward = PxData(IconData(0xe5a6, fontFamily: _f));
  static const caretLeft = PxData(IconData(0xe138, fontFamily: _f));
  static const caretRight = PxData(IconData(0xe13a, fontFamily: _f));
  static const checkCircleFill = PxData(IconData(0xe184, fontFamily: _f));
  static const heartFill = PxData(IconData(0xe2a8, fontFamily: _f));
  static const signOut = PxData(IconData(0xe42a, fontFamily: _f));
  static const pencilSimple = PxData(IconData(0xe3b4, fontFamily: _f));
  static const x = PxData(IconData(0xe4f6, fontFamily: _f));

  // --- Nav (regular idle, fill selected) ---
  static const house = PxData(IconData(0xe2c2, fontFamily: _r));
  static const houseFill = PxData(IconData(0xe2c2, fontFamily: _f));
  static const books = PxData(IconData(0xe758, fontFamily: _r));
  static const booksFill = PxData(IconData(0xe758, fontFamily: _f));
  static const userCircle = PxData(IconData(0xe4c4, fontFamily: _r));
  static const userCircleFill = PxData(IconData(0xe4c4, fontFamily: _f));

  // --- Duotone (main + faint secondary) ---
  static const bell =
      PxData(IconData(0xe0cf, fontFamily: _d), IconData(0xe0ce, fontFamily: _d));
  static const magnifyingGlass =
      PxData(IconData(0xe30d, fontFamily: _d), IconData(0xe30c, fontFamily: _d));
  static const microphone =
      PxData(IconData(0xe327, fontFamily: _d), IconData(0xe326, fontFamily: _d));
  static const usersThree =
      PxData(IconData(0xe68f, fontFamily: _d), IconData(0xe68e, fontFamily: _d));
  static const playlist =
      PxData(IconData(0xe6ab, fontFamily: _d), IconData(0xe6aa, fontFamily: _d));
  static const moonStars =
      PxData(IconData(0xe58f, fontFamily: _d), IconData(0xe58e, fontFamily: _d));
  static const bookOpen =
      PxData(IconData(0xe0e7, fontFamily: _d), IconData(0xe0e6, fontFamily: _d));
  static const trendUp =
      PxData(IconData(0xe4af, fontFamily: _d), IconData(0xe4ae, fontFamily: _d));
  static const shuffle =
      PxData(IconData(0xe423, fontFamily: _d), IconData(0xe422, fontFamily: _d));
  static const downloadSimple =
      PxData(IconData(0xe20d, fontFamily: _d), IconData(0xe20c, fontFamily: _d));
  static const clockCounterClockwise =
      PxData(IconData(0xe1a1, fontFamily: _d), IconData(0xe1a0, fontFamily: _d));
  static const translate =
      PxData(IconData(0xe4a3, fontFamily: _d), IconData(0xe4a2, fontFamily: _d));
  static const sun =
      PxData(IconData(0xe473, fontFamily: _d), IconData(0xe472, fontFamily: _d));
  static const question =
      PxData(IconData(0xe3eb, fontFamily: _d), IconData(0xe3e8, fontFamily: _d));
  static const chatCircleText =
      PxData(IconData(0xe16f, fontFamily: _d), IconData(0xe16e, fontFamily: _d));
  static const info =
      PxData(IconData(0xe2cf, fontFamily: _d), IconData(0xe2ce, fontFamily: _d));
  static const repeat =
      PxData(IconData(0xe3f9, fontFamily: _d), IconData(0xe3f6, fontFamily: _d));
  static const arrowCounterClockwise =
      PxData(IconData(0xe039, fontFamily: _d), IconData(0xe038, fontFamily: _d));
  static const arrowClockwise =
      PxData(IconData(0xe037, fontFamily: _d), IconData(0xe036, fontFamily: _d));
  static const queue =
      PxData(IconData(0xe6ad, fontFamily: _d), IconData(0xe6ac, fontFamily: _d));
  static const heart =
      PxData(IconData(0xe2a9, fontFamily: _d), IconData(0xe2a8, fontFamily: _d));
}
