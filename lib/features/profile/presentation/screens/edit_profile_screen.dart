import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_gradients.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _category;
  late final TextEditingController _social;
  String _coverUrl = '';
  String _avatarUrl = '';
  var _saved = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    final initialFullName = auth.fullName.isNotEmpty
        ? auth.fullName
        : (auth.currentUser['fullName'] as String? ?? '');
    _name = TextEditingController(text: initialFullName);

    final initialUsername = auth.username.isNotEmpty
        ? auth.username
        : ((auth.currentUser['handle'] as String?)?.replaceAll('@', '') ?? '');
    _username = TextEditingController(text: initialUsername);

    _bio = TextEditingController(
      text: (auth.currentUser['bio'] as String?) ?? '',
    );
    _category = TextEditingController(
      text: (auth.currentUser['category'] as String?) ?? '',
    );
    _social = TextEditingController(
      text: _extractSocialLinkUrl(auth.currentUser['socialLinks']),
    );
    _coverUrl = auth.currentUser['coverUrl'] as String? ?? _coverUrl;
    _avatarUrl = auth.currentUser['avatarUrl'] as String? ?? _avatarUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final auth = context.read<AuthCubit>();
    final user = await auth.fetchUserDetails();
    if (!mounted) return;
    if (user != null) {
      setState(() {
        if (auth.fullName.isNotEmpty) {
          _name.text = auth.fullName;
        } else if (user.fullName.isNotEmpty) {
          _name.text = user.fullName;
        }
        if (auth.username.isNotEmpty) {
          _username.text = auth.username;
        } else if (user.username != null && user.username!.isNotEmpty) {
          _username.text = user.username!;
        }
        if (auth.bio.isNotEmpty) {
          _bio.text = auth.bio;
        } else if (user.bio != null && user.bio!.isNotEmpty) {
          _bio.text = user.bio!;
        }
        if (auth.category.isNotEmpty) {
          _category.text = auth.category;
        } else if (user.category != null && user.category!.isNotEmpty) {
          _category.text = user.category!;
        }
        final socialUrl = _extractSocialLinkUrl(user.socialLinks);
        if (socialUrl.isNotEmpty && socialUrl != 'https://') {
          _social.text = socialUrl;
        }
        if (auth.avatarUrl.isNotEmpty) {
          _avatarUrl = auth.avatarUrl;
        } else if (user.profilePhotoUrl != null &&
            user.profilePhotoUrl!.isNotEmpty) {
          _avatarUrl = user.profilePhotoUrl!;
        }
        if (auth.coverUrl.isNotEmpty) {
          _coverUrl = auth.coverUrl;
        } else if (user.coverImageUrl != null &&
            user.coverImageUrl!.isNotEmpty) {
          _coverUrl = user.coverImageUrl!;
        }
      });
    }
  }

  static String _extractSocialLinkUrl(dynamic source) {
    if (source is List && source.isNotEmpty) {
      final first = source.first;
      if (first is Map) {
        final url = first['url']?.toString() ??
            first['websiteUrl']?.toString() ??
            first['website']?.toString();
        if (url != null && url.isNotEmpty && url != '#') {
          return url;
        }
      }
    } else if (source is Map) {
      final url = source['websiteUrl']?.toString() ??
          source['url']?.toString() ??
          source['instagramUrl']?.toString() ??
          source['youtubeUrl']?.toString();
      if (url != null && url.isNotEmpty && url != '#') {
        return url;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _category.dispose();
    _social.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthCubit>();
    if (auth.isUpdatingProfile) return;

    final fullName = _name.text.trim();
    final username = _username.text.trim();
    final bio = _bio.text.trim();
    final category = _category.text.trim();
    final social = _social.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }

    final success = await auth.saveProfile(
      fullName: fullName,
      username: username,
      bio: bio,
      category: category,
      socialLinkUrl: social,
    );
    if (!mounted) return;

    if (success) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) context.pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Unable to update profile. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned App Back Header
          const AppBackHeader(title: 'Edit Profile'),

          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Cover Photo & Centered Overlapping Avatar Header
                    _buildCoverAndAvatarHeader(_coverUrl, _avatarUrl),
                    const SizedBox(height: 52),

                    // 2. BASIC INFO Card
                    _buildSectionCard(
                      title: 'BASIC INFO',
                      children: [
                        _buildInputField(
                          label: 'Full Name',
                          controller: _name,
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          label: 'Username',
                          controller: _username,
                          readOnly: true,
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          label: 'Bio',
                          controller: _bio,
                          maxLines: 3,
                        ),
                      ],
                    ),

                    // 3. TALENT Card
                    _buildSectionCard(
                      title: 'TALENT',
                      children: [
                        _buildInputField(
                          label: 'Talent Category',
                          controller: _category,
                        ),
                      ],
                    ),

                    // 4. SOCIAL LINKS Card
                    _buildSectionCard(
                      title: 'SOCIAL LINKS',
                      children: [
                        _buildInputField(
                          label: 'Instagram / YouTube / Website',
                          controller: _social,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_saved)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Profile saved successfully!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),

                    // 5. Bottom Action Buttons: Cancel & Save Changes
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: const Color(0xFFECE8F5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5E2EAA).withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF241E38),
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Save Changes Button
                        Expanded(
                          child: GestureDetector(
                            onTap: context.select<AuthCubit, bool>((vm) => vm.isUpdatingProfile)
                                ? null
                                : _save,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppGradients.button,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5487).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: context.select<AuthCubit, bool>((vm) => vm.isUpdatingProfile)
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Cover Photo & Avatar Header Widget ---
  Widget _buildCoverAndAvatarHeader(String coverUrl, String avatarUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Cover Photo Banner
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              AppImage(
                url: coverUrl,
                height: 125, // Adjusted to match Figma ratio
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Change Cover',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Centered Overlapping Avatar with Camera Change Badge
        Positioned(
          bottom: -40,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5E2EAA).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: AppImage(
                    url: avatarUrl,
                    width: 80, // Size 80
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Camera Icon Badge on Bottom-Right of Avatar
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF3D77),
                        Color(0xFF8B3DFF),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3D77).withValues(alpha: 0.38),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. Section Card Container ---
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECE8F5), // Lavender-grey border
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2EAA).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF8B849C),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // --- 3. Custom Input Field ---
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B849C), // Label color matching Figma
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF2F0F7) : const Color(0xFFF8F7FC), // Background Color
            borderRadius: BorderRadius.circular(16), // Rounded 16px
            border: Border.all(
              color: const Color(0xFFECE8F5), // Lavender-grey border
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            enableInteractiveSelection: !readOnly,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: readOnly ? const Color(0xFF6E687F) : const Color(0xFF241E38),
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: maxLines > 1 ? 12 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
