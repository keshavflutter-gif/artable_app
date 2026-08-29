import 'package:flutter/material.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';

class ShareReportScreen extends StatefulWidget {
  const ShareReportScreen({super.key, this.reelId});

  final String? reelId;

  @override
  State<ShareReportScreen> createState() => _ShareReportScreenState();
}

class _ShareReportScreenState extends State<ShareReportScreen> {
  String? _selectedReason;
  bool _reportSubmitted = false;
  String? _sharedOptionId;

  @override
  Widget build(BuildContext context) {
    ReelHelpers.reelById(widget.reelId ?? 'r1');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Share & Report'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share',
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: MockData.SHARE_OPTIONS.length,
                      itemBuilder: (context, i) {
                        final opt = MockData.SHARE_OPTIONS[i];
                        final id = opt['id'] as String;
                        final shared = _sharedOptionId == id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _sharedOptionId = id);
                            Future.delayed(const Duration(milliseconds: 900), () {
                              if (mounted && _sharedOptionId == id) {
                                setState(() => _sharedOptionId = null);
                              }
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: shared ? AppGradients.button : null,
                                  color: shared ? null : const Color(0xFFF5F2FC),
                                ),
                                child: Icon(
                                  _shareIcon(opt['icon'] ?? ''),
                                  size: 19,
                                  color: shared ? Colors.white : AppColors.purple,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                opt['label'] ?? '',
                                style: AppTextStyles.hint12.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Report',
                      style: AppTextStyles.displaySemiBold135.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...MockData.REPORT_REASONS.map((reason) {
                      final id = reason['id'] as String;
                      final selected = _selectedReason == id;
                      return GestureDetector(
                        onTap: _reportSubmitted
                            ? null
                            : () => setState(() => _selectedReason = id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? AppColors.purple : AppColors.inputBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? AppColors.purple : AppColors.inputBorder,
                                    width: 2,
                                  ),
                                ),
                                child: selected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: AppGradients.button,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reason['label'] ?? '',
                                style: AppTextStyles.bodyRegular145.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SecondaryOutlineButton(
                      label: _reportSubmitted ? 'Reported' : 'Submit Report',
                      onPressed: _selectedReason != null && !_reportSubmitted
                          ? () => setState(() => _reportSubmitted = true)
                          : null,
                    ),
                    if (_reportSubmitted) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 16, color: AppColors.success.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thanks — our team will review this report.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _shareIcon(String key) => switch (key) {
        'link' => Icons.link,
        'whatsapp' => Icons.chat,
        'sms' => Icons.sms_outlined,
        'email' => Icons.email_outlined,
        _ => Icons.share_outlined,
      };
}
