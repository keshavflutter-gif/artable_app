import 'package:flutter/material.dart';

/// Full-bleed background matching specified asset frame
class BgDecoration extends StatelessWidget {
  const BgDecoration({
    super.key,
    this.assetName = 'assets/bg-frame-1.png',
  });

  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        assetName,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
