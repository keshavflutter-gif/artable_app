class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Checks if [id] is a valid backend database ID (CUID / ObjectId / UUID)
  /// and NOT a local mock/dummy string (e.g. 'c1', 'dance', 'cat_1', 'singing').
  static bool isRealDatabaseId(String? id) {
    if (id == null) return false;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('cat_') ||
        lower == 'c1' ||
        lower == 'c2' ||
        lower == 'c3' ||
        lower == 'c4' ||
        lower == 'c5' ||
        lower.startsWith('c1') ||
        lower.startsWith('c2') ||
        lower.startsWith('c3') ||
        lower == 'dance' ||
        lower == 'singing' ||
        lower == 'comedy' ||
        lower == 'fitness' ||
        lower == 'magic' ||
        lower == 'art' ||
        lower == 'acting' ||
        lower == 'sports' ||
        lower == 'custom' ||
        lower == 'mock' ||
        lower.contains('dummy')) {
      return false;
    }

    // Real CUIDs / ObjectIds are at least 15 characters long (e.g. "cmui0klzg000ejx8i91h0my8p")
    return trimmed.length >= 15;
  }
}
