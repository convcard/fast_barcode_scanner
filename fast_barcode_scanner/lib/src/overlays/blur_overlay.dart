import 'dart:ui';

import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
import 'package:flutter/material.dart';

class BlurPreviewOverlay extends StatelessWidget {
  final double blurAmount;
  final Duration duration;

  const BlurPreviewOverlay({super.key, this.blurAmount = 30, this.duration = const Duration(milliseconds: 500)});

  bool shouldBlur(event) => event == ScannerEvent.detected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CameraController.shared.eventNotifier,
      builder: (context, event, child) {
        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: shouldBlur(event) ? blurAmount : 0.0),
          duration: duration,
          curve: Curves.easeOut,
          child: Container(color: Colors.black.withOpacity(0.0)),
          builder: (_, value, child) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: value, sigmaY: value),
            child: child,
          ),
        );
      },
    );
  }
}
