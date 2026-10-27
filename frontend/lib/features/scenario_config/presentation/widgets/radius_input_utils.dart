double? parseRadiusInput(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

double clampConfirmedRadius(
  double raw, {
  required bool isUnitKm,
  required double maxRadiusKm,
}) {
  final minBound = isUnitKm ? 0.5 : 500.0;
  final maxBound = isUnitKm ? maxRadiusKm : maxRadiusKm * 1000.0;
  final clamped = raw.clamp(minBound, maxBound).toDouble();
  return isUnitKm ? clamped : clamped / 1000.0;
}
