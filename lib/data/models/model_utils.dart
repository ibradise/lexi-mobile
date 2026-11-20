String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing required string field: $key.');
  }
  return value;
}

String? optionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int optionalInt(Object? value, {int fallback = 0}) {
  return value is num ? value.toInt() : fallback;
}

double optionalDouble(Object? value, {double fallback = 0}) {
  return value is num ? value.toDouble() : fallback;
}

DateTime? optionalDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

List<String> stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
