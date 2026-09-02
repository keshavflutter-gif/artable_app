import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/formatters.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';

class StudioStepIndicator extends StatelessWidget {
  const StudioStepIndicator({
    super.key,
    required this.activeIndex,
    this.steps,
  });

  final int activeIndex;
  final List<String>? steps;

  static const _defaultSteps = ['Challenge', 'Record', 'Details', 'Preview'];

  @override
  Widget build(BuildContext context) {
    final stepList = (steps != null && steps!.isNotEmpty) ? steps! : _defaultSteps;
    final progress = activeIndex / (stepList.length - 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22, top: 4),
      child: Stack(
        children: [
          Positioned(
            top: 17,
            left: MediaQuery.sizeOf(context).width * 0.125,
            right: MediaQuery.sizeOf(context).width * 0.125,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFECE7F6),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.button,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(stepList.length, (i) {
              final isActive = i == activeIndex;
              final isDone = i < activeIndex;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive ? AppGradients.button : null,
                        color: isDone
                            ? AppColors.purple
                            : isActive
                                ? null
                                : const Color(0xFFF2EEFA),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF5E2EAA).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      transform: isActive
                          ? Matrix4.diagonal3Values(1.2, 1.2, 1.0)
                          : Matrix4.identity(),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: AppTextStyles.divider115.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? Colors.white : AppColors.textFaint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      stepList[i],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                        color: isActive
                            ? AppColors.purple
                            : isDone
                                ? AppColors.text
                                : AppColors.textFaint,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class StudioHeroCard extends StatelessWidget {
  const StudioHeroCard({super.key, required this.challenge});

  final Map<String, dynamic> challenge;

  @override
  Widget build(BuildContext context) {
    final maxDuration = challenge['maxVideoDuration'] != null
        ? '${challenge['maxVideoDuration']}'
        : '60';

    final categoryStr = (challenge['category'] as String?)?.trim() ?? '';
    final prizeStr = (challenge['prize'] as String?)?.trim() ?? '';
    final endDateRaw = (challenge['endDate'] as String?)?.trim() ?? '';
    final formattedDate = endDateRaw.isNotEmpty ? AppFormatters.formatDate(endDateRaw) : '';

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF1B0E3E), Color(0xFF2A1560), Color(0xFF170B33)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15083C).withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0x73FF8A3D),
                    const Color(0x408B3DFF),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.55, 0.75],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.46,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black],
                stops: [0, 0.32],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: AppNetworkImage(
                url: challenge['imageUrl'] as String? ?? challenge['bannerUrl'] as String? ?? '',
                fit: BoxFit.cover,
                alt: challenge['title'] as String? ?? '',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x0D0A0519),
                  const Color(0x400A0519),
                  const Color(0x8C080414),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Max $maxDuration sec',
                          style: AppTextStyles.divider115.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ready to record your talent?',
                    style: AppTextStyles.hint12.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    challenge['title'] as String? ?? '',
                    style: AppTextStyles.displayBold20.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.22,
                    ),
                  ),
                  if (categoryStr.isNotEmpty || prizeStr.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (categoryStr.isNotEmpty)
                          Text(
                            categoryStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFC24D),
                            ),
                          ),
                        if (categoryStr.isNotEmpty && prizeStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (prizeStr.isNotEmpty)
                          Text(
                            prizeStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFC24D),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ends $formattedDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeSummaryCard extends StatelessWidget {
  const ChallengeSummaryCard({super.key, required this.challenge});

  final Map<String, dynamic> challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFBF6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B3DFF).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              url: challenge['imageUrl'] as String,
              width: 74,
              height: 74,
              alt: challenge['title'] as String? ?? '',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'] as String? ?? '',
                  style: AppTextStyles.displaySemiBold135.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  challenge['category'] as String? ?? '',
                  style: AppTextStyles.hint12.copyWith(fontSize: 12),
                ),
                Text(
                  challenge['prize'] as String? ?? '',
                  style: AppTextStyles.hint12.copyWith(fontSize: 12),
                ),
                Text(
                  'Ends ${AppFormatters.formatDate(challenge['endDate'] as String? ?? '')}',
                  style: AppTextStyles.hint12.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
