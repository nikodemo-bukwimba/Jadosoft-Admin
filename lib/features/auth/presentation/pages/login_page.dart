// login_page.dart
// ─────────────────────────────────────────────────────────────
// Fix: after successful login (both normal and addAccount mode),
// use pushNamedAndRemoveUntil to wipe the entire navigation stack
// and replace it with /home. This prevents the back button from
// appearing on the home screen after going through the picker flow.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_form_field.dart';

class LoginPage extends StatefulWidget {
  final bool addAccount;
  const LoginPage({super.key, this.addAccount = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAdding = widget.addAccount;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Clear the ENTIRE stack (picker + login) and start fresh at /home.
          // (ModalRoute.withName('/') removes everything below /home too.)
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (_) => false, // remove all previous routes
          );
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
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: isAdding
              ? AppBar(
                  title: const Text('Add account'),
                  leading: const BackButton(),
                )
              : null,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _formMaxWidth(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        isAdding: isAdding,
                        scheme: scheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 40),
                      _LoginForm(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        submitted: _submitted,
                        isLoading: isLoading,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 12),
                      _ForgotPassword(scheme: scheme),
                      const SizedBox(height: 32),
                      _SubmitButton(isLoading: isLoading, onSubmit: _submit),
                      if (!isAdding) ...[
                        const SizedBox(height: 24),
                        _RegisterLink(scheme: scheme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _formMaxWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return 440;
    if (w >= 600) return 480;
    return double.infinity;
  }
}

class _Header extends StatelessWidget {
  final bool isAdding;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _Header({
    required this.isAdding,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isAdding ? Icons.person_add_outlined : Icons.lock_outline_rounded,
            size: 28,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isAdding ? 'Add another account' : 'Welcome back',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAdding
              ? 'Sign in to add and switch between accounts'
              : 'Sign in to continue',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool submitted;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.submitted,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          AuthFormField(
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthFormField(
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            controller: passCtrl,
            isPassword: true,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ForgotPassword extends StatelessWidget {
  final ColorScheme scheme;
  const _ForgotPassword({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: const Text('Forgot password?'),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;

  const _SubmitButton({required this.isLoading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onSubmit,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Text('Sign in'),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final ColorScheme scheme;
  const _RegisterLink({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/register'),
          child: const Text('Create one'),
        ),
      ],
    );
  }
}
