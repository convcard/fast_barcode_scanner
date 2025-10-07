import 'dart:async';

import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
import 'package:fast_barcode_scanner_platform_interface/fast_barcode_scanner_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ScannerState {
  final PreviewConfiguration? cameraInformation;
  final ScannerConfiguration? scannerConfig;
  final bool torch;
  final Error? error;

  bool get isInitialized => scannerConfig != null && cameraInformation != null;

  const ScannerState.uninitialized() : cameraInformation = null, scannerConfig = null, torch = false, error = null;

  ScannerState(this.cameraInformation, this.scannerConfig, this.torch, this.error);

  ScannerState withTorch(bool active) {
    return ScannerState(cameraInformation, scannerConfig, active, error);
  }

  ScannerState withError(Error error) {
    return ScannerState(null, null, torch, error);
  }

  @override
  String toString() {
    return 'ScannerState{cameraInformation: $cameraInformation, scannerConfig: $scannerConfig, torch: $torch, error: $error}';
  }
}

/// This class is purely for convinience. You can use [MethodChannelFastBarcodeScanner]
/// or even [FastBarcodeScannerPlatform] directly, if you so wish.
class CameraController {
  CameraController._internal() : super();
  static final shared = CameraController._internal();

  StreamSubscription? _scanSilencerSubscription;

  final _platform = FastBarcodeScannerPlatform.instance;

  DateTime? _lastScanTime;

  final state = ValueNotifier(const ScannerState.uninitialized());
  final resultNotifier = ValueNotifier(List<Barcode>.empty());
  final eventNotifier = ValueNotifier(ScannerEvent.uninitialized);

  static const scannedCodeTimeout = Duration(milliseconds: 250);

  /// A lock that prevents additional commands to the platform side.
  ///
  /// Locks while the platfrom is configuring the camera.
  bool _isConfiguringLock = false;

  /// User-defined handler that is called on barcode detection.
  OnDetectionHandler? _onScan;

  /// Builds a wrapper for [_onScan].
  ///
  /// This ensures that each scan receipt is done consistently.
  /// We log [_lastScanTime] and update the [resultNotifier] ValueNotifier
  OnDetectionHandler _buildScanHandler(OnDetectionHandler? onScan) {
    return (barcodes) {
      _lastScanTime = DateTime.now();
      resultNotifier.value = barcodes;
      onScan?.call(barcodes);
    };
  }

  Future<void> initialize({
    required List<BarcodeType> types,
    required Resolution resolution,
    required Framerate framerate,
    required CameraPosition position,
    required DetectionMode mode,
    required ApiMode api,
    OnDetectionHandler? onScan,
  }) async {
    try {
      print('[FAST_BARCODE_SCANNER] init');
      final cameraInfo = await _platform.init(types, resolution, framerate, mode, position, api);

      _onScan = _buildScanHandler(onScan);

      _scanSilencerSubscription = Stream.periodic(scannedCodeTimeout).listen((event) {
        final scanTime = _lastScanTime;
        if (scanTime != null && DateTime.now().difference(scanTime) > scannedCodeTimeout) {
          // it's been too long since we've seen a scanned code, clear the list
          resultNotifier.value = const <Barcode>[];
        }
      });

      _platform.setOnDetectHandler(_onDetectHandler);

      final scanner = ScannerConfiguration(types, resolution, framerate, mode, position);

      state.value = ScannerState(cameraInfo, scanner, false, null);
      eventNotifier.value = ScannerEvent.resumed;
      print('[FAST_BARCODE_SCANNER] initialized');
    } on Error catch (error) {
      print('[FAST_BARCODE_SCANNER] init error $error');
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      print('[FAST_BARCODE_SCANNER] init fatal error $error');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _platform.dispose();
      state.value = const ScannerState.uninitialized();
      eventNotifier.value = ScannerEvent.uninitialized;
      _scanSilencerSubscription?.cancel();
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> pauseCamera() async {
    try {
      await _platform.stop();
      eventNotifier.value = ScannerEvent.paused;
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> resumeCamera() async {
    try {
      await _platform.start();
      eventNotifier.value = ScannerEvent.resumed;
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> pauseScanner() async {
    try {
      await _platform.stopDetector();
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> resumeScanner() async {
    try {
      await _platform.startDetector();
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> toggleTorch() async {
    if (!state.value.isInitialized || _isConfiguringLock) {
      return state.value.torch;
    }

    _isConfiguringLock = true;

    try {
      final torchState = await _platform.toggleTorch();
      state.value = state.value.withTorch(torchState);
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }

    _isConfiguringLock = false;

    return state.value.torch;
  }

  Future<void> configure({
    List<BarcodeType>? types,
    Resolution? resolution,
    Framerate? framerate,
    DetectionMode? mode,
    CameraPosition? position,
    OnDetectionHandler? onScan,
  }) async {
    if (!state.value.isInitialized || _isConfiguringLock) return;

    _isConfiguringLock = true;

    final scannerConfig = state.value.scannerConfig!;

    try {
      final preview = await _platform.changeConfiguration(
        types: types,
        resolution: resolution,
        framerate: framerate,
        mode: mode,
        position: position,
      );

      final scanner = scannerConfig.copyWith(types: types, resolution: resolution, framerate: framerate, mode: mode, position: position);

      _onScan = _buildScanHandler(onScan);

      state.value = ScannerState(preview, scanner, state.value.torch, null);
    } on Error catch (error) {
      state.value = state.value.withError(error);
      eventNotifier.value = ScannerEvent.error;
    } catch (error) {
      rethrow;
    }

    _isConfiguringLock = false;
  }

  Future<List<Barcode>?> scanImage(ImageSource source) async {
    try {
      return _platform.scanImage(source);
    } catch (error) {
      return null;
    }
  }

  void _onDetectHandler(List<Barcode> codes) {
    eventNotifier.value = ScannerEvent.detected;
    _onScan?.call(codes);
  }
}

sealed class ScanResult {
  final List<Barcode> barcodes;
  final DateTime timestamp;

  ScanResult(this.barcodes) : timestamp = DateTime.now();

  ScanResult.none() : this([]);
}
