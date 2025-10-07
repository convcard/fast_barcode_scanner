import 'package:fast_barcode_scanner_platform_interface/fast_barcode_scanner_platform_interface.dart';

/// The configuration of the camera and scanner.
///
/// Holds detailed information about the running camera session.
class ScannerConfiguration {
  const ScannerConfiguration(this.types, this.resolution, this.framerate, this.mode, this.position);

  /// The types the scanner should look out for.
  ///
  /// If a barcode type is not in this list, it will not be detected.
  final List<BarcodeType> types;

  /// The target resolution of the camera.
  final Resolution resolution;

  /// The target framerate of the camera.
  final Framerate framerate;

  /// Determines how the camera reacts to detected barcodes.
  final DetectionMode mode;

  /// The physical position of the camera being used.
  final CameraPosition position;

  ScannerConfiguration copyWith({
    List<BarcodeType>? types,
    Resolution? resolution,
    Framerate? framerate,
    DetectionMode? mode,
    CameraPosition? position,
  }) {
    return ScannerConfiguration(
      types ?? this.types,
      resolution ?? this.resolution,
      framerate ?? this.framerate,
      mode ?? this.mode,
      position ?? this.position,
    );
  }
}
