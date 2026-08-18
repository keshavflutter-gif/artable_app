import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/app/theme/app_colors.dart';
import 'package:artable_app/app/theme/app_text_styles.dart';
import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_image.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';
import 'package:artable_app/data/datasources/mock_data.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  static const _tabs = ['All', 'Trending', 'Popular', 'New'];
  var _tab = 'All';

  List<Map<String, dynamic>> get _tracks {
    if (_tab == 'All') return MockData.MUSIC_LIBRARY_TRACKS;
    return MockData.MUSIC_LIBRARY_TRACKS
        .where((t) => (t['category'] as String) == _tab.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        children: [
          const AppBackHeader(title: 'Music Library'),
          FilterPills(items: _tabs, selected: _tab, onSelected: (t) => setState(() => _tab = t)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(22),
              itemCount: _tracks.length,
              itemBuilder: (_, i) {
                final t = _tracks[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImage(url: t['coverUrl'] as String, width: 52, height: 52),
                  ),
                  title: Text(t['title'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${t['artist']} · ${t['duration']}', style: AppTextStyles.bodySoft.copyWith(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t['saved'] == true)
                        const Icon(Icons.bookmark, color: AppColors.purple, size: 18),
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: AppColors.purple),
                        onPressed: () => context.push('/music-preview?id=${t['id']}'),
                      ),
                    ],
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

