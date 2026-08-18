import 'package:flutter/material.dart';

import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/features/profile/presentation/widgets/profile_reward_widgets.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  static const _filters = [
    ('all', 'All'),
    ('live', 'Live'),
    ('under_review', 'Under Review'),
    ('draft', 'Drafts'),
    ('rejected', 'Rejected'),
  ];

  var _status = 'all';

  @override
  Widget build(BuildContext context) {
    final list = _status == 'all'
        ? MockData.MY_VIDEOS
        : MockData.MY_VIDEOS.where((v) => v['status'] == _status).toList();

    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackHeader(title: 'My Videos'),
          FilterPills(
            items: _filters.map((f) => f.$2).toList(),
            selected: _filters.firstWhere((f) => f.$1 == _status).$2,
            onSelected: (label) {
              setState(() {
                _status = _filters.firstWhere((f) => f.$2 == label).$1;
              });
            },
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyNote(message: 'No videos in this category.')
                : GridView.builder(
                    padding: const EdgeInsets.all(22),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => VideoGridCard(video: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
