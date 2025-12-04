import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/* ============================== TITLES ============================== */

/// Title Widget
class AppTitle extends StatelessWidget {
  final String text;
  final Color color;
  final int size;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const AppTitle(
    this.text, {
    super.key,
    this.color = AppColors.primary,
    this.size = 16,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? overflow : TextOverflow.visible,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: size.toDouble(),
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// Subtitle Widget
class AppSubTitle extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const AppSubTitle(
    this.text, {
    super.key,
    this.color = AppColors.subtitle,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? overflow : TextOverflow.visible,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Label Widget
class AppLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  final FontWeight weight;

  const AppLabel(
    this.text, {
    super.key,
    this.color = AppColors.text,
    this.size = 15,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // NOTE: previously color param was ignored due to const TextStyle
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.1,
      ),
    );
  }
}

/* ============================== INPUTS ============================== */

/// Custom Input Field with enhanced visuals
class AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  // Optional UX enhancements (not required)
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(14));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, height: 1.4),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 22) : null,
        suffixIcon: suffixIcon,
        filled: true,
        // subtle fill that adapts to theme
        fillColor: isDark ? const Color(0xFF1C1F22) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.border, width: 1.1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        // Consistent error style
        errorStyle: TextStyle(
          color: Colors.redAccent.shade200,
          height: 1.2,
        ),
      ),
    );
  }
}

/* ============================== BUTTONS ============================== */

/// Primary Button
///
/// Safer layout: auto-expands when it *can*, but avoids infinite width in Row/Sliver.
/// No additional required params.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  // Optional polish
  final IconData? leadingIcon;
  final bool emphasis; // slightly bigger & stronger shadow for primary CTAs

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.leadingIcon,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: leadingIcon != null
          ? Icon(leadingIcon, size: 20)
          : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.primary,
        foregroundColor: Colors.white,
        elevation: emphasis ? 3 : 1,
        // IMPORTANT: do NOT set width = infinity; keep height consistent
        minimumSize: const Size(0, 48), // width flexible, height fixed
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    // Expand to full width *only* when constraints are finite.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.hasBoundedWidth;
        if (hasFiniteWidth) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: SizedBox(width: double.infinity, child: btn),
          );
        }
        // e.g., inside Row -> keep intrinsic width
        return btn;
      },
    );
  }
}

/// Outlined Button
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  // Optional polish
  final IconData? leadingIcon;

  const AppOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton.icon(
      onPressed: onPressed,
      icon: leadingIcon != null
          ? Icon(leadingIcon, size: 20, color: AppColors.primary)
          : const SizedBox.shrink(),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.3),
        minimumSize: const Size(0, 48), // width flexible, height fixed
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.hasBoundedWidth;
        if (hasFiniteWidth) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: SizedBox(width: double.infinity, child: btn),
          );
        }
        return btn;
      },
    );
  }
}

/// Text Button / Link
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppTextButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.08),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text),
    );
  }
}
