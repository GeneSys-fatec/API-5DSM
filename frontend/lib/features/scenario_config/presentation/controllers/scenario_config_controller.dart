import 'package:flutter/material.dart';
import '../../data/services/scenario_storage_service.dart';
import '../../domain/models/scenario_config_model.dart';

class ScenarioConfigController extends ChangeNotifier {
  final ScenarioStorageService _storageService;

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

  ScenarioConfigController({ScenarioStorageService? storageService})
      : _storageService = storageService ?? ScenarioStorageService() {
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
      rxSensitivityDbm: double.tryParse(rxSensitivityController.text.trim()) ?? -120.0,
      gatewayHeightM: double.tryParse(gatewayHeightController.text.trim()) ?? 6.0,
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
    notifyListeners();

    final model = toModel();
    await _storageService.saveScenario(model);

    await Future.delayed(const Duration(milliseconds: 100));

    _isCalculating = false;
    _successMessage = 'Cenário salvo e cálculo de simulação disparado com sucesso!';
    notifyListeners();
    return true;
  }

  Future<void> resetToDefaults() async {
    await _storageService.resetToDefaults();
    _applyModelToState(const ScenarioConfigModel());
    _successMessage = 'Parâmetros restaurados para o padrão de fábrica.';
    notifyListeners();
  }

  @override
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
