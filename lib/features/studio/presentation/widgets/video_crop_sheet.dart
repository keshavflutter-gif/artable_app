import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';

class VideoCropOption {
  const VideoCropOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.ratioWidth,
    required this.ratioHeight,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final double ratioWidth;
  final double ratioHeight;
}

class VideoCropSheet extends StatefulWidget {
  const VideoCropSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VideoCropSheet(),
    );
  }

  @override
  State<VideoCropSheet> createState() => _VideoCropSheetState();
}

class _VideoCropSheetState extends State<VideoCropSheet> {
  static const List<VideoCropOption> _options = [
    VideoCropOption(
      id: '9:16',
      label: '9:16 (Full Screen)',
      description: 'Best for Reels, Stories & TikTok',
      icon: Icons.crop_portrait_rounded,
      ratioWidth: 9,
      ratioHeight: 16,
    ),
    VideoCropOption(
      id: '1:1',
      label: '1:1 (Square)',
      description: 'Classic Feed Post',
      icon: Icons.crop_square_rounded,
      ratioWidth: 1,
      ratioHeight: 1,
    ),
    VideoCropOption(
      id: '4:5',
      label: '4:5 (Portrait)',
      description: 'Tall Instagram Feed Post',
      icon: Icons.crop_5_4_rounded,
      ratioWidth: 4,
      ratioHeight: 5,
    ),
    VideoCropOption(
      id: '16:9',
      label: '16:9 (Landscape)',
      description: 'Widescreen & YouTube format',
      icon: Icons.crop_landscape_rounded,
      ratioWidth: 16,
      ratioHeight: 9,
    ),
  ];

  late String _selectedCrop;

  @override
  void initState() {
    super.initState();
    _selectedCrop = context.read<StudioCubit>().state.videoCropAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DCEF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.crop,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Video Aspect Ratio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241E38),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select screen ratio for your video',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7A7090),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._options.map((option) {
            final isSelected = _selectedCrop == option.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _selectedCrop = option.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF4EDFF)
                        : const Color(0xFFFAFAFD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.purple
                          : const Color(0xFFECE7F6),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        color: isSelected
                            ? AppColors.purple
                            : const Color(0xFF8B80A5),
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.purple
                                    : const Color(0xFF241E38),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B80A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.purple,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Apply Crop',
            onPressed: () {
              context.read<StudioCubit>().setVideoCropAspectRatio(_selectedCrop);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
