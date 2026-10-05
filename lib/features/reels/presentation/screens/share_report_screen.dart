import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/data/datasources/mock_data.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_screen_header.dart';
import 'package:artable_app/core/widgets/secondary_outline_button.dart';

import 'package:artable_app/core/utils/video_share_helper.dart';

const String _whatsappSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="currentColor" d="M19.05 4.95A9.87 9.87 0 0 0 12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2.05 22l5.25-1.38c1.45.79 3.08 1.21 4.74 1.21h.01c5.46 0 9.91-4.45 9.91-9.91 0-2.65-1.03-5.14-2.91-7.02zm-7.01 15.17h-.01c-1.48 0-2.93-.4-4.2-1.15l-.3-.18-3.12.82.83-3.04-.2-.32a8.217 8.217 0 0 1-1.26-4.38c0-4.54 3.7-8.24 8.24-8.24 2.2 0 4.27.86 5.82 2.42a8.18 8.18 0 0 1 2.41 5.83c0 4.54-3.7 8.24-8.21 8.24zm4.51-6.16c-.25-.12-1.47-.72-1.69-.8-.23-.08-.39-.12-.56.12-.17.25-.66.8-.81.97-.15.17-.3.19-.55.07-.25-.12-1.05-.39-2-1.23-.74-.66-1.24-1.47-1.39-1.72-.15-.25-.02-.38.11-.5.11-.11.25-.29.37-.43.12-.15.17-.25.25-.42.08-.17.04-.31-.02-.43s-.56-1.35-.77-1.85c-.2-.48-.41-.42-.56-.43h-.48c-.17 0-.44.06-.67.31-.23.25-.87.85-.87 2.07 0 1.22.89 2.4 1.01 2.56.12.17 1.75 2.67 4.24 3.74.59.26 1.05.41 1.41.52.59.19 1.13.16 1.56.1.48-.07 1.47-.6 1.67-1.18.2-.58.2-1.08.14-1.18-.06-.1-.23-.16-.48-.28z"/>
</svg>
''';

class ShareReportScreen extends StatefulWidget {
  const ShareReportScreen({
    super.key,
    this.reelId,
    this.videoUrl,
    this.title,
    this.caption,
  });

  final String? reelId;
  final String? videoUrl;
  final String? title;
  final String? caption;

  @override
  State<ShareReportScreen> createState() => _ShareReportScreenState();
}

class _ShareReportScreenState extends State<ShareReportScreen> {
  String? _selectedReason;
  bool _reportSubmitted = false;
  String? _sharedOptionId;

  @override
  Widget build(BuildContext context) {
    final reel = ReelHelpers.reelById(widget.reelId ?? 'r1');
    final rawUrl = (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty)
        ? widget.videoUrl!.trim()
        : (reel?['videoUrl']?.toString() ?? reel?['video_url']?.toString() ?? '');
    final resolvedUrl = (rawUrl.isNotEmpty && rawUrl != 'null')
        ? rawUrl
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    final resolvedTitle = widget.title ?? reel?['title']?.toString();
    final resolvedCaption = widget.caption ?? reel?['caption']?.toString();

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
                          onTap: () async {
                            setState(() => _sharedOptionId = id);
                            await VideoShareHelper.shareVideo(
                              context: context,
                              optionId: id,
                              videoUrl: resolvedUrl,
                              title: resolvedTitle,
                              caption: resolvedCaption,
                            );
                            if (mounted) {
                              setState(() => _sharedOptionId = null);
                            }
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
                                child: shared
                                    ? const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                    : _buildShareIcon(opt['icon'] ?? ''),
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

  Widget _buildShareIcon(String key) {
    if (key == 'whatsapp') {
      return Center(
        child: SvgPicture.string(
          _whatsappSvg,
          width: 19,
          height: 19,
          colorFilter: const ColorFilter.mode(AppColors.purple, BlendMode.srcIn),
        ),
      );
    }
    final iconData = switch (key) {
      'link' => Icons.link_rounded,
      'sms' => Icons.sms_outlined,
      'email' => Icons.email_outlined,
      _ => Icons.share_outlined,
    };
    return Icon(
      iconData,
      size: 19,
      color: AppColors.purple,
    );
  }
}

