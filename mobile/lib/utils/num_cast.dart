/// Safe type conversion helpers for API responses where numeric fields
/// may arrive as strings (e.g. `"123.45"` instead of `123.45`).

/// Safely converts [v] to `num?` — handles num, String, and null.
num? toNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Safely converts [v] to `double?` — handles num, String, and null.
double? toDouble(dynamic v) {
  final n = toNum(v);
  return n?.toDouble();
}

/// Safely converts [v] to `int?` — handles num, String, and null.
int? toInt(dynamic v) {
  final n = toNum(v);
  return n?.toInt();
}

/// Safely converts [v] to `double` with a default — handles num, String, and null.
double toDoubleOr(dynamic v, [double defaultValue = 0]) =>
    toDouble(v) ?? defaultValue;

/// Safely converts [v] to `int` with a default — handles num, String, and null.
int toIntOr(dynamic v, [int defaultValue = 0]) =>
    toInt(v) ?? defaultValue;
