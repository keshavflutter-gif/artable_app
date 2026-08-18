import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/app/routes/app_routes.dart';
import 'package:artable_app/core/utils/app_icons.dart';

/// Home studio header — matches doc/css/app.css `.studio-header`.
class StudioHeader extends StatelessWidget {
  const StudioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.studioHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: _HeaderLeft(),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: _HeaderActions(onProfileTap: () => context.go(AppRoutes.profile)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderLeft extends StatelessWidget {
  const _HeaderLeft();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          onPressed: () => context.push(AppRoutes.settings),
          child: AppIcons.menu(size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppGradients.button,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FF3D77),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/logo.svg',
              width: 20,
              height: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: AppTypography.display(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  children: const [
                    TextSpan(text: 'ARTABLE '),
                    TextSpan(
                      text: 'STUDIO',
                      style: TextStyle(color: Color(0xFFFFC24D)),
                    ),
                  ],
                ),
              ),
              Text(
                'By Artable Studio Pvt. Ltd.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconButton(
          onPressed: () => context.push(AppRoutes.search),
          child: AppIcons.search(size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const _NotificationBell(),
        const SizedBox(width: 8),
        Flexible(
          child: _ProfileChip(
            name: auth.userName,
            initials: auth.userInitials,
            onTap: onProfileTap,
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.child,
    this.onPressed,
  });

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox(width: 20, height: 20, child: Center(child: child)),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AppIcons.bell(size: 20, color: Colors.white),
              Positioned(
                top: -5,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF170A30), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x8CFF3D77),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '3',
                    style: AppTypography.body(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.name,
    required this.initials,
    required this.onTap,
  });

  final String name;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 2),
              gradient: AppGradients.button,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.display(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AppTypography.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 2),
          AppIcons.chevronDown(
            size: 12,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
