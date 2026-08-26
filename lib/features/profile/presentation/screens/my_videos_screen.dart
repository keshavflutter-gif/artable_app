import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_cubit.dart';
import 'package:artable_app/features/profile/presentation/bloc/my_videos_state.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  static const _defaultFilterTabs = [
    ('ALL', 'All'),
    ('LIVE', 'Live'),
    ('UNDER_REVIEW', 'Under Review'),
    ('DRAFTS', 'Drafts'),
    ('REJECTED', 'Rejected'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<MyVideosCubit>();
      if (!cubit.hasLoaded && !cubit.isLoading) {
        cubit.loadMyVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyVideosCubit, MyVideosState>(
      builder: (context, state) {
        final cubit = context.read<MyVideosCubit>();

        // Extract tab pills dynamically from API tabs if available, else fallback
        final dynamicTabs = state.tabs.isNotEmpty
            ? state.tabs.map((t) => (t.key, t.label)).toList()
            : _defaultFilterTabs;

        final activeTabKey = state.activeTab;
        final selectedTabLabel = dynamicTabs
            .firstWhere(
              (t) => t.$1 == activeTabKey,
              orElse: () => dynamicTabs.first,
            )
            .$2;

        final list = state.videos;
        final emptyState = state.emptyState;
        final emptyMsg = emptyState?.message.isNotEmpty == true
            ? emptyState!.message
            : 'No videos in this category.';

        return AppScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackHeader(title: 'My Videos'),
              FilterPills(
                items: dynamicTabs.map((f) => f.$2).toList(),
                selected: selectedTabLabel,
                onSelected: (label) {
                  final target = dynamicTabs.firstWhere((f) => f.$2 == label);
                  cubit.selectTab(target.$1);
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cubit.loadMyVideos(forceRefresh: true),
                  child: state.isLoading && list.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : list.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: EmptyNote(message: emptyMsg),
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(22),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: list.length,
                              itemBuilder: (_, i) =>
                                  VideoGridCard(video: list[i].toUiMap()),
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
