import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppStatusTone { accent, positive, warning, neutral, danger }

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F2D2B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppPageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  const AppPageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.accent,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(description),
        ),
      ],
    );

    if (trailing == null) return titleBlock;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppSpacing.md),
              trailing!,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            trailing!,
          ],
        );
      },
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppStatusTone tone;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: colors.foreground.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ToneColors _toneColors(AppStatusTone value) {
    return switch (value) {
      AppStatusTone.accent => const _ToneColors(
        AppColors.accentSoft,
        AppColors.accentDark,
      ),
      AppStatusTone.positive => const _ToneColors(
        AppColors.positiveSoft,
        AppColors.positive,
      ),
      AppStatusTone.warning => const _ToneColors(
        AppColors.warningSoft,
        AppColors.warning,
      ),
      AppStatusTone.neutral => const _ToneColors(
        AppColors.surfaceMuted,
        AppColors.inkMuted,
      ),
      AppStatusTone.danger => const _ToneColors(
        AppColors.dangerSoft,
        AppColors.danger,
      ),
    };
  }
}

class _ToneColors {
  final Color background;
  final Color foreground;

  const _ToneColors(this.background, this.foreground);
}

class AppFeedbackBanner extends StatelessWidget {
  final String message;
  final AppStatusTone tone;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const AppFeedbackBanner({
    super.key,
    required this.message,
    this.tone = AppStatusTone.danger,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppStatusTone.danger => (
        AppColors.dangerSoft,
        AppColors.danger,
        Icons.error_outline,
      ),
      AppStatusTone.warning => (
        AppColors.warningSoft,
        AppColors.warning,
        Icons.warning_amber_outlined,
      ),
      AppStatusTone.positive => (
        AppColors.positiveSoft,
        AppColors.positive,
        Icons.check_circle_outline,
      ),
      AppStatusTone.accent => (
        AppColors.accentSoft,
        AppColors.accentDark,
        Icons.info_outline,
      ),
      AppStatusTone.neutral => (
        AppColors.surfaceMuted,
        AppColors.inkMuted,
        Icons.info_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: colors.$2.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.$3, color: colors.$2, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.$2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              tooltip: 'Try again',
              icon: Icon(Icons.refresh_rounded, color: colors.$2),
              visualDensity: VisualDensity.compact,
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss message',
              icon: Icon(Icons.close, color: colors.$2),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class AppQueueFlow extends StatelessWidget {
  final int waitingCount;
  final int servingCount;
  final int? customerPosition;

  const AppQueueFlow({
    super.key,
    required this.waitingCount,
    required this.servingCount,
    this.customerPosition,
  });

  @override
  Widget build(BuildContext context) {
    final ahead = customerPosition == null
        ? null
        : (customerPosition! - 1).clamp(0, 1 << 30);
    final visibleAhead = ahead == null
        ? 0
        : ahead > 5
        ? 5
        : ahead;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppColors.accentDark),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Live queue flow',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppStatusBadge(
                label: '$waitingCount waiting',
                icon: Icons.groups_outlined,
                tone: AppStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (servingCount > 0)
                const AppStatusBadge(
                  label: 'Serving now',
                  icon: Icons.campaign_outlined,
                  tone: AppStatusTone.warning,
                ),
              ...List<Widget>.generate(
                visibleAhead,
                (index) => Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.borderStrong,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (ahead != null && ahead > visibleAhead)
                Text(
                  '+${ahead - visibleAhead} ahead',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (customerPosition != null)
                const AppStatusBadge(
                  label: 'Your ticket',
                  icon: Icons.person_pin_circle_outlined,
                  tone: AppStatusTone.accent,
                ),
              if (customerPosition == null && servingCount == 0)
                Text(
                  'Waiting for the next customer',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (ahead != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              ahead == 0
                  ? 'You are next after the ticket currently being served.'
                  : '$ahead ${ahead == 1 ? 'person is' : 'people are'} ahead of you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class AppQueueMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;

  const AppQueueMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AppStatusTone.accent,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = switch (tone) {
      AppStatusTone.accent => AppColors.accentDark,
      AppStatusTone.positive => AppColors.positive,
      AppStatusTone.warning => AppColors.warning,
      AppStatusTone.neutral => AppColors.inkMuted,
      AppStatusTone.danger => AppColors.danger,
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;

  const AppSectionHeading({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.inkMuted, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(message, textAlign: TextAlign.center),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = false,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = (foregroundColor != null || borderColor != null)
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.accentDark,
            side: BorderSide(
              color: borderColor ?? foregroundColor ?? AppColors.borderStrong,
            ),
          )
        : null;

    final button = OutlinedButton.icon(
      style: style,
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 20),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppLoadingState extends StatelessWidget {
  final String message;

  const AppLoadingState({
    super.key,
    this.message = 'Loading…',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message),
        ],
      ),
    );
  }
}
