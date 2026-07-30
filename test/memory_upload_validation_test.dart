import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/core/constants/storage_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/features/memories/data/memory_upload_validator.dart';

void main() {
  group('MemoryUploadValidator', () {
    test('akzeptiert gültiges JPEG innerhalb des Limits', () {
      expect(
        () => MemoryUploadValidator.validateImageBytes(
          List.filled(1024, 0),
          'image/jpeg',
        ),
        returnsNormally,
      );
    });

    test('lehnt zu große Dateien ab', () {
      expect(
        () => MemoryUploadValidator.validateImageBytes(
          List.filled(StorageConstants.maxFamilyImageBytes + 1, 0),
          'image/jpeg',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            MemoryUploadValidator.imageTooLargeCode,
          ),
        ),
      );
    });

    test('lehnt ungültigen MIME-Typ ab', () {
      expect(
        () => MemoryUploadValidator.validateImageBytes(
          List.filled(100, 0),
          'application/pdf',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            MemoryUploadValidator.invalidImageTypeCode,
          ),
        ),
      );
    });

    test('akzeptiert alle erlaubten MIME-Typen', () {
      for (final mime in StorageConstants.allowedFamilyImageMimeTypes) {
        expect(
          () => MemoryUploadValidator.validateImageBytes(
            List.filled(100, 0),
            mime,
          ),
          returnsNormally,
          reason: mime,
        );
      }
    });
  });

  group('StorageConstants.familyImagePath', () {
    test('erzeugt Pfad im Format familyId/userId/fileId.ext', () {
      expect(
        StorageConstants.familyImagePath(
          familyId: 'fam-1',
          userId: 'user-2',
          fileId: 'abc-123',
          extension: 'jpg',
        ),
        'fam-1/user-2/abc-123.jpg',
      );
    });

    test('entfernt führenden Punkt bei Extension', () {
      expect(
        StorageConstants.familyImagePath(
          familyId: 'fam-1',
          userId: 'user-2',
          fileId: 'abc-123',
          extension: '.png',
        ),
        'fam-1/user-2/abc-123.png',
      );
    });
  });
}
