import 'package:flutter/material.dart';
import '../../data/services/scenario_storage_service.dart';
import '../../data/services/simulation_service.dart';
import '../../domain/models/scenario_config_model.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../controllers/area_delimitation_controller.dart'
    show AreaDelimitationController;
import '../../data/models/api_models.dart';
import 'package:frontend/features/scenario_history/models/scenario_history_models.dart';

class ScenarioConfigController extends ChangeNotifier {
  final ScenarioStorageService _storageService;
  final SimulationService _simulationService;

  final TextEditingController txPowerController = TextEditingController();
  final TextEditingController rxSensitivityController = TextEditingController();
  final TextEditingController gatewayHeightController = TextEditingController();
  final TextEditingController deviceHeightController = TextEditingController();
  final TextEditingController maxGatewaysController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();

  String _selectedFrequencyPreset = '915 MHz';
  String _selectedPropagationModel = 'Okumura-Hata Suburbano';
  double _minCoveragePercent = 95.0;
  double _fadeMarginDb = 14.0;
  bool _religadoresChecked = true;
  bool _transformadoresChecked = true;
  bool _medidoresChecked = true;

  bool _isLoading = false;
  bool _isCalculating = false;
  String? _successMessage;
  String? _errorMessage;
  SimulationResponse? _lastSimulationResult;
  final Function(SimulationScenario)? _onSimulationComplete;

  ScenarioConfigController({
    ScenarioStorageService? storageService,
    SimulationService? simulationService,
    this._onSimulationComplete,
  }) : _storageService = storageService ?? ScenarioStorageService(),
       _simulationService = simulationService ?? SimulationService() {
    _applyModelToState(const ScenarioConfigModel());
    _initListeners();
  }

  void _initListeners() {
    txPowerController.addListener(notifyListeners);
    rxSensitivityController.addListener(notifyListeners);
    gatewayHeightController.addListener(notifyListeners);
    deviceHeightController.addListener(notifyListeners);
    maxGatewaysController.addListener(notifyListeners);
    frequencyController.addListener(notifyListeners);
  }

  String get selectedFrequencyPreset => _selectedFrequencyPreset;
  String get selectedPropagationModel => _selectedPropagationModel;
  double get minCoveragePercent => _minCoveragePercent;
  double get fadeMarginDb => _fadeMarginDb;
  bool get religadoresChecked => _religadoresChecked;
  bool get transformadoresChecked => _transformadoresChecked;
  bool get medidoresChecked => _medidoresChecked;
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  String? get successMessage => _successMessage;
  String? get errorMessage => _errorMessage;
  SimulationResponse? get lastSimulationResult => _lastSimulationResult;

  String? get coverageError {
    if (_minCoveragePercent < 1.0 || _minCoveragePercent > 100.0) {
      return 'A cobertura deve estar entre 1% e 100%';
    }
    return null;
  }

  String? get gatewaysError {
    final text = maxGatewaysController.text.trim();
    if (text.isEmpty) return 'Informe o número de gateways';
    final val = int.tryParse(text);
    if (val == null || val < 1) {
      return 'Gateways deve ser a partir de 1';
    }
    return null;
  }

  String? get txPowerError {
    final text = txPowerController.text.trim();
    if (text.isEmpty) return 'Informe a potência TX';
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      return 'Potência deve ser maior que 0 dBm';
    }
    return null;
  }

  String? get rxSensitivityError {
    final rxText = rxSensitivityController.text.trim();
    if (rxText.isEmpty) return 'Informe a sensibilidade RX';
    final rxVal = double.tryParse(rxText);
    if (rxVal == null) return 'Sensibilidade inválida';

    final txText = txPowerController.text.trim();
    final txVal = double.tryParse(txText);
    if (txVal != null) {
      if (rxVal > txVal) {
        return 'Sensibilidade não pode ser maior que potência TX';
      }
    }
    return null;
  }

  String? get gatewayHeightError {
    final text = gatewayHeightController.text.trim();
    if (text.isEmpty) return 'Informe a altura do gateway';
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      return 'Altura deve ser maior que 0 metros';
    }
    return null;
  }

  String? get deviceHeightError {
    final text = deviceHeightController.text.trim();
    if (text.isEmpty) return 'Informe a altura do receptor';
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      return 'Altura deve ser maior que 0 metros';
    }
    return null;
  }

  String? get frequencyError {
    final text = frequencyController.text.trim();
    if (text.isEmpty) return 'Informe a frequência';
    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      return 'Frequência deve ser maior que 0';
    }
    return null;
  }

  bool get isValid {
    return coverageError == null &&
        gatewaysError == null &&
        txPowerError == null &&
        rxSensitivityError == null &&
        gatewayHeightError == null &&
        deviceHeightError == null &&
        frequencyError == null;
  }

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    final config = await _storageService.loadScenario();
    _applyModelToState(config);

    _isLoading = false;
    notifyListeners();
  }

  void _applyModelToState(ScenarioConfigModel config) {
    _selectedFrequencyPreset = config.frequencyPreset;
    _selectedPropagationModel = config.propagationModel;
    _minCoveragePercent = config.minCoveragePercent;
    _fadeMarginDb = config.fadeMarginDb;
    _religadoresChecked = config.religadoresChecked;
    _transformadoresChecked = config.transformadoresChecked;
    _medidoresChecked = config.medidoresChecked;

    frequencyController.text = config.frequencyMhz.toStringAsFixed(0);
    txPowerController.text = config.txPowerDbm.toStringAsFixed(0);
    rxSensitivityController.text = config.rxSensitivityDbm.toStringAsFixed(0);
    gatewayHeightController.text = config.gatewayHeightM.toStringAsFixed(1);
    deviceHeightController.text = config.deviceHeightM.toStringAsFixed(1);
    maxGatewaysController.text = config.maxGateways.toString();
  }

  ScenarioConfigModel toModel() {
    return ScenarioConfigModel(
      frequencyMhz: double.tryParse(frequencyController.text.trim()) ?? 915.0,
      frequencyPreset: _selectedFrequencyPreset,
      txPowerDbm: double.tryParse(txPowerController.text.trim()) ?? 21.0,
      rxSensitivityDbm:
          double.tryParse(rxSensitivityController.text.trim()) ?? -120.0,
      gatewayHeightM:
          double.tryParse(gatewayHeightController.text.trim()) ?? 6.0,
      deviceHeightM: double.tryParse(deviceHeightController.text.trim()) ?? 5.0,
      propagationModel: _selectedPropagationModel,
      minCoveragePercent: _minCoveragePercent,
      fadeMarginDb: _fadeMarginDb,
      maxGateways: int.tryParse(maxGatewaysController.text.trim()) ?? 12,
      religadoresChecked: _religadoresChecked,
      transformadoresChecked: _transformadoresChecked,
      medidoresChecked: _medidoresChecked,
    );
  }

  void setFrequencyPreset(String preset, double defaultFrequency) {
    _selectedFrequencyPreset = preset;
    frequencyController.text = defaultFrequency.toStringAsFixed(0);
    notifyListeners();
  }

  void setPropagationModel(String model) {
    _selectedPropagationModel = model;
    notifyListeners();
  }

  void setMinCoverage(double value) {
    _minCoveragePercent = value;
    notifyListeners();
  }

  void setFadeMargin(double value) {
    _fadeMarginDb = value;
    notifyListeners();
  }

  void toggleReligadores(bool? value) {
    _religadoresChecked = value ?? true;
    notifyListeners();
  }

  void toggleTransformadores(bool? value) {
    _transformadoresChecked = value ?? true;
    notifyListeners();
  }

  void toggleMedidores(bool? value) {
    _medidoresChecked = value ?? true;
    notifyListeners();
  }

  Future<bool> calculateScenario() async {
    if (!isValid) return false;

    _isCalculating = true;
    _successMessage = null;
    _errorMessage = null;
    _lastSimulationResult = null;
    notifyListeners();

    try {
      final model = toModel();
      await _storageService.saveScenario(model);

      final candidates = AreaDelimitationController.sharedResult?.candidates ?? [];
      if (candidates.isEmpty) {
        throw SimulationException('Nenhum candidato a gateway disponível. Configure a área na Etapa 1.');
      }

      final request = _buildSimulationRequest(model, candidates);
      final response = await _simulationService.runSimulationWithAuth(request);

      _lastSimulationResult = response;
      
      // Convert to SimulationScenario for results screen
      final config = AreaDelimitationController.sharedConfig;
      final scenario = response.toSimulationScenario(
        centerLat: config?.centerLatitude.toString() ?? '-23.298',
        centerLng: config?.centerLongitude.toString() ?? '-45.952',
        regionName: config?.address ?? 'Região EDP_SP',
      );
      
      // Navigate to results screen with real data
      _onSimulationComplete?.call(scenario);

      _isCalculating = false;
      _successMessage = 'Simulação concluída com sucesso!';
      notifyListeners();
      return true;
    } on SimulationException catch (e) {
      _isCalculating = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isCalculating = false;
      _errorMessage = 'Erro inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  SimulationRequest _buildSimulationRequest(ScenarioConfigModel model, List<CandidateAsset> candidates) {
    // Limit candidates to avoid OOM on backend (O(candidates × assets) complexity)
    const maxCandidates = 200;
    final limitedCandidates = candidates.length > maxCandidates
        ? _sampleCandidates(candidates, maxCandidates)
        : candidates;

    final gatewayCandidates = limitedCandidates.asMap().entries.map((entry) {
      final index = entry.key;
      final candidate = entry.value;
      return GatewayCandidateRequest(
        id: index + 1,
        source: candidate.bdgdId,
        assetKey: candidate.assetKey,
        latitude: candidate.latitude,
        longitude: candidate.longitude,
        estimatedCost: 1500.0,
      );
    }).toList();

    final propagationModelMap = {
      'Okumura-Hata Suburbano': 'OKUMURA_HATA_SUBURBAN',
      '3GPP Rural Macro': 'THREE_GPP_RURAL_MACRO',
      'ITM Longley-Rice': 'ITM_LONGLEY_RICE',
    };

    return SimulationRequest(
      name: 'Cenário ${DateTime.now().toString().substring(0, 16)}',
      regionName: AreaDelimitationController.sharedConfig?.address ?? 'Região não definida',
      coverageTargetPct: model.minCoveragePercent,
      maxGateways: model.maxGateways,
      gatewayCandidates: gatewayCandidates,
      propagationModel: propagationModelMap[model.propagationModel] ?? 'OKUMURA_HATA_SUBURBAN',
      gatewayUnitCost: 1500.0,
      rfParameter: RfParameterRequest(
        frequencyMhz: model.frequencyMhz,
        transmitPowerDbm: model.txPowerDbm,
        receiverSensitivityDbm: model.rxSensitivityDbm,
        antennaHeightM: model.gatewayHeightM,
        deviceHeightM: model.deviceHeightM,
        antennaGainDbi: 0.0,
        systemLossDb: model.fadeMarginDb,
      ),
    );
  }

  Future<void> saveCurrentState() async {
    final model = toModel();
    await _storageService.saveScenario(model);
  }

  Future<void> resetToDefaults() async {
    await _storageService.resetToDefaults();
    _applyModelToState(const ScenarioConfigModel());
    _successMessage = 'Parâmetros restaurados para o padrão de fábrica.';
    notifyListeners();
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  List<CandidateAsset> _sampleCandidates(List<CandidateAsset> candidates, int max) {
    if (candidates.length <= max) return candidates;

    final byType = <CandidateAssetType, List<CandidateAsset>>{};
    for (final c in candidates) {
      byType.putIfAbsent(c.type, () => []).add(c);
    }

    final result = <CandidateAsset>[];
    final perType = (max / byType.length).ceil();

    for (final list in byType.values) {
      list.shuffle();
      result.addAll(list.take(perType));
    }

    if (result.length > max) {
      result.shuffle();
      return result.take(max).toList();
    }
    return result;
  }

  void dispose() {
    txPowerController.dispose();
    rxSensitivityController.dispose();
    gatewayHeightController.dispose();
    deviceHeightController.dispose();
    maxGatewaysController.dispose();
    frequencyController.dispose();
    super.dispose();
  }
}
