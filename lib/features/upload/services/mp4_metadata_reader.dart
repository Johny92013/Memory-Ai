/// Leichtgewichtiger Reader für MP4/MOV-Container-Metadaten.
/// Liest nur Atom-Header und relevante Boxen – nicht die gesamte Mediendatei.
class Mp4MetadataReader {
  Mp4MetadataReader._();

  /// Parst [bytes] (kann ein Prefix sein). Fehler → leeres Ergebnis.
  static Mp4ContainerMetadata parse(List<int> bytes) {
    try {
      final view = ByteDataView(bytes);
      final result = Mp4ContainerMetadata();
      _walkAtoms(view, 0, bytes.length, result, depth: 0);
      return result;
    } catch (_) {
      return Mp4ContainerMetadata();
    }
  }

  static void _walkAtoms(
    ByteDataView view,
    int start,
    int end,
    Mp4ContainerMetadata out, {
    required int depth,
  }) {
    if (depth > 12) return;
    var offset = start;
    while (offset + 8 <= end) {
      final size32 = view.getUint32(offset);
      final type = view.getAscii(offset + 4, 4);
      var header = 8;
      var atomEnd = offset + size32;
      if (size32 == 1 && offset + 16 <= end) {
        final size64 = view.getUint64(offset + 8);
        header = 16;
        atomEnd = offset + size64;
      } else if (size32 == 0) {
        atomEnd = end;
      }
      if (atomEnd > end || atomEnd <= offset) break;

      final payloadStart = offset + header;
      final payloadEnd = atomEnd;

      if (type == 'moov' ||
          type == 'trak' ||
          type == 'mdia' ||
          type == 'minf' ||
          type == 'stbl' ||
          type == 'udta' ||
          type == 'meta') {
        var childStart = payloadStart;
        if (type == 'meta' && childStart + 4 <= payloadEnd) {
          childStart += 4; // version/flags
        }
        _walkAtoms(view, childStart, payloadEnd, out, depth: depth + 1);
      } else if (type == 'mvhd') {
        _parseMvhd(view, payloadStart, payloadEnd, out);
      } else if (type == 'tkhd') {
        _parseTkhd(view, payloadStart, payloadEnd, out);
      } else if (type == '©xyz' ||
          type == 'xyz ' ||
          type == String.fromCharCodes(const [0xA9, 0x78, 0x79, 0x7A])) {
        _parseXyz(view, payloadStart, payloadEnd, out);
      }

      offset = atomEnd;
    }
  }

  static void _parseMvhd(
    ByteDataView view,
    int start,
    int end,
    Mp4ContainerMetadata out,
  ) {
    if (start + 4 > end) return;
    final version = view.getUint8(start);
    if (version == 1) {
      if (start + 32 > end) return;
      final creation = view.getUint64(start + 4);
      final timescale = view.getUint32(start + 20);
      final duration = view.getUint64(start + 24);
      out.creationTime = _macEpochToDateTime(creation);
      if (timescale > 0) {
        out.durationSeconds = (duration / timescale).round();
      }
    } else {
      if (start + 20 > end) return;
      final creation = view.getUint32(start + 4);
      final timescale = view.getUint32(start + 12);
      final duration = view.getUint32(start + 16);
      out.creationTime = _macEpochToDateTime(creation);
      if (timescale > 0) {
        out.durationSeconds = (duration / timescale).round();
      }
    }
  }

  static void _parseTkhd(
    ByteDataView view,
    int start,
    int end,
    Mp4ContainerMetadata out,
  ) {
    if (out.width != null && out.height != null) return;
    if (start + 4 > end) return;
    final version = view.getUint8(start);
    final whOffset = version == 1 ? start + 96 : start + 84;
    if (whOffset + 8 > end) return;
    final w = view.getUint32(whOffset) / 65536.0;
    final h = view.getUint32(whOffset + 4) / 65536.0;
    if (w > 0 && h > 0) {
      out.width = w.round();
      out.height = h.round();
    }
  }

  /// QuickTime location atom: "+lat+lon/" oder "+lat+lon+alt/"
  static void _parseXyz(
    ByteDataView view,
    int start,
    int end,
    Mp4ContainerMetadata out,
  ) {
    if (start >= end) return;
    var textStart = start;
    if (end - start > 4) {
      textStart = start + 4;
    }
    final raw = view.getAscii(textStart, end - textStart).trim();
    final match = RegExp(
      r'([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)',
    ).firstMatch(raw);
    if (match == null) return;
    out.latitude = double.tryParse(match.group(1)!);
    out.longitude = double.tryParse(match.group(2)!);
  }

  static DateTime? _macEpochToDateTime(int seconds) {
    if (seconds <= 0) return null;
    // Mac epoch: 1904-01-01 UTC
    final unix = seconds - 2082844800;
    if (unix < 0 || unix > 4102444800) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      unix * 1000,
      isUtc: true,
    ).toLocal();
  }
}

class Mp4ContainerMetadata {
  DateTime? creationTime;
  int? durationSeconds;
  int? width;
  int? height;
  double? latitude;
  double? longitude;
}

class ByteDataView {
  ByteDataView(this._bytes);

  final List<int> _bytes;

  int getUint8(int offset) => _bytes[offset] & 0xff;

  int getUint32(int offset) {
    return (getUint8(offset) << 24) |
        (getUint8(offset + 1) << 16) |
        (getUint8(offset + 2) << 8) |
        getUint8(offset + 3);
  }

  int getUint64(int offset) {
    final hi = getUint32(offset);
    final lo = getUint32(offset + 4);
    return (hi << 32) + lo;
  }

  String getAscii(int offset, int length) {
    final end = (offset + length).clamp(0, _bytes.length);
    final start = offset.clamp(0, _bytes.length);
    if (start >= end) return '';
    return String.fromCharCodes(_bytes.sublist(start, end));
  }
}
