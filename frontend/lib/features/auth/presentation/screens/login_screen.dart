import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  final bool initialLoginMode;

  const LoginScreen({super.key, this.initialLoginMode = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();

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
    if (!_controller.isLoginMode) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
    }

    final success = await _controller.submit();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                _controller.isLoginMode
                    ? 'Autenticação realizada com sucesso!'
                    : 'Cadastro realizado com sucesso!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 960 : 480,
                      ),
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
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _buildLeftInstitutionalPanel(),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: _buildRightFormPanel(),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLeftInstitutionalPanel(isMobile: true),
                                  _buildRightFormPanel(isDesktop: false),
                                ],
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDF2F7), width: 1),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/tecsys_logo.png',
        height: 28,
        errorBuilder: (context, error, stackTrace) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
          const SizedBox(height: 14),
          _buildFeatureBadge(
            icon: Icons.memory_rounded,
            title: 'Otimização Heurística & IA (NSGA-II)',
            description:
                'Algoritmos genéticos para maximizar densidade de enlace e reduzir CAPEX de torres.',
            iconColor: AppColors.iconGold,
          ),
        ],
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
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabSwitcher(),
                  const SizedBox(height: 28),
                  if (_controller.showSuccessMessage && !_controller.isLoginMode)
                    _buildSuccessBanner(),
                  Text(
                    _controller.isLoginMode ? 'Acesse a Plataforma' : 'Crie sua Conta',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_controller.errorMessage != null) ...[
                    _buildErrorBanner(_controller.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (_controller.isLoginMode) ...[
                    _buildLoginForm(),
                  ] else ...[
                    _buildRegisterForm(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cadastro realizado com sucesso!',
              style: TextStyle(
                color: AppColors.successText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              tooltip: _controller.isPasswordVisible ? 'Ocultar senha' : 'Ver senha',
              onPressed: _controller.togglePasswordVisibility,
            ),
            hintText: 'Digite sua senha',
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        _buildSubmitButton('Acessar'),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Ainda não tem conta? ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  _formKey.currentState?.reset();
                  _controller.setLoginMode(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.linkPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Criar nova conta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelWithAsterisk('Nome Completo'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.nameController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.name],
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            hintText: 'Insira seu nome completo',
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Informe seu nome completo';
            }
            if (valor.trim().split(' ').length < 2) {
              return 'Informe seu nome e sobrenome';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabelWithAsterisk('E-mail'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.email],
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
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Informe seu e-mail';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(valor.trim())) {
              return 'Informe um e-mail válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabelWithAsterisk('Senha'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.passwordController,
          obscureText: !_controller.isPasswordVisible,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
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
              tooltip: _controller.isPasswordVisible ? 'Ocultar senha' : 'Ver senha',
              onPressed: _controller.togglePasswordVisibility,
            ),
            hintText: 'Digite sua senha',
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Informe sua senha';
            }
            if (valor.length < 6) {
              return 'A senha deve conter no mínimo 6 caracteres';
            }
            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(valor)) {
              return 'Use letras e números';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildLabelWithAsterisk('Confirmar Senha'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller.confirmPasswordController,
          obscureText: !_controller.isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
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
                _controller.isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textLight,
                size: 20,
              ),
              tooltip: _controller.isConfirmPasswordVisible ? 'Ocultar senha' : 'Ver senha',
              onPressed: _controller.toggleConfirmPasswordVisibility,
            ),
            hintText: 'Confirme sua senha',
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Confirme sua senha';
            }
            if (valor != _controller.passwordController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildSubmitButton('Cadastrar'),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Já tem uma conta? ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  _formKey.currentState?.reset();
                  _controller.setLoginMode(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.linkPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Já tenho uma conta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String title) {
    return SizedBox(
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              isSelected: _controller.isLoginMode,
              title: 'Entrar no Sistema',
              icon: Icons.login_rounded,
              onTap: () {
                _formKey.currentState?.reset();
                _controller.setLoginMode(true);
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              isSelected: !_controller.isLoginMode,
              title: 'Criar Nova Conta',
              icon: Icons.person_add_alt_1_outlined,
              onTap: () {
                _formKey.currentState?.reset();
                _controller.setLoginMode(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required bool isSelected,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.28),
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
              color: isSelected ? Colors.white : AppColors.textGray,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textGray,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
