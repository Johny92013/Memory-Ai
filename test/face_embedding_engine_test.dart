import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memory_ai/features/people/data/face_embedding_engine.dart';

void main() {
  test(
    'LocalProjectionEmbeddingEngine erzeugt festen Dimensionsvektor',
    () async {
      final engine = LocalProjectionEmbeddingEngine(dimensions: 32);
      final image = img.Image(width: 80, height: 80);
      img.fill(image, color: img.ColorRgb8(120, 90, 60));
      final bytes = Uint8List.fromList(img.encodeJpg(image));
      final embedding = await engine.embedFaceCrop(bytes);
      expect(embedding.length, 32);
      final norm = FaceEmbeddingMath.cosineSimilarity(embedding, embedding);
      expect(norm, closeTo(1.0, 1e-6));
    },
  );

  test('ähnliche Crops haben höhere Ähnlichkeit als Zufall', () async {
    final engine = LocalProjectionEmbeddingEngine(dimensions: 64);

    Future<List<double>> build(void Function(img.Image) paint) async {
      final image = img.Image(width: 64, height: 64);
      img.fill(image, color: img.ColorRgb8(40, 40, 40));
      paint(image);
      return engine.embedFaceCrop(Uint8List.fromList(img.encodeJpg(image)));
    }

    void faceLike(img.Image image) {
      img.fillCircle(
        image,
        x: 32,
        y: 28,
        radius: 18,
        color: img.ColorRgb8(210, 170, 140),
      );
      img.fillCircle(
        image,
        x: 26,
        y: 24,
        radius: 3,
        color: img.ColorRgb8(20, 20, 20),
      );
      img.fillCircle(
        image,
        x: 38,
        y: 24,
        radius: 3,
        color: img.ColorRgb8(20, 20, 20),
      );
    }

    void faceLikeSlightlyDifferent(img.Image image) {
      img.fillCircle(
        image,
        x: 33,
        y: 29,
        radius: 17,
        color: img.ColorRgb8(200, 160, 130),
      );
      img.fillCircle(
        image,
        x: 27,
        y: 25,
        radius: 3,
        color: img.ColorRgb8(30, 30, 30),
      );
      img.fillCircle(
        image,
        x: 39,
        y: 25,
        radius: 3,
        color: img.ColorRgb8(30, 30, 30),
      );
    }

    void stripes(img.Image image) {
      for (var y = 0; y < 64; y += 4) {
        img.drawLine(
          image,
          x1: 0,
          y1: y,
          x2: 63,
          y2: y,
          color: img.ColorRgb8(10, 220, 250),
        );
      }
    }

    final ea = await build(faceLike);
    final eb = await build(faceLikeSlightlyDifferent);
    final ec = await build(stripes);

    final similar = FaceEmbeddingMath.cosineSimilarity(ea, eb);
    final different = FaceEmbeddingMath.cosineSimilarity(ea, ec);
    expect(similar, greaterThan(different));
  });
}
