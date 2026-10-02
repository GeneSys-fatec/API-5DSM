import 'dart:math' as math;

import 'models/area_delimitation_model.dart';

/// Escolhe até [max] candidatos espalhados pela área de busca (farthest-point
/// sampling): parte do candidato mais próximo do centro e, a cada passo, pega o
/// que está mais longe de todos os já escolhidos.
///
/// Selecionar os candidatos mais próximos do centro os deixa colados uns nos
/// outros: os círculos de cobertura se sobrepõem quase por completo, o segundo
/// gateway não acrescenta ativos e o algoritmo guloso do backend para cedo.
List<CandidateAsset> selectSpreadCandidates(
  List<CandidateAsset> candidates, {
  required int max,
  required double centerLatitude,
  required double centerLongitude,
}) {
  if (max <= 0) return const [];
  if (candidates.length <= max) return List.of(candidates);

  const metersPerDegreeLatitude = 111320.0;
  final metersPerDegreeLongitude =
      metersPerDegreeLatitude * math.cos(centerLatitude * math.pi / 180.0);

  final xs = List<double>.generate(
    candidates.length,
    (i) => (candidates[i].longitude - centerLongitude) * metersPerDegreeLongitude,
  );
  final ys = List<double>.generate(
    candidates.length,
    (i) => (candidates[i].latitude - centerLatitude) * metersPerDegreeLatitude,
  );

  var seed = 0;
  var seedDistance = double.infinity;
  for (var i = 0; i < candidates.length; i++) {
    final d = xs[i] * xs[i] + ys[i] * ys[i];
    if (d < seedDistance) {
      seedDistance = d;
      seed = i;
    }
  }

  final selected = <int>[seed];
  final minDistanceToSelected = List<double>.generate(candidates.length, (i) {
    final dx = xs[i] - xs[seed];
    final dy = ys[i] - ys[seed];
    return dx * dx + dy * dy;
  });

  while (selected.length < max) {
    var next = -1;
    var nextDistance = -1.0;
    for (var i = 0; i < candidates.length; i++) {
      if (minDistanceToSelected[i] > nextDistance) {
        nextDistance = minDistanceToSelected[i];
        next = i;
      }
    }
    if (next < 0 || nextDistance <= 0) break;

    selected.add(next);
    for (var i = 0; i < candidates.length; i++) {
      final dx = xs[i] - xs[next];
      final dy = ys[i] - ys[next];
      final d = dx * dx + dy * dy;
      if (d < minDistanceToSelected[i]) minDistanceToSelected[i] = d;
    }
  }

  return selected.map((i) => candidates[i]).toList();
}
