import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import '../../data/models/faq_model.dart';
import '../../data/repositories/static_pages_repository.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();
  String? _expandedFaqId;
  late final StaticPagesRepository _repository;

  bool _isLoading = true;
  String? _errorMessage;
  List<FaqItem> _faqs = [];
  String _searchQuery = '';

  final List<Map<String, dynamic>> _topics = const [
    {
      'id': 'challenges',
      'title': 'Challenge Participation',
      'icon': Icons.emoji_events_outlined,
    },
    {
      'id': 'studio',
      'title': 'Recording Studio',
      'icon': Icons.videocam_outlined,
    },
    {
      'id': 'rewards',
      'title': 'Rewards & Wallet',
      'icon': Icons.card_membership_outlined,
    },
    {
      'id': 'prime',
      'title': 'Prime Membership',
      'icon': Icons.diamond_outlined,
    },
    {
      'id': 'privacy',
      'title': 'Account & Privacy',
      'icon': Icons.lock_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    _repository = StaticPagesRepository(
      onTokensRefreshed: authCubit.applyRefreshedTokens,
      onSessionRefreshFailed: authCubit.handleSessionRefreshFailed,
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authCubit = context.read<AuthCubit>();
      final token = authCubit.sessionToken;
      final refresh = authCubit.refreshToken;

      final faqs = await _repository.getFaqs(
        sessionToken: token != 'design_preview' ? token : null,
        refreshToken: refresh != 'design_preview' ? refresh : null,
      );

      faqs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (mounted) {
        setState(() {
          _faqs = faqs;
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
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(_searchQuery) ||
          faq.answer.toLowerCase().contains(_searchQuery) ||
          faq.category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Help & Support'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: const Color(0xFF8B3DFF),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF241E38),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          filled: false,
                          hintText: 'Search help topics...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFFB5ADC8),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF958CAE),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Quick Help" Title
                    const Text(
                      'Quick Help',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Help 2-Column Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topics.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (context, index) {
                        final topic = _topics[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5E2EAA).withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3EAFD),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  topic['icon'] as IconData,
                                  color: const Color(0xFF8B3DFF),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  topic['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // "Frequently Asked Questions" Title
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF241E38),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // FAQs Expandable Cards
                    _buildFaqsSection(),

                    const SizedBox(height: 16),

                    // "Need more help?" Contact Banner Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFFECEF), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3D77).withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF8F55), Color(0xFFFF5487)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Need more help?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF241E38),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Our team is here for you.',
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
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Support chat opened.'),
                                  backgroundColor: Color(0xFF8B3DFF),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5487).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Contact Support',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // "Submit a support request" Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F7FC),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Color(0xFF8B849C),
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Submit a support request',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF241E38),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
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

  Widget _buildFaqsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B3DFF),
          ),
        ),
      );
    }

    if (_errorMessage != null && _faqs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF8B849C),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchFaqs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B3DFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredList = _filteredFaqs;

    if (filteredList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
        ),
        child: const Center(
          child: Text(
            'No FAQs found.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF8B849C),
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredList.map((faq) {
        final isExpanded = _expandedFaqId == faq.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECE8F5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E2EAA).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF241E38),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFB7B1C6),
                ),
                onTap: () {
                  setState(() {
                    _expandedFaqId = isExpanded ? null : faq.id;
                  });
                },
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF8B849C),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
