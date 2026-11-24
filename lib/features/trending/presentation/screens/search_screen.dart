import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:artable_app/core/widgets/app_back_header.dart';
import 'package:artable_app/core/widgets/app_scaffold.dart';
import 'package:artable_app/core/widgets/filter_pills.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  void _goResults([String? q]) {
    final query = (q ?? _controller.text).trim();
    context.push('/search-results?q=${Uri.encodeComponent(query)}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackHeader(title: 'Search'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSearchBar(
                    controller: _controller,
                    onSubmitted: _goResults,
                  ),
                  const AppContent(
                    noBottomPad: true,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: EmptyNote(
                        message:
                            'Search creators, videos, and challenges using the bar above.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
