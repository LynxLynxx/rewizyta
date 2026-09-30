import 'package:jaspr/dom.dart';

/// The Rewizyta palette. Values live once, as CSS custom properties in
/// `web/styles.css`; these read them, so a colour changes in one place.
abstract final class Palette {
  static const paper = Color.variable('--paper');
  static const white = Color.variable('--white');
  static const ink = Color.variable('--ink');
  static const ink2 = Color.variable('--ink-2');
  static const text2 = Color.variable('--text-2');
  static const muted = Color.variable('--muted');
  static const placeholder = Color.variable('--placeholder');
  static const controlLine = Color.variable('--control-line');
  static const onDarkMuted = Color.variable('--on-dark-muted');
  static const line = Color.variable('--line');
  static const lineLight = Color.variable('--line-light');

  /// Due dates and progress only, with ink text on it.
  static const accent = Color.variable('--accent');
  static const accentBg = Color.variable('--accent-bg');
  static const accentOnBg = Color.variable('--accent-on-bg');
  static const accentSelected = Color.variable('--accent-selected');
  static const accentText = Color.variable('--accent-text');
  static const ok = Color.variable('--ok');
  static const error = Color.variable('--error');
  static const decline = Color.variable('--decline');
}

/// IBM Plex Mono, for dates, phone numbers and codes.
const monoFont = FontFamily.variable('--font-mono');

/// Page width and side padding shared by every section.
const pageMaxWidth = Unit.pixels(1080);
const pagePadding = Unit.pixels(20);
