import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:artable_app/core/di/app_blocs.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';

class ArtableApp extends StatelessWidget {
  const ArtableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: AppBlocs.providers,
      child: MaterialApp.router(
        title: 'Artable',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const ClampingScrollPhysics(),
        ),
      ),
    );
  }
}
