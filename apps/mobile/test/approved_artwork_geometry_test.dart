import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/approved_artwork_geometry.dart';

void main() {
  test('approved source maps uniformly to the 576x1024 design canvas', () {
    expect(
      ApprovedArtworkGeometry.sourceToCanvas(const Offset(810, 1440)),
      const Offset(576, 1024),
    );
    expect(
      ApprovedArtworkGeometry.sourceRectToCanvas(
        const Rect.fromLTWH(0, 0, 810, 1440),
      ),
      ApprovedArtworkGeometry.referenceCanvas,
    );
    expect(
      ApprovedArtworkGeometry.nominalBoardRect,
      const Rect.fromLTWH(17, 205, 542, 542),
    );
  });

  test('nominal 15x15 cell centres are deterministic visual guides', () {
    const pitch = 542 / 15;
    expect(
      ApprovedArtworkGeometry.nominalCellCenter(0, 0),
      const Offset(17 + pitch / 2, 205 + pitch / 2),
    );
    expect(
      ApprovedArtworkGeometry.nominalCellCenter(14, 14),
      const Offset(17 + 14.5 * pitch, 205 + 14.5 * pitch),
    );
    expect(
      () => ApprovedArtworkGeometry.nominalCellCenter(-1, 0),
      throwsRangeError,
    );
    expect(
      () => ApprovedArtworkGeometry.nominalCellCenter(15, 0),
      throwsRangeError,
    );
  });

  test('portrait sizes preserve the entire source without stretching', () {
    for (final size in <Size>[
      const Size(360, 800),
      const Size(393, 873),
      const Size(412, 915),
    ]) {
      final scale = ApprovedArtworkGeometry.uniformScale(size);
      final origin = ApprovedArtworkGeometry.centeredOrigin(size);
      expect(origin.dx, greaterThanOrEqualTo(0));
      expect(origin.dy, greaterThanOrEqualTo(0));
      expect(
        576 * scale + origin.dx * 2,
        closeTo(size.width, 0.0001),
      );
      expect(
        1024 * scale + origin.dy * 2,
        closeTo(size.height, 0.0001),
      );
      expect(
        (576 * scale) / (1024 * scale),
        closeTo(9 / 16, 0.000001),
      );
    }
  });

  test('reference controls have independent touch regions on the canvas', () {
    expect(ApprovedArtworkGeometry.diceRect.center.dx, 288);
    expect(
      ApprovedArtworkGeometry.chatTouchRect.overlaps(
        ApprovedArtworkGeometry.moreTouchRect,
      ),
      isFalse,
    );
    expect(
      ApprovedArtworkGeometry.referenceCanvas.contains(
        ApprovedArtworkGeometry.chatTouchRect.center,
      ),
      isTrue,
    );
    expect(
      ApprovedArtworkGeometry.referenceCanvas.contains(
        ApprovedArtworkGeometry.moreTouchRect.center,
      ),
      isTrue,
    );
  });
}
