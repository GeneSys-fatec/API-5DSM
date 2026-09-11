import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/scenario_storage_service.dart';
import 'package:frontend/features/scenario_config/domain/models/scenario_config_model.dart';
import 'package:frontend/features/scenario_config/presentation/controllers/scenario_config_controller.dart';
import 'package:frontend/features/scenario_config/presentation/screens/scenario_config_screen.dart';

void main() {
  group('ScenarioConfigModel & ScenarioStorageService', () {
    test('Valores padrao do modelo de cenario estao corretos', () {
      const model = ScenarioConfigModel();
      expect(model.frequencyMhz, 915.0);
      expect(model.txPowerDbm, 21.0);
      expect(model.rxSensitivityDbm, -120.0);
      expect(model.gatewayHeightM, 6.0);
      expect(model.deviceHeightM, 5.0);
      expect(model.minCoveragePercent, 95.0);
      expect(model.maxGateways, 12);
      expect(model.fadeMarginDb, 14.0);
    });

    test('Serializacao e deserializacao preserva todos os parametros', () {
      const model = ScenarioConfigModel(
        frequencyMhz: 433.0,
        frequencyPreset: '433 MHz',
        txPowerDbm: 27.0,
        rxSensitivityDbm: -130.0,
        gatewayHeightM: 10.5,
        deviceHeightM: 4.0,
        minCoveragePercent: 98.0,
        fadeMarginDb: 20.0,
        maxGateways: 18,
      );

      final jsonString = model.toJson();
      final deserialized = ScenarioConfigModel.fromJson(jsonString);

      expect(deserialized.frequencyMhz, 433.0);
      expect(deserialized.frequencyPreset, '433 MHz');
      expect(deserialized.txPowerDbm, 27.0);
      expect(deserialized.rxSensitivityDbm, -130.0);
      expect(deserialized.gatewayHeightM, 10.5);
      expect(deserialized.deviceHeightM, 4.0);
      expect(deserialized.minCoveragePercent, 98.0);
      expect(deserialized.fadeMarginDb, 20.0);
      expect(deserialized.maxGateways, 18);
    });

    test('ScenarioStorageService grava e recupera cenario em memoria', () async {
      final storage = ScenarioStorageService();
      const customModel = ScenarioConfigModel(
        txPowerDbm: 25.0,
        maxGateways: 15,
      );

      await storage.saveScenario(customModel);
      final loaded = await storage.loadScenario();

      expect(loaded.txPowerDbm, 25.0);
      expect(loaded.maxGateways, 15);
    });
  });

  group('ScenarioConfigController Validations', () {
    late ScenarioConfigController controller;

    setUp(() {
      controller = ScenarioConfigController();
      controller.loadConfig();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Controlador inicializa com valores validos e isValid = true', () {
      expect(controller.isValid, isTrue);
      expect(controller.coverageError, isNull);
      expect(controller.gatewaysError, isNull);
      expect(controller.txPowerError, isNull);
      expect(controller.rxSensitivityError, isNull);
    });

    test('Valida faixa de cobertura (1% a 100%)', () {
      controller.setMinCoverage(0.5);
      expect(controller.coverageError, isNotNull);
      expect(controller.isValid, isFalse);

      controller.setMinCoverage(100.5);
      expect(controller.coverageError, isNotNull);
      expect(controller.isValid, isFalse);

      controller.setMinCoverage(95.0);
      expect(controller.coverageError, isNull);
      expect(controller.isValid, isTrue);
    });

    test('Valida limite de gateways (a partir de 1)', () {
      controller.maxGatewaysController.text = '0';
      expect(controller.gatewaysError, 'Gateways deve ser a partir de 1');
      expect(controller.isValid, isFalse);

      controller.maxGatewaysController.text = '';
      expect(controller.gatewaysError, 'Informe o número de gateways');
      expect(controller.isValid, isFalse);

      controller.maxGatewaysController.text = '5';
      expect(controller.gatewaysError, isNull);
      expect(controller.isValid, isTrue);
    });

    test('Valida que sensibilidade RX nao pode ser maior que potencia TX', () {
      controller.txPowerController.text = '21';
      controller.rxSensitivityController.text = '25';
      expect(controller.rxSensitivityError, 'Sensibilidade não pode ser maior que potência TX');
      expect(controller.isValid, isFalse);

      controller.rxSensitivityController.text = '-120';
      expect(controller.rxSensitivityError, isNull);
      expect(controller.isValid, isTrue);
    });
  });

  group('ScenarioConfigScreen Widget Tests', () {
    testWidgets('Renderiza todos os componentes e campos principais', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: ScenarioConfigScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Parâmetros de Tecnologia & Radiofrequência'), findsOneWidget);
      expect(find.text('915 MHz'), findsWidgets);
      expect(find.text('POTÊNCIA TX GATEWAY'), findsOneWidget);
      expect(find.text('SENSIBILIDADE RX'), findsOneWidget);
      expect(find.text('ALTURA DO GATEWAY'), findsOneWidget);
      expect(find.text('ALTURA DO RECEPTOR'), findsOneWidget);
      expect(find.text('Okumura-Hata Suburbano'), findsOneWidget);

      expect(find.text('Metas de Cobertura e Restrições de Orçamento'), findsOneWidget);
      expect(find.textContaining('META DE COBERTURA'), findsOneWidget);
      expect(find.textContaining('MARGEM DE DESVANECIMENTO'), findsOneWidget);
      expect(find.text('Limite de Gateways'), findsOneWidget);
      expect(find.textContaining('PRIORIDADE DE COBERTURA'), findsOneWidget);

      expect(find.text('Calcular Cenário'), findsOneWidget);
    });

    testWidgets('Bloqueia o botao Calcular Cenario quando campo e invalido', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ScenarioConfigController();
      await tester.pumpWidget(
        MaterialApp(home: ScenarioConfigScreen(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final calcularBtnFinder = find.widgetWithText(ElevatedButton, 'Calcular Cenário');
      await tester.ensureVisible(calcularBtnFinder);
      final calcularBtn = tester.widget<ElevatedButton>(calcularBtnFinder);
      expect(calcularBtn.onPressed, isNotNull);

      controller.maxGatewaysController.text = '0';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final calcularBtnDesabilitado = tester.widget<ElevatedButton>(calcularBtnFinder);
      expect(calcularBtnDesabilitado.onPressed, isNull);
      expect(find.text('Gateways deve ser a partir de 1'), findsOneWidget);
    });

    testWidgets('Dispara a simulacao ao clicar no botao habilitado', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ScenarioConfigController();
      await tester.pumpWidget(
        MaterialApp(home: ScenarioConfigScreen(controller: controller)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final calcularBtn = find.widgetWithText(ElevatedButton, 'Calcular Cenário');
      await tester.ensureVisible(calcularBtn);
      await tester.pumpAndSettle();

      final btnWidget = tester.widget<ElevatedButton>(calcularBtn);
      btnWidget.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.successMessage, isNotNull);
      expect(find.textContaining('Cenário salvo! Simulação de cobertura iniciada.'), findsOneWidget);
    });
  });
}
