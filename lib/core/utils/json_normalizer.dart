/// On Flutter Web, `dart:convert`'s JSON decoder (via Dio's XHR response
/// path) produces `LinkedHashMap` with untyped `dynamic` keys/values at
/// *every* level of the decoded tree — not just the top-level response
/// body, but every nested object too. DTO decoders across the app do
/// `json['field'] as Map<String, dynamic>?` on nested fields (e.g.
/// `assignedRm`, `staff`, `kpis`), and that cast throws a TypeError instead
/// of working — visible to users as a generic "Something went wrong" crash
/// instead of real data or a proper error. Recursively rebuilding the tree
/// with a real string-keyed map at every level (not just the outermost
/// one) fixes this at the source, before any DTO code touches the data.
dynamic normalizeJson(dynamic value) {
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), normalizeJson(v)));
  }
  if (value is List) {
    return value.map(normalizeJson).toList();
  }
  return value;
}

/// [normalizeJson], asserting the result is a JSON object.
Map<String, dynamic> asStringKeyedMap(dynamic value) {
  final normalized = normalizeJson(value);
  if (normalized is Map<String, dynamic>) return normalized;
  throw FormatException('Expected a JSON object, got ${value.runtimeType}');
}
