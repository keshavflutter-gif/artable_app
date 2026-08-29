import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/utils/mock_helpers.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:artable_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:artable_app/features/settings/presentation/screens/logout_delete_confirm_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthCubit, String>((vm) => vm.userName);
    final currentUser = context.select<AuthCubit, Map<String, dynamic>>(
      (vm) => vm.currentUser,
    );
    final u = MockHelpers.currentUser;
    final name = userName;
    final handle = (currentUser['handle'] as String?)?.isNotEmpty == true
        ? currentUser['handle'] as String
        : u['handle'] as String;
    final avatarUrl = (currentUser['avatarUrl'] as String?)?.isNotEmpty == true
        ? currentUser['avatarUrl'] as String
        : u['avatarUrl'] as String;
    final emailHandle = handle.replaceAll('@', '');

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBackHeader(title: 'Settings'),
          Expanded(
            child: SingleChildScrollView(
              child: AppContent(
                noBottomPad: true,
                child: Column(
                  children: [
                    SettingsProfileCard(
                      avatarUrl: avatarUrl,
                      name: name,
                      handle: handle,
                      email: '$emailHandle@artable.app',
                      showPrime: u['prime'] == true,
                    ),
                    SettingsGroup(
                      title: 'Account',
                      children: [
                        SettingsMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Name, photo, bio, and links',
                          route: '/edit-profile',
                        ),
                        SettingsMenuItem(
                          icon: Icons.diamond_outlined,
                          title: 'Membership',
                          subtitle: 'Manage your Prime subscription',
                          route: '/membership-plan',
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Security',
                      children: [
                        SettingsMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Keep your account secure',
                          route: '/change-password',
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Notifications & Privacy',
                      children: [
                        SettingsMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notification Settings',
                          subtitle: 'Choose what you get notified about',
                          route: '/notification-settings',
                        ),
                        SettingsMenuItem(
                          icon: Icons.shield_outlined,
                          title: 'Privacy Settings',
                          subtitle: 'Control who sees your activity',
                          route: '/privacy-settings',
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Help & Legal',
                      children: [
                        SettingsMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'FAQs and contact options',
                          route: '/help-support',
                        ),
                        SettingsMenuItem(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          route: '/terms',
                        ),
                        SettingsMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          route: '/privacy-policy',
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Account Actions',
                      danger: true,
                      children: [
                        SettingsMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () => LogoutDeleteConfirmScreen.show(context, mode: 'logout'),
                        ),
                        SettingsMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          danger: true,
                          onTap: () => LogoutDeleteConfirmScreen.show(context, mode: 'delete'),
                        ),
                      ],
                    ),
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
