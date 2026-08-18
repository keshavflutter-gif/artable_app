import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = 1024.0;
  const outputPath = 'assets/logo.png';
  final svgFile = File('assets/logo.svg');

  final key = GlobalKey();

  testWidgets('Generate launcher icon PNG from logo.svg', (tester) async {
    await tester.binding.setSurfaceSize(const Size(size, size));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: Colors.white,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: size * 0.82,
                height: size * 0.82,
                child: SvgPicture.file(
                  svgFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    await tester.binding.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(outputPath).writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
