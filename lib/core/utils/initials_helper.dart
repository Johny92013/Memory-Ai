/// Erzeugt Initialen aus Vor- und Nachname.
class InitialsHelper {
  InitialsHelper._();

  static String fromNames(
    String? firstName,
    String? lastName, {
    String fallback = '?',
  }) {
    final firstInitial = _firstLetter(firstName);
    final lastInitial = _firstLetter(lastName);

    if (firstInitial.isEmpty && lastInitial.isEmpty) {
      return fallback;
    }

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  static String fromFullName(String? fullName, {String fallback = '?'}) {
    if (fullName == null || fullName.trim().isEmpty) {
      return fallback;
    }

    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final initial = _firstLetter(parts.first);
      return initial.isEmpty ? fallback : initial.toUpperCase();
    }

    return fromNames(parts.first, parts.last, fallback: fallback);
  }

  static String _firstLetter(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed[0];
  }
}
