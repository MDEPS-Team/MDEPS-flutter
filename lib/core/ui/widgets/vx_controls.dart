import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';

enum VxButtonStyle { primary, secondary, ghost, blue }

/// Main call-to-action button: press scale, disabled fade and loading swap.
class VxButton extends StatelessWidget {
  const VxButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = VxButtonStyle.primary,
    this.enabled = true,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 52,
    this.expand = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final VxButtonStyle style;
  final bool enabled;
  final bool loading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final (bg, fg, border) = switch (style) {
      VxButtonStyle.primary => (p.ink, p.surface, null),
      VxButtonStyle.secondary => (p.surface, p.ink, BorderSide(color: p.line)),
      VxButtonStyle.ghost => (Colors.transparent, p.ink, null),
      VxButtonStyle.blue => (Vx.blue, Colors.white, null),
    };
    final active = enabled && !loading && onPressed != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: border ?? BorderSide.none,
    );

    return PressScale(
      enabled: active,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: VxMotion.fast,
        child: SizedBox(
          height: height,
          width: expand ? double.infinity : null,
          child: Material(
            color: bg,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: active ? onPressed : null,
              splashColor: fg.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: VxMotion.fast,
                    switchInCurve: VxMotion.easeOut,
                    child: loading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (leadingIcon != null) ...[
                                Icon(leadingIcon, color: fg, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (trailingIcon != null) ...[
                                const SizedBox(width: 8),
                                Icon(trailingIcon, color: fg, size: 18),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-select pill chip with color transition.
class VxChoiceChip extends StatelessWidget {
  const VxChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return PressScale(
      pressedScale: 0.95,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: VxMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? p.ink : p.chip,
            borderRadius: BorderRadius.circular(50),
          ),
          child: AnimatedDefaultTextStyle(
            duration: VxMotion.fast,
            style: TextStyle(
              color: selected ? p.surface : p.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            child: Text(text, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

class VxFieldLabel extends StatelessWidget {
  const VxFieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.vx.muted,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: trailing == null
          ? label
          : Row(children: [Expanded(child: label), trailing!]),
    );
  }
}

InputDecoration vxInputDecoration(
  BuildContext context, {
  String? hint,
  IconData? leadingIcon,
  Widget? suffix,
  String? error,
  Widget? prefix,
  Color? fill,
}) {
  final p = context.vx;
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.7)),
    prefixIcon: leadingIcon == null ? null : Icon(leadingIcon, color: p.muted),
    prefix: prefix,
    suffixIcon: suffix,
    errorText: error,
    filled: true,
    fillColor: fill ?? p.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: border(p.line),
    focusedBorder: border(p.ink, 1.5),
    errorBorder: border(Vx.red),
    focusedErrorBorder: border(Vx.red, 1.5),
    disabledBorder: border(p.line),
  );
}

/// Labeled single-line text field with optional password reveal toggle.
class VxTextField extends StatefulWidget {
  const VxTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.error,
    this.leadingIcon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? error;
  final IconData? leadingIcon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;

  @override
  State<VxTextField> createState() => _VxTextFieldState();
}

class _VxTextFieldState extends State<VxTextField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) VxFieldLabel(widget.label),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.isPassword && !_revealed,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          cursorColor: p.ink,
          style: TextStyle(color: p.ink, fontSize: 15),
          decoration: vxInputDecoration(
            context,
            hint: widget.hint,
            leadingIcon: widget.leadingIcon,
            suffix: widget.isPassword
                ? IconButton(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(
                      _revealed ? Icons.visibility_off : Icons.visibility,
                      color: p.muted,
                    ),
                  )
                : null,
          ),
        ),
        AnimatedSize(
          duration: VxMotion.fast,
          curve: VxMotion.easeOut,
          child: widget.error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    widget.error!,
                    style: const TextStyle(color: Vx.red, fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Segmented selector on a chip-colored track (e.g. period filters).
class VxSegmented extends StatelessWidget {
  const VxSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.selectedColor,
    this.selectedTextColor,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color? selectedColor;
  final Color? selectedTextColor;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: VxMotion.fast,
                  curve: VxMotion.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? (selectedColor ?? p.surface) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    options[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                      color: i == selected ? (selectedTextColor ?? p.ink) : p.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
