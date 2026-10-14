import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden images are rendered with the test font (boxes instead of glyphs),
/// so they catch layout regressions. A small tolerance absorbs anti-aliasing
/// differences between developer machines and the CI runner.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final local = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = _TolerantComparator(local.basedir.resolve('golden_test.dart'));
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  /// Maximum fraction of differing pixels (0.5 %).
  static const tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}
