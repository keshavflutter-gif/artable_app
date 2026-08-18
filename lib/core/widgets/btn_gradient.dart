import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_radii.dart';
import 'package:artable_app/app/theme/app_shadows.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/app_icons.dart';

class BtnGradient extends StatefulWidget {
  const BtnGradient({
    super.key,
    required this.label,
    this.onPressed,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;

  @override
  State<BtnGradient> createState() => BtnGradientState();
}

class BtnGradientState extends State<BtnGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 2.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: -4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.ease,
    ));
  }

  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() {}),
        onTapUp: (_) => setState(() {}),
        onTapCancel: () => setState(() {}),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppRadii.btn),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(AppRadii.btn),
                boxShadow: AppShadows.btnGradient,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.btn),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.label, style: AppTextStyles.displayBold15),
                        if (widget.showArrow) ...[
                          const SizedBox(width: 10),
                          AppIcons.arrowRight(),
                        ],
                      ],
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
