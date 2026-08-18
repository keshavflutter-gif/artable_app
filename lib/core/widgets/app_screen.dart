import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'bg_decoration.dart';

/// Scaffold matching .app-screen + .screen-scroll from style.css
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.child,
    this.centerContent = false,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(26, 28, 26, 28),
    this.bottomOverlay,
    this.bgAsset = 'assets/bg-frame-1.png',
  });

  final Widget child;
  final bool centerContent;
  final bool scrollable;
  final EdgeInsets padding;
  final Widget? bottomOverlay;
  final String bgAsset;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (centerContent) {
      content = Padding(
        padding: padding,
        child: Center(child: child),
      );
    } else if (scrollable) {
      content = SingleChildScrollView(
        padding: padding,
        child: child,
      );
    } else {
      content = Padding(padding: padding, child: child);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BgDecoration(assetName: bgAsset),
          SafeArea(child: content),
          ?bottomOverlay,
        ],
      ),
    );
  }
}
