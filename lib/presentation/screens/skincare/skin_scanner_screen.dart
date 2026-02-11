import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';

class SkinScannerScreen extends ConsumerStatefulWidget {
  const SkinScannerScreen({super.key});

  @override
  ConsumerState<SkinScannerScreen> createState() => _SkinScannerScreenState();
}

class _SkinScannerScreenState extends ConsumerState<SkinScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFaceDetected = false;
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;
  DateTime? _lastProcessedTime;
  String? _diagnosticMessage;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    // Use front camera if available
    final frontCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Better resolution for accurate detection
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21 // Hint for NV21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      _controller!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _frameCount++;
    if (_faceDetector == null || _isProcessingFrame || _isCapturing) return;

    // Frame Throttling: Only process frames every 250ms (approx 4 FPS)
    final now = DateTime.now();
    if (_lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inMilliseconds < 250) {
      return;
    }

    _isProcessingFrame = true;
    _lastProcessedTime = now;

    try {
      final inputImage = _createInputImageFromCameraImage(image);
      if (inputImage == null) {
        if (mounted && _frameCount % 20 == 0) {
          setState(() => _diagnosticMessage = 'Format conversion failed');
        }
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _isFaceDetected = faces.isNotEmpty;
          _diagnosticMessage = faces.isNotEmpty
              ? 'Face detected! ✨'
              : 'Searching for face... (${image.width}x${image.height})';
        });
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
      if (mounted) setState(() => _diagnosticMessage = 'Detection error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _createInputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _controller!.description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    // On Android, we manually convert to NV21 to avoid "Bad position" errors
    // and correctly handle plane strides (padding).
    if (Platform.isAndroid) {
      if (image.planes.length < 3) return null;

      final nv21Bytes = _convertYUV420ToNV21(image);

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // Clean buffer has no padding
        ),
      );
    }

    // iOS and fallback
    final BytesBuilder allBytes = BytesBuilder();
    for (final plane in image.planes) {
      allBytes.add(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: allBytes.takeBytes(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing ||
        !_isFaceDetected) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        // Navigate to report screen with the image path
        context.push('/skin-analysis-report', extra: image.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // AR Overlay (Head Position Guide)
          _buildAROverlay(),

          // UI Controls
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HeadGuidePainter(isFaceDetected: _isFaceDetected),
        child: Container(),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ResponsiveConfig.heightBox(24),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => context.pop(),
                ),
                Text(
                  'Skin Scanner',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 48), // Spacer
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                Text(
                  _diagnosticMessage ?? 'Align your face within the frame',
                  textAlign: TextAlign.center,
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: _isFaceDetected ? Colors.greenAccent : Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
                ResponsiveConfig.heightBox(24),
                GestureDetector(
                  onTap: _isFaceDetected ? _takePicture : null,
                  child: Opacity(
                    opacity: _isFaceDetected ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _isFaceDetected
                                ? AppTheme.primaryPink
                                : Colors.white,
                            width: 4),
                      ),
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _isFaceDetected
                                    ? AppTheme.primaryPink
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadGuidePainter extends CustomPainter {
  final bool isFaceDetected;

  _HeadGuidePainter({required this.isFaceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFaceDetected
          ? Colors.green.withOpacity(0.8)
          : Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2 - 50);
    final ovalWidth = size.width * 0.65;
    final ovalHeight = size.height * 0.45;

    // Draw face oval
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight),
      paint,
    );

    // Draw eye guides
    final eyeY = center.dy - ovalHeight * 0.1;
    final eyeSpacing = ovalWidth * 0.3;
    canvas.drawLine(
      Offset(center.dx - eyeSpacing, eyeY),
      Offset(center.dx - eyeSpacing + 20, eyeY),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + eyeSpacing, eyeY),
      Offset(center.dx + eyeSpacing - 20, eyeY),
      paint,
    );

    // Draw mouth guide
    final mouthY = center.dy + ovalHeight * 0.25;
    canvas.drawLine(
      Offset(center.dx - 30, mouthY),
      Offset(center.dx + 30, mouthY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeadGuidePainter oldDelegate) {
    return oldDelegate.isFaceDetected != isFaceDetected;
  }
}

/// Manually converts a YUV420 CameraImage to a packed NV21 buffer.
/// This removes row padding (strides) and interleaves the Chroma planes.
Uint8List _convertYUV420ToNV21(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yBuffer = yPlane.bytes;
  final uBuffer = uPlane.bytes;
  final vBuffer = vPlane.bytes;

  final numPixels = width * height;
  final nv21 = Uint8List(numPixels * 3 ~/ 2);

  // 1. Copy Y Plane (Luma) - Remove row padding if any
  int idY = 0;
  for (int y = 0; y < height; y++) {
    final int rowOffset = y * yPlane.bytesPerRow!;
    nv21.setRange(
        idY, idY + width, yBuffer.sublist(rowOffset, rowOffset + width));
    idY += width;
  }

  // 2. Interleave Chroma (U/V) into NV21 format (V, U, V, U...)
  // UV planes are subsampled 2x2.
  final int vRowStride = vPlane.bytesPerRow!;
  final int vPixelStride = vPlane.bytesPerPixel!;
  final int uRowStride = uPlane.bytesPerRow!;
  final int uPixelStride = uPlane.bytesPerPixel!;

  int idUV = numPixels;
  for (int y = 0; y < height ~/ 2; y++) {
    for (int x = 0; x < width ~/ 2; x++) {
      // In NV21, V comes before U
      nv21[idUV++] = vBuffer[y * vRowStride + x * vPixelStride];
      nv21[idUV++] = uBuffer[y * uRowStride + x * uPixelStride];
    }
  }

  return nv21;
}
