library scenario_results_models;

class GatewayPoint {
  final String id;
  final String posteId;
  final double lat;
  final double lng;
  final double antennaHeight;
  final double txPowerDbm;
  final int linkedAssets;
  final double avgFadeMarginDb;
  final double coverageRadiusMeters;

  const GatewayPoint({
    required this.id,
    required this.posteId,
    required this.lat,
    required this.lng,
    required this.antennaHeight,
    required this.txPowerDbm,
    required this.linkedAssets,
    required this.avgFadeMarginDb,
    required this.coverageRadiusMeters,
  });
}

class ScenarioParameters {
  final String feederName;
  final int gatewayCount;
  final double txPowerDbm;
  final String propagationModel;

  const ScenarioParameters({
    required this.feederName,
    required this.gatewayCount,
    required this.txPowerDbm,
    required this.propagationModel,
  });
}

class ScenarioResults {
  final double coveragePercent;
  final int connectedAssets;
  final int totalAssets;
  final double implementationCost;
  final double avgRssiDbm;
  final List<GatewayPoint> gateways;

  const ScenarioResults({
    required this.coveragePercent,
    required this.connectedAssets,
    required this.totalAssets,
    required this.implementationCost,
    required this.avgRssiDbm,
    required this.gateways,
  });

  int get assetsInShadow => totalAssets - connectedAssets;
}

class SimulationScenario {
  final String id;
  final String code;
  final String region;
  final double centerLat;
  final double centerLng;
  final DateTime executedAt;
  final ScenarioParameters parameters;
  final ScenarioResults results;

  const SimulationScenario({
    required this.id,
    required this.code,
    required this.region,
    required this.centerLat,
    required this.centerLng,
    required this.executedAt,
    required this.parameters,
    required this.results,
  });
}

final List<SimulationScenario> kMockScenarios = [
  SimulationScenario(
    id: '1',
    code: 'SIM-2024-098F',
    region: 'Regional Leste',
    centerLat: -23.1896,
    centerLng: -45.8841,
    executedAt: DateTime(2024, 11, 12, 14, 32),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Central - Regional Leste',
      gatewayCount: 14,
      txPowerDbm: 27,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 96.8,
      connectedAssets: 1248,
      totalAssets: 1289,
      implementationCost: 168000,
      avgRssiDbm: -88,
      gateways: const [
        GatewayPoint(
          id: 'GW-04',
          posteId: 'BDGD #90412',
          lat: -23.1896,
          lng: -45.8841,
          antennaHeight: 14.5,
          txPowerDbm: 27,
          linkedAssets: 142,
          avgFadeMarginDb: 18.4,
          coverageRadiusMeters: 4200,
        ),
        GatewayPoint(
          id: 'GW-02',
          posteId: 'BDGD #90188',
          lat: -23.1755,
          lng: -45.9020,
          antennaHeight: 12.0,
          txPowerDbm: 25,
          linkedAssets: 98,
          avgFadeMarginDb: 15.1,
          coverageRadiusMeters: 3600,
        ),
        GatewayPoint(
          id: 'GW-07',
          posteId: 'BDGD #90540',
          lat: -23.2050,
          lng: -45.8600,
          antennaHeight: 16.0,
          txPowerDbm: 27,
          linkedAssets: 121,
          avgFadeMarginDb: 16.9,
          coverageRadiusMeters: 3900,
        ),
      ],
    ),
  ),
  SimulationScenario(
    id: '2',
    code: 'SIM-2024-071A',
    region: 'Regional Norte',
    centerLat: -3.1019,
    centerLng: -60.0250,
    executedAt: DateTime(2024, 9, 3, 9, 15),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Rio Negro - Regional Norte',
      gatewayCount: 9,
      txPowerDbm: 30,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 88.2,
      connectedAssets: 604,
      totalAssets: 685,
      implementationCost: 121500,
      avgRssiDbm: -93,
      gateways: const [
        GatewayPoint(
          id: 'GW-01',
          posteId: 'BDGD #41002',
          lat: -3.1019,
          lng: -60.0250,
          antennaHeight: 18.0,
          txPowerDbm: 30,
          linkedAssets: 210,
          avgFadeMarginDb: 12.3,
          coverageRadiusMeters: 5200,
        ),
      ],
    ),
  ),
  SimulationScenario(
    id: '3',
    code: 'SIM-2024-055C',
    region: 'Regional Sul',
    centerLat: -30.0346,
    centerLng: -51.2177,
    executedAt: DateTime(2024, 7, 21, 16, 48),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Guaíba - Regional Sul',
      gatewayCount: 11,
      txPowerDbm: 26,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 99.1,
      connectedAssets: 972,
      totalAssets: 981,
      implementationCost: 143200,
      avgRssiDbm: -81,
      gateways: const [
        GatewayPoint(
          id: 'GW-03',
          posteId: 'BDGD #52110',
          lat: -30.0346,
          lng: -51.2177,
          antennaHeight: 13.0,
          txPowerDbm: 26,
          linkedAssets: 188,
          avgFadeMarginDb: 20.2,
          coverageRadiusMeters: 3800,
        ),
      ],
    ),
  ),
  SimulationScenario(
    id: '4',
    code: 'SIM-2024-102D',
    region: 'Regional Nordeste',
    centerLat: -8.0476,
    centerLng: -34.8770,
    executedAt: DateTime(2024, 12, 2, 10, 5),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Boa Viagem - Regional Nordeste',
      gatewayCount: 16,
      txPowerDbm: 28,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 93.4,
      connectedAssets: 1510,
      totalAssets: 1617,
      implementationCost: 189700,
      avgRssiDbm: -85,
      gateways: const [
        GatewayPoint(
          id: 'GW-09',
          posteId: 'BDGD #61220',
          lat: -8.0476,
          lng: -34.8770,
          antennaHeight: 15.5,
          txPowerDbm: 28,
          linkedAssets: 176,
          avgFadeMarginDb: 17.0,
          coverageRadiusMeters: 4000,
        ),
      ],
    ),
  ),
  SimulationScenario(
    id: '5',
    code: 'SIM-2024-039E',
    region: 'Regional Centro-Oeste',
    centerLat: -16.6869,
    centerLng: -49.2648,
    executedAt: DateTime(2024, 5, 30, 8, 40),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Cerrado - Regional Centro-Oeste',
      gatewayCount: 7,
      txPowerDbm: 29,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 91.0,
      connectedAssets: 430,
      totalAssets: 472,
      implementationCost: 98400,
      avgRssiDbm: -90,
      gateways: const [
        GatewayPoint(
          id: 'GW-05',
          posteId: 'BDGD #30044',
          lat: -16.6869,
          lng: -49.2648,
          antennaHeight: 17.0,
          txPowerDbm: 29,
          linkedAssets: 132,
          avgFadeMarginDb: 14.6,
          coverageRadiusMeters: 4600,
        ),
      ],
    ),
  ),
  SimulationScenario(
    id: '6',
    code: 'SIM-2024-018B',
    region: 'Regional Leste',
    centerLat: -23.3105,
    centerLng: -45.9645,
    executedAt: DateTime(2024, 3, 14, 11, 20),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Vista Verde - Regional Leste',
      gatewayCount: 8,
      txPowerDbm: 24,
      propagationModel: 'ITU-R P.1546 + SRTM',
    ),
    results: ScenarioResults(
      coveragePercent: 97.6,
      connectedAssets: 812,
      totalAssets: 832,
      implementationCost: 87300,
      avgRssiDbm: -84,
      gateways: const [
        GatewayPoint(
          id: 'GW-06',
          posteId: 'BDGD #90701',
          lat: -23.3105,
          lng: -45.9645,
          antennaHeight: 12.5,
          txPowerDbm: 24,
          linkedAssets: 154,
          avgFadeMarginDb: 19.5,
          coverageRadiusMeters: 3300,
        ),
      ],
    ),
  ),
];