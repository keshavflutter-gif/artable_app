import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/widgets/network_image_widget.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.gridMode = false,
  });

  final Map<String, dynamic> category;
  final bool gridMode;

  @override
  Widget build(BuildContext context) {
    final height = gridMode ? 172.0 : 132.0;
    final borderRadius = gridMode ? 22.0 : 18.0;
    final iconSize = gridMode ? 32.0 : 28.0;
    final iconRadius = gridMode ? 10.0 : 9.0;
    final nameSize = gridMode ? 15.0 : 13.5;
    final textInset = gridMode ? 14.0 : 12.0;
    final bottomInset = gridMode ? 14.0 : 11.0;

    return GestureDetector(
      onTap: () => context.go('/challenges?categoryId=${category['id']}'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x285E2EAA),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWidget(url: category['imageUrl'] as String? ?? ''),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0F140A28),
                    Color(0x0A140A28),
                    Color(0x940A0514),
                    Color(0xEB06030E),
                  ],
                  stops: [0, 0.32, 0.62, 1],
                ),
              ),
            ),
            Positioned(
              top: gridMode ? 14 : 11,
              left: gridMode ? 14 : 11,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(iconRadius),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _iconForCategory(category['icon'] as String? ?? 'sparkle'),
                  size: gridMode ? 16 : 14,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: textInset,
              right: textInset,
              bottom: bottomInset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category['name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF21B573),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${category['count'] ?? category['liveChallenges'] ?? 0} live',
                          style: AppTypography.body(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String icon) {
    switch (icon) {
      case 'dance':
        return Icons.directions_run;
      case 'mic':
        return Icons.mic;
      case 'mask':
        return Icons.theater_comedy;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'wand':
        return Icons.auto_fix_high;
      case 'brush':
        return Icons.brush;
      case 'drama':
        return Icons.movie_filter;
      case 'trophy':
        return Icons.emoji_events;
      case 'sparkle':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }
}
