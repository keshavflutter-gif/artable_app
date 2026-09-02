import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_cubit.dart';
import 'package:artable_app/features/studio/presentation/bloc/studio_state.dart';
import 'package:artable_app/features/studio/data/models/studio_filters_response.dart';
import 'package:artable_app/core/utils/app_filter_utils.dart';
import 'package:artable_app/core/utils/reel_helpers.dart';
import 'package:artable_app/core/widgets/app_network_image.dart';
import 'package:artable_app/core/widgets/gradient_button.dart';

class StudioFiltersScreen extends StatefulWidget {
  const StudioFiltersScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  State<StudioFiltersScreen> createState() => _StudioFiltersScreenState();
}

class _StudioFiltersScreenState extends State<StudioFiltersScreen> {
  late String _selectedFilter;
  late String _selectedSpeed;
  late bool _beautyOn;
  late double _beautyIntensity;

  @override
  void initState() {
    super.initState();
    final studio = context.read<StudioCubit>();
    _selectedFilter = studio.selectedFilter;
    _selectedSpeed = studio.selectedSpeed.replaceAll('x', '');
    _beautyOn = studio.beautyOn;
    _beautyIntensity = studio.beautyIntensity;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudioCubit>().loadFiltersConfig();
      }
    });
  }

  void _applyFilters() {
    final studio = context.read<StudioCubit>();
    studio.setFilter(_selectedFilter);
    studio.setSpeed('${_selectedSpeed}x');
    studio.setBeautyOn(_beautyOn);
    studio.setBeautyIntensity(_beautyIntensity);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ReelHelpers.challengeById(widget.challengeId ?? 'c1')!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<StudioCubit, StudioState>(
        builder: (context, state) {
          final config = state.filtersConfig;
          final filtersList = config?.filters ??
              const [
                StudioFilterItem(key: 'natural', name: 'Natural'),
                StudioFilterItem(key: 'glow', name: 'Glow'),
                StudioFilterItem(key: 'warm', name: 'Warm'),
                StudioFilterItem(key: 'studio', name: 'Studio'),
                StudioFilterItem(key: 'beauty', name: 'Beauty'),
              ];

          final speedsList = config?.speeds.map((s) {
                final sStr = s.toString();
                return sStr.endsWith('.0') ? sStr.substring(0, sStr.length - 2) : sStr;
              }).toList() ??
              const ['0.5', '1', '1.5', '2'];

          final showBeauty = config?.beautyFilterAvailable ?? true;

          return Column(
            children: [
              SizedBox(
                height: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Live Real-Time Filtered Preview Header
                    AppFilterUtils.buildFilteredView(
                      filterId: _selectedFilter,
                      beautyOn: _beautyOn,
                      beautyIntensity: _beautyIntensity,
                      child: AppNetworkImage(
                        url: challenge['imageUrl'] as String,
                        fit: BoxFit.cover,
                        alt: 'preview',
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0x8C0A0519),
                            const Color(0xBF0A0519),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.85),
                      child: Text(
                        'Effects & Filters',
                        style: AppTypography.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a Filter',
                        style: AppTypography.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 105,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: filtersList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, i) {
                            final item = filtersList[i];
                            final preset = AppFilterUtils.presets.firstWhere(
                              (p) => p.id.toLowerCase() == item.key.toLowerCase(),
                              orElse: () => FilterPreset(
                                id: item.key,
                                label: item.name,
                                icon: Icons.auto_awesome,
                                gradient: const [Color(0xFFC9C2FF), Color(0xFF8B3DFF)],
                              ),
                            );
                            final active = _selectedFilter == preset.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilter = preset.id),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 56,
                                    height: 56,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: active
                                          ? Border.all(color: AppColors.purple, width: 2.5)
                                          : Border.all(color: Colors.transparent, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: active
                                              ? AppColors.purple.withValues(alpha: 0.35)
                                              : const Color(0xFF5E2EAA).withValues(alpha: 0.12),
                                          blurRadius: active ? 12 : 6,
                                          spreadRadius: active ? 2.5 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: preset.gradient),
                                      ),
                                      child: Icon(
                                        preset.icon,
                                        size: 22,
                                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.name.isNotEmpty ? item.name : preset.label,
                                    style: AppTypography.body(
                                      fontSize: 11,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                      color: active ? AppColors.purple : AppColors.textSoft,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Speed',
                        style: AppTypography.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: speedsList.map((speed) {
                          final active = _selectedSpeed == speed;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedSpeed = speed),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    gradient: active ? AppGradients.button : null,
                                    color: active ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: active
                                        ? null
                                        : Border.all(color: AppColors.inputBorder, width: 1.5),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: AppColors.purple.withValues(alpha: 0.25),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${speed}x',
                                    style: AppTypography.display(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: active ? Colors.white : AppColors.textSoft,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (showBeauty) ...[
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beauty Filter',
                              style: AppTypography.display(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            Switch(
                              value: _beautyOn,
                              activeTrackColor: AppColors.purple,
                              onChanged: (v) => setState(() => _beautyOn = v),
                            ),
                          ],
                        ),
                        if (_beautyOn) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Intensity',
                                style: AppTypography.body(
                                  fontSize: 11.5,
                                  color: AppColors.textSoft,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_beautyIntensity.round()}%',
                                style: AppTypography.display(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _beautyIntensity,
                            min: 0,
                            max: 100,
                            activeColor: AppColors.purple,
                            inactiveColor: AppColors.purple.withValues(alpha: 0.15),
                            onChanged: (v) => setState(() => _beautyIntensity = v),
                          ),
                        ],
                      ],
                      const SizedBox(height: 32),
                      GradientButton(
                        label: 'Apply',
                        onPressed: _applyFilters,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


