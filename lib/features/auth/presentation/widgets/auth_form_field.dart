// auth_form_field.dart
// Consistent styled TextFormField used across login & register pages.

import 'package:flutter/material.dart';

class AuthFormField extends StatefulWidget {
  final String             label;
  final String?            hint;
  final IconData           prefixIcon;
  final bool               isPassword;
  final bool               isOptional;
  final TextInputType      keyboardType;
  final TextEditingController controller;
  final String?            Function(String?)? validator;
  final TextInputAction     textInputAction;
  final VoidCallback?      onEditingComplete;
  final bool               enabled;

  const AuthFormField({
    super.key,
    required this.label,
    required this.prefixIcon,
    required this.controller,
    this.hint,
    this.isPassword      = false,
    this.isOptional      = false,
    this.keyboardType    = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.enabled         = true,
  });

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller:        widget.controller,
      obscureText:       widget.isPassword && _obscure,
      keyboardType:      widget.keyboardType,
      textInputAction:   widget.textInputAction,
      enabled:           widget.enabled,
      onEditingComplete: widget.onEditingComplete,
      validator:         widget.validator,
      autocorrect:       false,
      decoration: InputDecoration(
        labelText:  widget.label +
            (widget.isOptional ? '  (optional)' : ''),
        hintText:   widget.hint,
        fillColor:  scheme.surfaceContainerHighest.withOpacity(0.5),
        prefixIcon: Icon(widget.prefixIcon, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
