import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../widgets/common/app_scaffold.dart';
import '../controllers/area_delimitation_controller.dart';
import '../widgets/area_delimitation_footer_bar.dart';
import '../widgets/area_delimitation_map.dart';
import '../widgets/candidate_assets_card.dart';
import '../widgets/scenario_wizard_stepper.dart';
import '../widgets/search_radius_card.dart';
import '../widgets/simulation_center_card.dart';

class AreaDelimitationScreen extends StatefulWidget {
  final AreaDelimitationController? controller;

  final bool enableMapTiles;

  const AreaDelimitationScreen({
    super.key,
    this.controller,
    this.enableMapTiles = true,
  });

  @override
  State<AreaDelimitationScreen> createState() => _AreaDelimitationScreenState();
}

class _AreaDelimitationScreenState extends State<AreaDelimitationScreen> {
  late final AreaDelimitationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AreaDelimitationController();
    _controller.init();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _navigateToStep2() {
    Navigator.of(context).pushReplacementNamed('/scenario/rf');
  }

  void _navigateToBdgd() {
    Navigator.of(context).pushReplacementNamed('/bdgd-import');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AppScaffold(
          title: 'Configuração de Cenário de Radiofrequência',
          currentRoute: '/scenario',
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScenarioWizardStepper(
                    currentStep: 1,
                    onStep2Tap: _controller.canAdvance
                        ? _navigateToStep2
                        : null,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 960) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SimulationCenterCard(controller: _controller),
                            const SizedBox(height: 14),
                            SearchRadiusCard(controller: _controller),
                            const SizedBox(height: 14),
                            CandidateAssetsCard(controller: _controller),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SimulationCenterCard(
                              controller: _controller,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SearchRadiusCard(controller: _controller),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CandidateAssetsCard(controller: _controller),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: isMobile ? 380 : 540,
                    child: AreaDelimitationMap(
                      controller: _controller,
                      enableTiles: widget.enableMapTiles,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AreaDelimitationFooterBar(
                    controller: _controller,
                    onBackToBdgd: _navigateToBdgd,
                    onAdvanceToStep2: _navigateToStep2,
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
