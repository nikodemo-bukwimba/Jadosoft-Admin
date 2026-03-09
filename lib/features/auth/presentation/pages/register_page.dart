// register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_form_field.dart';

class RegisterPage extends StatefulWidget {
  final bool addAccount;
  const RegisterPage({super.key, this.addAccount = false});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
        phone: _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAdding = widget.addAccount;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (widget.addAccount) {
            context.go(AppRouter.accountPicker);
          } else {
            context.go(AppRouter.home);
          }
          return;
        }
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            appBar: isAdding
                ? AppBar(
                    title: const Text('Create account'),
                    leading: const BackButton(),
                  )
                : null,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _formMaxWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ───────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 28,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Create account',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fill in your details to get started',
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // ── Form ─────────────────────────────
                        Form(
                          key: _formKey,
                          autovalidateMode: _submitted
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            children: [
                              AuthFormField(
                                label: 'Full name',
                                prefixIcon: Icons.badge_outlined,
                                controller: _nameCtrl,
                                enabled: !isLoading,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Name is required';
                                  if (v.trim().length < 2)
                                    return 'Name is too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthFormField(
                                label: 'Email',
                                prefixIcon: Icons.email_outlined,
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !isLoading,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email is required';
                                  if (!v.contains('@'))
                                    return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthFormField(
                                label: 'Phone',
                                prefixIcon: Icons.phone_outlined,
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                isOptional: true,
                                enabled: !isLoading,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return null;
                                  final digits = v.replaceAll(
                                    RegExp(r'[\s\-()]'),
                                    '',
                                  );
                                  if (!RegExp(
                                    r'^\+?\d{7,15}$',
                                  ).hasMatch(digits)) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthFormField(
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                controller: _passCtrl,
                                isPassword: true,
                                enabled: !isLoading,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 8)
                                    return 'At least 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthFormField(
                                label: 'Confirm password',
                                prefixIcon: Icons.lock_outline,
                                controller: _confirmCtrl,
                                isPassword: true,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: _submit,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Please confirm your password';
                                  if (v != _passCtrl.text)
                                    return 'Passwords do not match';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Create account'),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                            TextButton(
                              onPressed: () {
                                if (isAdding) {
                                  // Pop back to LoginPage (was pushed before register).
                                  context.pop();
                                } else {
                                  context.go(AppRouter.login);
                                }
                              },
                              child: const Text('Sign in'),
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
        },
      ),
    );
  }

  double _formMaxWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return 440;
    if (w >= 600) return 480;
    return double.infinity;
  }
}
