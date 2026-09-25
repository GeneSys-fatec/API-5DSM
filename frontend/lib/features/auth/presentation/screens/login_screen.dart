import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';
import '../screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialLoginMode;
  const LoginScreen({super.key, this.initialLoginMode = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    if (!widget.initialLoginMode) {
      _controller.setLoginMode(false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final success = await _controller.submit();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Autenticação realizada com sucesso!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/bdgd-import');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 960 : 480,
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: isDesktop
                              ? LayoutBuilder(
                                  builder: (context, cardConstraints) {
                                    final halfWidth =
                                        cardConstraints.maxWidth / 2;
                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: halfWidth,
                                          child: _buildLeftInstitutionalPanel(),
                                        ),
                                        Row(
                                          children: [
                                            const Spacer(flex: 5),
                                            Expanded(
                                              flex: 5,
                                              child: _buildRightFormPanel(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLeftInstitutionalPanel(
                                      isMobile: true,
                                    ),
                                    _buildRightFormPanel(isDesktop: false),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7), width: 1)),
      ),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo.png',
        height: 32,
        errorBuilder: (context, error, stackTrace) {
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub, color: Color(0xFF1E3A8A), size: 24),
              SizedBox(width: 8),
              Text(
                'TECSYS®',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftInstitutionalPanel({bool isMobile = false}) {
    return Container(
      color: AppColors.darkPurple,
      padding: EdgeInsets.all(isMobile ? 24 : 36),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Planejamento Inteligente\nde Radiofrequência para\nRedes Elétricas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Plataforma computacional de alta fidelidade para simulação espectral, alocação ótima de gateways e conformidade regulatória para concessionárias de energia.',
                style: TextStyle(
                  color: AppColors.textLilac,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _buildFeatureBadge(
                icon: Icons.hub_rounded,
                title: 'Integração Direta BDGD (ANEEL)',
                description:
                    'Ingestão geoespacial de postes, transformadores e subestações sem perda topológica.',
                iconColor: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPurple, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.iconContainerPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF9D94B2),
                    fontSize: 11,
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

  Widget _buildRightFormPanel({bool isDesktop = true}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 24,
            vertical: 34,
          ),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabSwitcher(),
                const SizedBox(height: 28),
                ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                    transitionBuilder: (child, animation) {
                      final isRegister =
                          (child.key as ValueKey<String>?)?.value ==
                          'register_form_view';
                      final offset = isRegister
                          ? const Offset(0.25, 0.0)
                          : const Offset(-0.25, 0.0);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: offset,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: _controller.isLoginMode
                        ? KeyedSubtree(
                            key: const ValueKey('login_form_view'),
                            child: _buildLoginForm(),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('register_form_view'),
                            child: RegisterView(
                              aoIrParaLogin: () =>
                                  _controller.setLoginMode(true),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Acesse a Plataforma',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 22),
        if (_controller.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildLabelWithAsterisk('E-mail'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            hintText: 'nome@distribuidora.com.br',
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabelWithAsterisk('Senha'),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recuperação de senha em desenvolvimento.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              hoverColor: Colors.transparent,
              child: const Text(
                'Esqueceu a senha?',
                style: TextStyle(
                  color: AppColors.linkPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.passwordController,
          obscureText: !_controller.isPasswordVisible,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _handleSubmit(),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _controller.isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textLight,
                size: 20,
              ),
              onPressed: _controller.togglePasswordVisibility,
            ),
            hintText: 'Digite sua senha',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              shadowColor: AppColors.primaryPurple.withValues(alpha: 0.4),
            ),
            child: _controller.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Acessar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelWithAsterisk(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 3),
        const Text(
          '*',
          style: TextStyle(
            color: AppColors.linkPurple,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    final isLogin = _controller.isLoginMode;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                alignment: isLogin
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _controller.setLoginMode(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              size: 16,
                              color: isLogin
                                  ? Colors.white
                                  : AppColors.textGray,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Entrar no Sistema',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLogin
                                      ? Colors.white
                                      : AppColors.textGray,
                                  fontSize: 13,
                                  fontWeight: isLogin
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _controller.setLoginMode(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 16,
                              color: !isLogin
                                  ? Colors.white
                                  : AppColors.textGray,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Criar Nova Conta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: !isLogin
                                      ? Colors.white
                                      : AppColors.textGray,
                                  fontSize: 13,
                                  fontWeight: !isLogin
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
