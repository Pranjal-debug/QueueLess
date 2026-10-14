import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../design_system/app_components.dart';
import '../design_system/app_theme.dart';

class SignInScreen extends StatefulWidget {
  final Widget child;

  const SignInScreen({super.key, required this.child});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    client.auth.authInfoListenable.addListener(_updateSignedInState);
    _isSignedIn = client.auth.isAuthenticated;
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_updateSignedInState);
    super.dispose();
  }

  void _updateSignedInState() {
    if (!mounted) return;
    setState(() => _isSignedIn = client.auth.isAuthenticated);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn) return widget.child;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 760
              ? AppSpacing.xxl
              : constraints.maxWidth < 360
                  ? AppSpacing.md
                  : AppSpacing.lg;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xl,
              horizontalPadding,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    if (innerConstraints.maxWidth < 780) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIntro(context),
                          const SizedBox(height: AppSpacing.xl),
                          _buildSignInCard(context),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildIntro(context)),
                        const SizedBox(width: AppSpacing.xxxl),
                        Expanded(child: _buildSignInCard(context)),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: const Icon(
            Icons.space_dashboard_outlined,
            color: AppColors.accentDark,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'STAFF ACCESS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.accent,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Keep every queue moving with confidence.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Sign in to access the queue for your authorized room. Your staff permissions are checked securely before any queue data is loaded.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppStatusBadge(
          label: 'Protected staff workspace',
          icon: Icons.lock_outline,
          tone: AppStatusTone.neutral,
        ),
      ],
    );
  }

  Widget _buildSignInCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('Use your staff account to continue.'),
          const SizedBox(height: AppSpacing.lg),
          SignInWidget(
            client: client,
            onAuthenticated: () {
              if (!mounted) return;
              context.showSnackBar(
                message: 'You’re signed in. Checking your room access…',
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
              );
            },
            onError: (_) {
              if (!mounted) return;
              context.showSnackBar(
                message:
                    'We couldn’t sign you in. Check your details and try again.',
                backgroundColor: colors.errorContainer,
                foregroundColor: colors.onErrorContainer,
              );
            },
          ),
        ],
      ),
    );
  }
}

extension on BuildContext {
  void showSnackBar({
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
