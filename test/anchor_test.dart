import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/box.dart';
import 'package:flutter_portal/src/anchor.dart';
import 'package:flutter_portal/src/portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('$Anchor is passed proper constraints', (tester) async {
    Rect? constraintsTargetRect;
    BoxConstraints? constraintsOverlayConstraints;
    Size? offsetSourceSize;
    Rect? offsetTargetRect;
    Rect? offsetTheaterRect;
    final anchor = _TestAnchor(
      constraints: const BoxConstraints.tightFor(
        width: 42,
        height: 42,
      ),
      onGetSourceConstraints: (targetRect, overlayConstraints) {
        constraintsTargetRect = targetRect;
        constraintsOverlayConstraints = overlayConstraints;
      },
      onGetSourceOffset: (sourceSize, targetRect, theaterRect) {
        offsetSourceSize = sourceSize;
        offsetTargetRect = targetRect;
        offsetTheaterRect = theaterRect;
      },
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: Colors.green,
              child: Portal(
                child: Center(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: PortalTarget(
                        anchor: anchor,
                        portalFollower: const ColoredBox(
                          color: Colors.red,
                        ),
                        child: const Center(
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    expect(constraintsTargetRect, Offset.zero & const Size(50, 50));
    expect(
      constraintsOverlayConstraints,
      BoxConstraints.tight(const Size(100, 100)),
    );
    expect(constraintsTargetRect, offsetTargetRect);
    expect(offsetSourceSize, const Size(42, 42));
    expect(offsetTheaterRect, const Offset(-25, -25) & const Size(100, 100));
  });

  testWidgets('$Aligned defers to backup if needed', (tester) async {
    var offsetAccessed = false;
    final backupAligned = _TestAligned(
      source: Alignment.bottomLeft,
      target: Alignment.topLeft,
      onGetSourceOffset: () => offsetAccessed = true,
    );
    final entry = PortalTarget(
      anchor: Aligned(
        source: Alignment.topLeft,
        target: Alignment.bottomLeft,
        backup: backupAligned,
      ),
      portalFollower: const SizedBox(
        width: 20,
        height: 20,
      ),
      child: const SizedBox(
        width: 10,
        height: 10,
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: Portal(
              child: Center(
                child: entry,
              ),
            ),
          ),
        ),
      ),
    ));

    expect(offsetAccessed, false);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 50,
            height: 49,
            child: Portal(
              child: Center(
                child: entry,
              ),
            ),
          ),
        ),
      ),
    ));

    expect(offsetAccessed, true);
  });
}

class _TestAnchor implements Anchor {
  const _TestAnchor({
    required this.constraints,
    required this.onGetSourceConstraints,
    required this.onGetSourceOffset,
  });

  final BoxConstraints constraints;

  final void Function(
    Rect targetRect,
    BoxConstraints overlayConstraints,
  ) onGetSourceConstraints;
  final void Function(
    Size sourceSize,
    Rect targetRect,
    Rect theaterRect,
  ) onGetSourceOffset;

  @override
  BoxConstraints getFollowerConstraints({
    required Rect targetRect,
    required BoxConstraints portalConstraints,
  }) {
    onGetSourceConstraints(targetRect, portalConstraints);
    return constraints;
  }

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Rect targetRect,
    required Rect portalRect,
  }) {
    onGetSourceOffset(followerSize, targetRect, portalRect);
    return Offset.zero;
  }
}

class _TestAligned extends Aligned {
  const _TestAligned({
    required Alignment source,
    required Alignment target,
    Offset offset = Offset.zero,
    double? widthFactor,
    double? heightFactor,
    required this.onGetSourceOffset,
  }) : super(
            source: source,
            target: target,
            offset: offset,
            widthFactor: widthFactor,
            heightFactor: heightFactor);

  final VoidCallback onGetSourceOffset;

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Rect targetRect,
    required Rect portalRect,
  }) {
    onGetSourceOffset();
    return super.getFollowerOffset(
      followerSize: followerSize,
      targetRect: targetRect,
      portalRect: portalRect,
    );
  }
}
