import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/scenario_config_controller.dart';
import '../widgets/action_footer_bar.dart';
import '../widgets/optimization_criteria_card.dart';
import '../widgets/rf_parameters_card.dart';

class ScenarioConfigScreen extends StatefulWidget {
  final ScenarioConfigController? controller;

  const ScenarioConfigScreen({super.key, this.controller});

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RfParametersCard(controller: _controller),
                      const SizedBox(height: 18),
                      OptimizationCriteriaCard(controller: _controller),
                      const SizedBox(height: 18),
                      ActionFooterBar(controller: _controller),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
