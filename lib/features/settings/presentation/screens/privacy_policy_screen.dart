import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_typography.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import '../../data/models/privacy_policy_model.dart';
import '../../data/repositories/static_pages_repository.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};
  late final StaticPagesRepository _repository;

  bool _isLoading = true;
  String? _errorMessage;
  PrivacyPolicyData? _privacyData;

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    _repository = StaticPagesRepository(
      onTokensRefreshed: authCubit.applyRefreshedTokens,
      onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
    );
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authCubit = context.read<AuthCubit>();
      final token = authCubit.sessionToken;
      final refresh = authCubit.refreshToken;

      final data = await _repository.getPrivacyPolicy(
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      _sectionKeys.clear();
      for (var i = 0; i < data.sections.length; i++) {
        _sectionKeys[i] = GlobalKey();
      }

      if (mounted) {
        setState(() {
          _privacyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _privacyData?.title.isNotEmpty == true
        ? _privacyData!.title
        : 'Privacy Policy';

    return AppScreen(
      child: Column(
        children: [
          AppBackHeader(title: titleText),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.purple,
        ),
      );
    }

    if (_errorMessage != null && _privacyData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTypography.body(
                  fontSize: 13.5,
                  color: AppColors.textSoft,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPrivacyPolicy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _privacyData!;
    final lastUpdated = data.lastUpdated.isNotEmpty
        ? 'Last updated: ${data.lastUpdated}'
        : '';
    final tabs = data.tabs;
    final sections = data.sections;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastUpdated.isNotEmpty) ...[
            Text(
              lastUpdated,
              style: AppTypography.body(
                fontSize: 11.5,
                color: AppColors.textFaint,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (tabs.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(tabs.length, (index) {
                return GestureDetector(
                  onTap: () => _scrollToSection(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tabs[index],
                      style: AppTypography.body(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
          ...List.generate(sections.length, (index) {
            final item = sections[index];
            return Padding(
              key: _sectionKeys[index],
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.display(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: AppTypography.body(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
