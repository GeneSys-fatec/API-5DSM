import 'package:flutter/material.dart';
import '../shared/colors.dart';
import 'register.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _abaSelecionada = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoTela,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Container(
                decoration: BoxDecoration(
                  color: Cores.branco,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Cores.bordaCard),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final telaGrande = constraints.maxWidth > 750;

                    if (telaGrande) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: _construirBanner()),
                            Expanded(flex: 6, child: _construirFormulario()),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _construirBanner(compacto: true),
                        _construirFormulario(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirBanner({bool compacto = false}) {
    return Container(
      color: Cores.fundoBanner,
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 24 : 36,
        vertical: compacto ? 28 : 44,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Planejamento Inteligente\nde Radiofrequência para\nRedes Elétricas',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Plataforma computacional de alta fidelidade para simulação espectral, '
            'alocação ótima de gateways e conformidade regulatória para concessionárias de energia.',
            style: TextStyle(
              fontSize: 13,
              color: Cores.textoBanner,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          _construirCardDestaque(
            icon: Icons.hub_rounded,
            titulo: 'Integração Direta BDGD (ANEEL)',
            descricao:
                'Ingestão geoespacial de postes, transformadores e subestações sem perda topológica.',
          ),
          const SizedBox(height: 14),

          _construirCardDestaque(
            icon: Icons.memory_rounded,
            titulo: 'Otimização Heurística & IA (NSGA-II)',
            descricao:
                'Algoritmos genéticos para maximizar densidade de enlace e reduzir CAPEX de torres.',
          ),
        ],
      ),
    );
  }

  Widget _construirCardDestaque({
    required IconData icon,
    required String titulo,
    required String descricao,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.cardBanner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.bordaCardBanner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Cores.roxoClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Cores.amarelo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Cores.textoBanner,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirSeletorAbas(),
          const SizedBox(height: 28),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _abaSelecionada == 0
                ? Center(
                    key: const ValueKey('login_placeholder'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 48,
                            color: Cores.textoPlaceholder,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tela de Login em desenvolvimento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Cores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RegisterView(
                    key: const ValueKey('register_view'),
                    aoIrParaLogin: () {
                      setState(() => _abaSelecionada = 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirSeletorAbas() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Cores.fundoAbas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _construirItemAba(
              titulo: 'Entrar no Sistema',
              icon: Icons.login_rounded,
              selecionada: _abaSelecionada == 0,
              aoTocar: () => setState(() => _abaSelecionada = 0),
            ),
          ),
          Expanded(
            child: _construirItemAba(
              titulo: 'Criar Nova Conta',
              icon: Icons.person_add_alt_1_rounded,
              selecionada: _abaSelecionada == 1,
              aoTocar: () => setState(() => _abaSelecionada = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemAba({
    required String titulo,
    required IconData icon,
    required bool selecionada,
    required VoidCallback aoTocar,
  }) {
    return GestureDetector(
      onTap: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionada ? Cores.roxoPrincipal : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selecionada
              ? [
                  BoxShadow(
                    color: Cores.roxoPrincipal.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selecionada ? Colors.white : Cores.cinzaAzulado,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selecionada ? FontWeight.w600 : FontWeight.w500,
                  color: selecionada ? Colors.white : Cores.cinzaAzulado,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
