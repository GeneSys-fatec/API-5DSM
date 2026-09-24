import 'package:flutter/material.dart';
import '../../../../widgets/common/app_scaffold.dart';
import '../controllers/scenario_config_controller.dart';
import '../widgets/action_footer_bar.dart';
import '../widgets/optimization_criteria_card.dart';
import '../widgets/rf_parameters_card.dart';
import '../widgets/scenario_wizard_stepper.dart';
import '../../domain/models/area_delimitation_model.dart';

class ScenarioConfigScreen extends StatefulWidget {
  final ScenarioConfigController? controller;
  final AreaDelimitationConfig? areaConfig;

  const ScenarioConfigScreen({super.key, this.controller, this.areaConfig});

  @override
  State<ScenarioConfigScreen> createState() => _ScenarioConfigScreenState();
}

class _ScenarioConfigScreenState extends State<ScenarioConfigScreen> {
  late final ScenarioConfigController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScenarioConfigController();
    _controller.loadConfig();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _navigateToStep1() {
    _controller.saveCurrentState();
    Navigator.of(context).pushReplacementNamed('/scenario');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AppScaffold(
          title: 'Configuração de Cenário de Radiofrequência',
          currentRoute: '/scenario',
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScenarioWizardStepper(
                    currentStep: 2,
                    onStep1Tap: _navigateToStep1,
                  ),
                  const SizedBox(height: 18),
                  RfParametersCard(controller: _controller),
                  const SizedBox(height: 18),
                  OptimizationCriteriaCard(controller: _controller),
                  const SizedBox(height: 18),
                  ActionFooterBar(
                    controller: _controller,
                    onBackToStep1: _navigateToStep1,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
