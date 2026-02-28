import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/app_settings.dart';
import 'app_cards.dart';
import 'app_style.dart';

enum AppDialogTone { normal, danger }

class AppDialogs {
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogTone tone = AppDialogTone.normal,
    bool dismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? .55 : .35),
      builder: (_) => _DialogMaterialShell(
        child: _ConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          tone: tone,
        ),
      ),
    );
    return result == true;
  }

  /// validate(code) returns:
  /// - null  => success (dialog closes and returns the code)
  /// - String => error message to display (dialog stays open)
  static Future<String?> showSixDigitCodeDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Future<String?> Function(String code) validate,
    String defaultErrorMessage = 'Invalid code. Try again.',
    String confirmLabel = 'Enable',
    String cancelLabel = 'Cancel',
    bool obscureDigits = true,
    int length = 6,
    bool dismissible = true,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? .55 : .35),
      builder: (_) => _DialogMaterialShell(
        child: _SixDigitCodeDialog(
          title: title,
          subtitle: subtitle,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          obscureDigits: obscureDigits,
          length: length,
          validate: validate,
          defaultErrorMessage: defaultErrorMessage,
        ),
      ),
    );
  }

  static Future<Color?> showColorPalettePicker({
    required BuildContext context,
    required String title,
    required List<Color> palette,
    required Color current,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? .55 : .35),
      builder: (_) => _DialogMaterialShell(
        child: _PalettePickerDialog(
          title: title,
          palette: palette,
          current: current,
          cancelLabel: cancelLabel,
        ),
      ),
    );
  }

  static Future<_SelectedColorPick?> showSelectedCountryColorPicker({
    required BuildContext context,
    required String title,
    required List<Color> palette,
    required SelectedCountryColorMode mode,
    required Color currentColor,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<_SelectedColorPick>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? .55 : .35),
      builder: (_) => _DialogMaterialShell(
        child: _SelectedCountryColorPickerDialog(
          title: title,
          palette: palette,
          mode: mode,
          currentColor: currentColor,
          cancelLabel: cancelLabel,
        ),
      ),
    );
  }
}

/// ✅ Fixes “No Material widget found” for TextField inside custom glass surfaces.
class _DialogMaterialShell extends StatelessWidget {
  const _DialogMaterialShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context); // keyboard
    final padding = MediaQuery.paddingOf(context); // safe areas

    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        // ✅ bottom lifts when keyboard opens
        padding: EdgeInsets.fromLTRB(
          0,
          padding.top,
          0,
          insets.bottom + padding.bottom,
        ),
        child: Align(
          alignment: Alignment.center,
          // ✅ scrolls if keyboard leaves too little space
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.tone,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final AppDialogTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final accent = tone == AppDialogTone.danger ? cs.error : cs.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlowCard(
            tone: tone == AppDialogTone.danger ? CardTone.danger : CardTone.normal,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                      color: tone == AppDialogTone.danger ? cs.error : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(cancelLabel),
                      ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: cs.onPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SixDigitCodeDialog extends StatefulWidget {
  const _SixDigitCodeDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.obscureDigits,
    required this.length,
    required this.validate,
    required this.defaultErrorMessage,
  });

  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final bool obscureDigits;
  final int length;

  /// validate(code) returns:
  /// - null => success
  /// - String => error message to show (keep dialog open)
  final Future<String?> Function(String code) validate;

  final String defaultErrorMessage;

  @override
  State<_SixDigitCodeDialog> createState() => _SixDigitCodeDialogState();
}

class _SixDigitCodeDialogState extends State<_SixDigitCodeDialog> {
  late final List<TextEditingController> _controllers = List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(widget.length, (_) => FocusNode());

  bool _submitting = false;
  String? _errorText;
  bool _closing = false;

  Future<void> _safePop<T>(T? result) async {
    if (_closing) return;
    _closing = true;

    // let current gesture/ink effects finish
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);

    try {
      nav.pop(result);
      return;
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav2 = Navigator.of(context, rootNavigator: true);
      try {
        nav2.pop(result);
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text.trim()).join();
  bool get _isComplete => _controllers.every((c) => c.text.trim().isNotEmpty);

  void _focusIndex(int i) {
    if (i < 0 || i >= _nodes.length) return;
    _nodes[i].requestFocus();
  }

  void _setDigit(int i, String v) {
    if (i < 0 || i >= _controllers.length) return;
    _controllers[i].text = v;
    _controllers[i].selection = TextSelection.collapsed(offset: _controllers[i].text.length);
  }

  void _clearAll({bool keepFocus = true}) {
    for (final c in _controllers) c.clear();
    if (keepFocus) _focusIndex(0);
  }

  void _handlePasteOrInput(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _setDigit(index, '');
      setState(() {
        _errorText = null;
      });
      return;
    }

    var k = 0;
    for (int i = index; i < widget.length && k < digits.length; i++) {
      _setDigit(i, digits[k]);
      k++;
    }

    final nextEmpty = _controllers.indexWhere((c) => c.text.trim().isEmpty);
    if (nextEmpty == -1) {
      _nodes.last.unfocus();
    } else {
      _focusIndex(nextEmpty);
    }

    setState(() {
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting || _closing) return;

    if (!_isComplete) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() => _submitting = true);
    try {
      final err = await widget.validate(_code);
      if (!mounted) return;

      if (err == null) {
        await _safePop<String>(_code);
        return;
      }

      HapticFeedback.lightImpact();
      setState(() {
        _errorText = err.trim().isEmpty ? widget.defaultErrorMessage : err;
      });
      _clearAll();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DigitRow(
                    length: widget.length,
                    controllers: _controllers,
                    nodes: _nodes,
                    obscureDigits: widget.obscureDigits,
                    showError: _errorText != null,
                    onChanged: (index, value) => _handlePasteOrInput(index, value),
                    onBackspaceAtEmpty: (index) {
                      if (index <= 0) return;
                      _setDigit(index - 1, '');
                      _focusIndex(index - 1);
                      setState(() {
                        _errorText = null;
                      });
                    },
                    onMaybeComplete: () {
                      if (_isComplete) _submit();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _submitting ? null : () => _safePop<String?>(null),
                        child: Text(widget.cancelLabel),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(widget.confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _DigitChanged = void Function(int index, String value);
typedef _BackspaceEmpty = void Function(int index);

class _DigitRow extends StatelessWidget {
  const _DigitRow({
    required this.length,
    required this.controllers,
    required this.nodes,
    required this.obscureDigits,
    required this.showError,
    required this.onChanged,
    required this.onBackspaceAtEmpty,
    required this.onMaybeComplete,
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final bool obscureDigits;
  final bool showError;

  final _DigitChanged onChanged;
  final _BackspaceEmpty onBackspaceAtEmpty;
  final VoidCallback onMaybeComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = context.style;

    final w = MediaQuery.of(context).size.width;
    final box = (w < 380) ? 44.0 : 50.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (i) {
        return _DigitBox(
          size: box,
          controller: controllers[i],
          node: nodes[i],
          obscure: obscureDigits,
          radius: style.iconRadius,
          showError: showError,
          textStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
          onChanged: (v) {
            onChanged(i, v);

            final t = controllers[i].text.trim();
            if (t.isNotEmpty && t.length == 1 && i < length - 1) {
              nodes[i + 1].requestFocus();
            }

            onMaybeComplete();
          },
          onBackspaceAtEmpty: () => onBackspaceAtEmpty(i),
        );
      }),
    );
  }
}

// --- everything below unchanged from your file ---

class _SelectedColorPick {
  final SelectedCountryColorMode mode;
  final Color? color;

  const _SelectedColorPick.multicolor()
      : mode = SelectedCountryColorMode.multicolor,
        color = null;

  const _SelectedColorPick.single(this.color) : mode = SelectedCountryColorMode.single;
}

class _PalettePickerDialog extends StatelessWidget {
  const _PalettePickerDialog({
    required this.title,
    required this.palette,
    required this.current,
    required this.cancelLabel,
  });

  final String title;
  final List<Color> palette;
  final Color current;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                  ),
                  const SizedBox(height: 14),
                  _ColorGrid(
                    palette: palette,
                    selected: current,
                    onPick: (c) => Navigator.of(context).pop(c),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(cancelLabel, style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCountryColorPickerDialog extends StatelessWidget {
  const _SelectedCountryColorPickerDialog({
    required this.title,
    required this.palette,
    required this.mode,
    required this.currentColor,
    required this.cancelLabel,
  });

  final String title;
  final List<Color> palette;
  final SelectedCountryColorMode mode;
  final Color currentColor;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                  ),
                  const SizedBox(height: 14),
                  _SelectedColorGrid(
                    palette: palette,
                    mode: mode,
                    selectedColor: currentColor,
                    onPickMulticolor: () => Navigator.of(context).pop(const _SelectedColorPick.multicolor()),
                    onPickSingle: (c) => Navigator.of(context).pop(_SelectedColorPick.single(c)),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(cancelLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.palette,
    required this.selected,
    required this.onPick,
  });

  final List<Color> palette;
  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = context.style;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in palette)
          _ColorChip(
            color: c,
            selected: c.value == selected.value,
            radius: style.iconRadius,
            border: cs.outlineVariant.withOpacity(style.cardBorderOpacity),
            ring: cs.onSurface.withOpacity(.85),
            onTap: () => onPick(c),
          ),
      ],
    );
  }
}

class _SelectedColorGrid extends StatelessWidget {
  const _SelectedColorGrid({
    required this.palette,
    required this.mode,
    required this.selectedColor,
    required this.onPickMulticolor,
    required this.onPickSingle,
  });

  final List<Color> palette;
  final SelectedCountryColorMode mode;
  final Color selectedColor;
  final VoidCallback onPickMulticolor;
  final ValueChanged<Color> onPickSingle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = context.style;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MultiColorChip(
          palette: palette,
          selected: mode == SelectedCountryColorMode.multicolor,
          radius: style.iconRadius,
          border: cs.outlineVariant.withOpacity(style.cardBorderOpacity),
          ring: cs.onSurface.withOpacity(.85),
          onTap: onPickMulticolor,
        ),
        for (final c in palette)
          _ColorChip(
            color: c,
            selected: mode == SelectedCountryColorMode.single && c.value == selectedColor.value,
            radius: style.iconRadius,
            border: cs.outlineVariant.withOpacity(style.cardBorderOpacity),
            ring: cs.onSurface.withOpacity(.85),
            onTap: () => onPickSingle(c),
          ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.radius,
    required this.border,
    required this.ring,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final double radius;
  final Color border;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ring : border,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _MultiColorChip extends StatelessWidget {
  const _MultiColorChip({
    required this.palette,
    required this.selected,
    required this.radius,
    required this.border,
    required this.ring,
    required this.onTap,
  });

  final List<Color> palette;
  final bool selected;
  final double radius;
  final Color border;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: palette),
          border: Border.all(
            color: selected ? ring : border,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _DigitBox extends StatefulWidget {
  const _DigitBox({
    required this.size,
    required this.controller,
    required this.node,
    required this.obscure,
    required this.radius,
    required this.showError,
    required this.textStyle,
    required this.onChanged,
    required this.onBackspaceAtEmpty,
  });

  final double size;
  final TextEditingController controller;
  final FocusNode node;
  final bool obscure;

  final double radius;
  final bool showError;
  final TextStyle? textStyle;

  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceAtEmpty;

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final focused = widget.node.hasFocus;

    final borderColor = widget.showError
        ? cs.error.withOpacity(.55)
        : (focused ? cs.primary.withOpacity(.55) : cs.outlineVariant.withOpacity(style.cardBorderOpacity));

    final fill = cs.surface.withOpacity(theme.brightness == Brightness.dark ? .10 : .12);

    final Color glowColor = widget.showError
        ? cs.error.withOpacity(theme.brightness == Brightness.dark ? .16 : .10)
        : cs.primary.withOpacity(theme.brightness == Brightness.dark ? .16 : .10);

    final showGlow = focused || widget.showError;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: _down ? style.pressScale : 1,
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: fill,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: showGlow
                ? [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 12),
                color: glowColor,
              ),
            ]
                : const [],
          ),
          alignment: Alignment.center,
          child: _BackspaceAwareField(
            controller: widget.controller,
            focusNode: widget.node,
            obscure: widget.obscure,
            textStyle: widget.textStyle,
            onChanged: widget.onChanged,
            onBackspaceAtEmpty: widget.onBackspaceAtEmpty,
          ),
        ),
      ),
    );
  }
}

class _BackspaceAwareField extends StatelessWidget {
  const _BackspaceAwareField({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.textStyle,
    required this.onChanged,
    required this.onBackspaceAtEmpty,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final TextStyle? textStyle;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceAtEmpty;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (controller.text.isEmpty) {
            onBackspaceAtEmpty();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: textStyle,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 6, // paste supported; we trim upstream
        maxLines: 1,
        obscureText: obscure,
        enableSuggestions: false,
        autocorrect: false,
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}