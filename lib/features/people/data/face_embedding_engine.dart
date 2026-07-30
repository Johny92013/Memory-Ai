import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// On-Device-Embedding aus Gesichtscrop (kostenlos, lokal, kein externes API).
///
/// Erzeugt einen 128-D-Vektor über feste Zufallsprojektion (reproduzierbar).
/// Kann später durch MobileFaceNet/TFLite ersetzt werden, ohne Service-API zu ändern.
abstract class FaceEmbeddingEngine {
  Future<List<double>> embedFaceCrop(Uint8List jpegOrPngBytes);
  Future<void> dispose() async {}
}

class LocalProjectionEmbeddingEngine implements FaceEmbeddingEngine {
  LocalProjectionEmbeddingEngine({this.dimensions = 128, int seed = 42})
    : _projection = _buildProjection(dimensions, seed);

  final int dimensions;
  final List<List<double>> _projection;

  static const _inputSize = 64;

  static List<List<double>> _buildProjection(int dims, int seed) {
    final rnd = math.Random(seed);
    return List.generate(
      dims,
      (_) => List.generate(_inputSize * _inputSize, (_) => rnd.nextGaussian()),
    );
  }

  @override
  Future<List<double>> embedFaceCrop(Uint8List jpegOrPngBytes) async {
    final decoded = img.decodeImage(jpegOrPngBytes);
    if (decoded == null) return List.filled(dimensions, 0);
    final gray = img.grayscale(
      img.copyResize(decoded, width: _inputSize, height: _inputSize),
    );
    final pixels = <double>[];
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final p = gray.getPixel(x, y);
        pixels.add((p.r.toDouble() / 255.0) * 2 - 1);
      }
    }
    final out = List<double>.filled(dimensions, 0);
    for (var i = 0; i < dimensions; i++) {
      var sum = 0.0;
      final row = _projection[i];
      for (var j = 0; j < pixels.length; j++) {
        sum += row[j] * pixels[j];
      }
      out[i] = sum;
    }
    return FaceEmbeddingMath.l2Normalize(out);
  }

  @override
  Future<void> dispose() async {}
}

abstract final class FaceEmbeddingMath {
  static List<double> l2Normalize(List<double> v) {
    var sum = 0.0;
    for (final x in v) {
      sum += x * x;
    }
    final norm = math.sqrt(sum);
    if (norm < 1e-9) return List.filled(v.length, 0);
    return v.map((x) => x / norm).toList();
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot; // bereits L2-normalisiert
  }

  /// Schwelle für Vorschlag (kein Auto-Confirm).
  static const suggestionThreshold = 0.78;
}

extension on math.Random {
  double nextGaussian() {
    // Box-Muller
    final u1 = nextDouble().clamp(1e-12, 1.0);
    final u2 = nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
