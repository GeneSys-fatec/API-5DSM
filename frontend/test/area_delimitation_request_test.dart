import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/area_delimitation_service.dart';
import 'package:frontend/features/scenario_config/domain/models/area_delimitation_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  test('request de busca envia somente os dados da area selecionada', () async {
    final requests = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      final body = json.decode(request.body) as Map<String, dynamic>;
      requests.add(body);
      final isPolygon = body.containsKey('polygonPoints');
      return http.Response(
        json.encode({
          'candidates': [
            {
              'id': isPolygon ? 'polygon-candidate' : 'radius-candidate',
              'type': 'POSTE',
              'latitude': -10.9,
              'longitude': -37.0,
            },
          ],
          'validationStatus': 'OK',
        }),
        200,
      );
    });

    await http.runWithClient(() async {
      final service = AreaDelimitationService();
      const circle = AreaDelimitationConfig(
        bdgdImportId: '00000000-0000-0000-0000-000000000001',
        centerLatitude: -10.9,
        centerLongitude: -37.0,
        radiusKm: 2.0,
      );
      const polygon = AreaDelimitationConfig(
        bdgdImportId: '00000000-0000-0000-0000-000000000001',
        centerLatitude: -10.9,
        centerLongitude: -37.0,
        radiusKm: 2.0,
        useDrawnPolygon: true,
        drawnPolygonPoints: [
          [-10.90, -37.00],
          [-10.90, -37.01],
          [-10.91, -37.00],
        ],
      );

      final circleResult = await service.evaluateArea(circle);
      final polygonResult = await service.evaluateArea(polygon);

      expect(requests, hasLength(2));
      expect(requests[0]['radius'], circle.radiusMeters);
      expect(requests[0].containsKey('polygonPoints'), isFalse);
      expect(requests[1].containsKey('radius'), isFalse);
      expect(requests[1]['polygonPoints'], hasLength(3));
      expect(circleResult.candidates.single.id, 'radius-candidate');
      expect(polygonResult.candidates.single.id, 'polygon-candidate');
    }, () => client);
  });
}
