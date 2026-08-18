import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/utils/format_utils.dart';
import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';

class PrizeTrackingScreen extends StatelessWidget {
  const PrizeTrackingScreen({super.key, this.rewardId});

  final String? rewardId;

  @override
  Widget build(BuildContext context) {
    // Fetch mock data
    final reward = MockHelpers.rewardById(rewardId);
    
    // Fallbacks matching the Nike Sponsor Kit in the Figma screen
    final prizeName = reward != null ? reward['title'] as String : 'Nike Sponsor Kit';
    final challengeName = reward != null ? reward['challengeName'] as String? ?? 'Street Sports Showdown' : 'Street Sports Showdown';
    final prizeImage = reward != null ? reward['imageUrl'] as String : 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=480&q=80'; 
    final wonDateText = reward != null ? 'Won on ${FormatUtils.formatDate(reward['dateClaimed'] as String? ?? '2026-07-02')}' : 'Won on Jul 2, 2026';

    // Mock tracking status
    final tracking = {
      'status': 'shipped',
      'estimatedDate': '2026-07-25',
      'trackingId': 'ATB-8834-IN',
    };

    final steps = [
      {'title': 'Winner Verified', 'subtext': 'Completed', 'status': 'completed'},
      {'title': 'Reward Approved', 'subtext': 'Completed', 'status': 'completed'},
      {'title': 'Prize Processing', 'subtext': 'Completed', 'status': 'completed'},
      {'title': 'Shipped / Delivered', 'subtext': 'In progress', 'status': 'active'},
    ];

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Prize Tracking'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Prize Item Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E2EAA).withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Rounded Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AppImage(
                              url: prizeImage,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PRIZE ITEM',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFFB7B1C6),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF9652FF), Color(0xFFFF5487)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'SHIPPED/DELIVERED',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  prizeName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  challengeName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  wonDateText,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFFB7B1C6),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid Info Cards (Estimated Delivery & Tracking ID)
                    Row(
                      children: [
                        // Estimated Delivery
                        Expanded(
                          child: _SummaryGridCard(
                            icon: Icons.calendar_today_rounded,
                            title: FormatUtils.formatDate(tracking['estimatedDate'] as String),
                            subtitle: 'EST. DELIVERY\nExpected shipping window',
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tracking ID
                        Expanded(
                          child: _SummaryGridCard(
                            icon: Icons.local_shipping_outlined,
                            title: tracking['trackingId'] as String,
                            subtitle: 'TRACKING ID\nCourier reference',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Delivery Status Timeline
                    const Text(
                      'Delivery Status',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Stepper Column
                    Column(
                      children: List.generate(steps.length, (i) {
                        final step = steps[i];
                        final isCompleted = step['status'] == 'completed';
                        final isActive = step['status'] == 'active';
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Timeline node + line
                            Column(
                              children: [
                                // Step node
                                if (isCompleted)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3EAFD),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF8B3DFF),
                                      size: 20,
                                    ),
                                  )
                                else if (isActive)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFF8F55), Color(0xFFFF5487)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.circle,
                                          color: Color(0xFFFF5487),
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFECE8F5), width: 2),
                                    ),
                                  ),
                                
                                // Vertical line
                                if (i < steps.length - 1)
                                  Container(
                                    width: 2.5,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          isCompleted ? const Color(0xFF8B3DFF) : const Color(0xFFECE8F5),
                                          steps[i+1]['status'] == 'completed' ? const Color(0xFF8B3DFF) : const Color(0xFFECE8F5),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Step texts
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title']!,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: const Color(0xFF241E38),
                                        fontWeight: isCompleted || isActive ? FontWeight.w800 : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step['subtext']!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: isCompleted
                                            ? const Color(0xFF21B573)
                                            : (isActive ? const Color(0xFF8B3DFF) : const Color(0xFFB7B1C6)),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    
                    // View Reward Detail Button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppGradients.button,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5487).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (reward != null) {
                              context.push('/reward-detail?id=${reward['id']}');
                            }
                          },
                          borderRadius: BorderRadius.circular(27),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Reward Detail',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Need Help Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3EAFD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_toggle_off_rounded,
                              color: Color(0xFF8B3DFF),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need help?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Contact support for delivery updates.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF8B849C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFB7B1C6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGridCard extends StatelessWidget {
  const _SummaryGridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EAFD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B3DFF),
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFB7B1C6),
                    fontWeight: FontWeight.w600,
                    fontSize: 7.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
