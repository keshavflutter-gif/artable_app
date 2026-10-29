import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/utils/formatters.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/referral/presentation/bloc/referral_cubit.dart';
import 'package:artable_app/features/referral/presentation/bloc/referral_state.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReferralCubit>().loadInvite();
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _inviteShareText(ReferralState state) {
    final code = state.invite?.code.trim() ?? '';
    final link = state.invite?.inviteLink.trim() ?? '';
    final shareMessage = state.invite?.shareMessage.trim() ?? '';
    if (shareMessage.isNotEmpty) return shareMessage;
    final buffer = StringBuffer('Join me on Artable!');
    if (code.isNotEmpty) {
      buffer.write('\nUse my referral code $code to sign up and earn rewards.');
    } else {
      buffer.write('\nSign up and earn rewards with me.');
    }
    if (link.isNotEmpty) buffer.write('\n$link');
    return buffer.toString();
  }

  Future<void> _onShareOptionTap(String label, ReferralState state) async {
    final text = _inviteShareText(state);
    const title = 'Join me on Artable!';
    final optionId = switch (label.toLowerCase()) {
      'whatsapp' => 'whatsapp',
      'sms' => 'sms',
      'email' => 'email',
      _ => 'social',
    };

    try {
      if (optionId == 'whatsapp') {
        final waUri = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(text)}',
        );
        final launched = await launchUrl(
          waUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } else if (optionId == 'sms') {
        final smsUri = Uri(scheme: 'sms', queryParameters: {'body': text});
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          return;
        }
      } else if (optionId == 'email') {
        final emailUri = Uri(
          scheme: 'mailto',
          queryParameters: {
            'subject': title,
            'body': text,
          },
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          return;
        }
      }

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null && box.hasSize)
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: title,
          title: title,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open share.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Invite Friends'),
          Expanded(
            child: BlocBuilder<ReferralCubit, ReferralState>(
              builder: (context, state) {
                final code = state.invite?.code ?? '';
                return SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: 12),
                  // Top Referral Code Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E2250),
                          Color(0xFF4C307A),
                          Color(0xFF6F32CD),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6F32CD).withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR REFERRAL CODE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Dashed Code Container
                        CustomPaint(
                          painter: _DashedBorderPainter(
                            color: Colors.white.withValues(alpha: 0.35),
                            strokeWidth: 1.2,
                            dashWidth: 6.0,
                            dashSpace: 4.0,
                            borderRadius: 16,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: state.isInviteLoading && code.isEmpty
                                ? const SizedBox(
                                    height: 28,
                                    child: Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    code.isNotEmpty ? code : '—',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Copy Code Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: code.isEmpty ? null : () => _copyCode(code),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    size: 15,
                                    color: AppColors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _copied ? 'Copied!' : 'Copy Code',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section: Invite via
                  const Text(
                    'Invite via',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Share Options Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ShareOptionItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        onTap: () => _onShareOptionTap('WhatsApp', state),
                      ),
                      _ShareOptionItem(
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                        onTap: () => _onShareOptionTap('SMS', state),
                      ),
                      _ShareOptionItem(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        onTap: () => _onShareOptionTap('Email', state),
                      ),
                      _ShareOptionItem(
                        icon: Icons.share_outlined,
                        label: 'Social Share',
                        onTap: () => _onShareOptionTap('Social Share', state),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info Note Card: Earn rewards for every friend
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x0F8B3DFF),
                          Color(0x0DFF8A3D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x248B3DFF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B3DFF).withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mail_outline_rounded,
                            size: 15,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earn rewards for every friend',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'You and your friend both get rewarded when they join and complete their first challenge.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Button: Track My Referrals
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B3DFF).withValues(alpha: 0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/referral-tracking'),
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: Text(
                              'Track My Referrals',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOptionItem extends StatelessWidget {
  const _ShareOptionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5F2FC),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 16.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace ||
        borderRadius != oldDelegate.borderRadius;
  }
}

class ReferralTrackingScreen extends StatefulWidget {
  const ReferralTrackingScreen({super.key});

  @override
  State<ReferralTrackingScreen> createState() => _ReferralTrackingScreenState();
}

class _ReferralTrackingScreenState extends State<ReferralTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReferralCubit>().loadTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Referral Tracking'),
          Expanded(
            child: BlocBuilder<ReferralCubit, ReferralState>(
              builder: (context, state) {
                if (state.isTrackingLoading && state.tracking == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                final items = state.tracking?.referrals ?? const [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No referrals yet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSoft,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: AppContent(
                    noBottomPad: true,
                    child: Column(
                      children: items.map((r) {
                        final dateLabel = r.date.isEmpty
                            ? ''
                            : AppFormatters.formatDate(r.date);
                        final subtitle = [
                          if (r.status.isNotEmpty) r.status,
                          if (dateLabel.isNotEmpty) dateLabel,
                        ].join(' · ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: r.avatarUrl.isNotEmpty
                                ? NetworkImage(r.avatarUrl)
                                : null,
                            backgroundColor: const Color(0xFFF5F2FC),
                            child: r.avatarUrl.isEmpty
                                ? Text(
                                    r.name.isNotEmpty
                                        ? r.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            r.name.isNotEmpty ? r.name : 'Artable user',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: AppTextStyles.bodySoft.copyWith(fontSize: 11),
                          ),
                          trailing: Text(
                            r.amount,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

