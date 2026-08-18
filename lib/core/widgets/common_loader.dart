import 'package:flutter/material.dart';
import 'package:artable_app/app/theme/app_colors.dart';

class CommonLoader extends StatelessWidget {
  const CommonLoader({
    super.key,
    this.color = AppColors.purple,
    this.size = 36.0,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
