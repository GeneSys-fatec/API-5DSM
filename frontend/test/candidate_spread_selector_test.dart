import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/models/api_models.dart';
import 'package:frontend/features/scenario_config/domain/candidate_spread_selector.dart';
import 'package:frontend/features/scenario_config/domain/models/area_delimitation_model.dart';

const _centerLat = -10.909;
const _centerLng = -37.068;

List<CandidateAsset> _grid(int side, double stepMeters) {
  const metersPerDegreeLat = 111320.0;
  final metersPerDegreeLng = metersPerDegreeLat * math.cos(_centerLat * math.pi / 180.0);
  final list = <CandidateAsset>[];
  for (var r = 0; r < side; r++) {
    for (var c = 0; c < side; c++) {
      final dy = (r - (side - 1) / 2) * stepMeters;
      final dx = (c - (side - 1) / 2) * stepMeters;
      list.add(CandidateAsset(
        id: 'p-$r-$c',
        assetKey: 'p-$r-$c',
        type: CandidateAssetType.poste,
        latitude: _centerLat + dy / metersPerDegreeLat,
        longitude: _centerLng + dx / metersPerDegreeLng,
      ));
    }
  }
  return list;
}

double _meters(CandidateAsset a, CandidateAsset b) {
  const metersPerDegreeLat = 111320.0;
  final metersPerDegreeLng = metersPerDegreeLat * math.cos(_centerLat * math.pi / 180.0);
  final dy = (a.latitude - b.latitude) * metersPerDegreeLat;
  final dx = (a.longitude - b.longitude) * metersPerDegreeLng;
  return math.sqrt(dx * dx + dy * dy);
}

double _minPairwise(List<CandidateAsset> list) {
  var best = double.infinity;
  for (var i = 0; i < list.length; i++) {
    for (var j = i + 1; j < list.length; j++) {
      best = math.min(best, _meters(list[i], list[j]));
    }
  }
  return best;
}

void main() {
  group('selectSpreadCandidates', () {
    test('devolve todos os candidatos quando ha menos que o maximo', () {
      final candidates = _grid(3, 100);
      final result = selectSpreadCandidates(
        candidates,
        max: 30,
        centerLatitude: _centerLat,
        centerLongitude: _centerLng,
      );
      expect(result.length, 9);
    });

    test('limita ao maximo, sem repetir candidatos', () {
      final candidates = _grid(20, 100);
      final result = selectSpreadCandidates(
        candidates,
        max: 15,
        centerLatitude: _centerLat,
        centerLongitude: _centerLng,
      );
      expect(result.length, 15);
      expect(result.map((c) => c.id).toSet().length, 15);
    });

    test('comeca pelo candidato mais proximo do centro', () {
      final candidates = _grid(21, 100);
      final result = selectSpreadCandidates(
        candidates,
        max: 5,
        centerLatitude: _centerLat,
        centerLongitude: _centerLng,
      );
      expect(result.first.id, 'p-10-10');
    });

    test('espalha os candidatos: distancia minima entre eles e muito maior que a dos mais proximos do centro', () {
      final candidates = _grid(40, 100);
      const max = 15;

      final spread = selectSpreadCandidates(
        candidates,
        max: max,
        centerLatitude: _centerLat,
        centerLongitude: _centerLng,
      );

      final nearest = List.of(candidates)
        ..sort((a, b) {
          final da = math.pow(a.latitude - _centerLat, 2) + math.pow(a.longitude - _centerLng, 2);
          final db = math.pow(b.latitude - _centerLat, 2) + math.pow(b.longitude - _centerLng, 2);
          return da.compareTo(db);
        });
      final clustered = nearest.take(max).toList();

      final spreadMin = _minPairwise(spread);
      final clusteredMin = _minPairwise(clustered);

      expect(clusteredMin, lessThan(150));
      expect(spreadMin, greaterThan(800));
    });
  });

  group('SimulationRequest', () {
    const rf = RfParameterRequest(
      frequencyMhz: 915,
      transmitPowerDbm: 21,
      receiverSensitivityDbm: -120,
      antennaHeightM: 6,
      deviceHeightM: 5,
      antennaGainDbi: 0,
      systemLossDb: 14,
    );

    test('envia a area de busca da Etapa 1 quando informada', () {
      const request = SimulationRequest(
        name: 'x',
        regionName: 'y',
        coverageTargetPct: 90,
        maxGateways: 5,
        gatewayCandidates: [],
        propagationModel: 'OKUMURA_HATA_SUBURBAN',
        searchCenterLatitude: -10.909,
        searchCenterLongitude: -37.068,
        searchRadiusMeters: 3500,
        rfParameter: rf,
      );
      final map = request.toMap();
      expect(map['searchCenterLatitude'], -10.909);
      expect(map['searchCenterLongitude'], -37.068);
      expect(map['searchRadiusMeters'], 3500);
    });

    test('omite a area de busca quando nao informada', () {
      const request = SimulationRequest(
        name: 'x',
        regionName: 'y',
        coverageTargetPct: 90,
        maxGateways: 5,
        gatewayCandidates: [],
        propagationModel: 'OKUMURA_HATA_SUBURBAN',
        rfParameter: rf,
      );
      final map = request.toMap();
      expect(map.containsKey('searchCenterLatitude'), false);
      expect(map.containsKey('searchRadiusMeters'), false);
    });
  });
}
