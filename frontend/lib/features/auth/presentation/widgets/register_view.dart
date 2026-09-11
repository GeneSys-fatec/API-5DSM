import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback aoIrParaLogin;

  const RegisterView({super.key, required this.aoIrParaLogin});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;
  bool _carregando = false;
  bool _mostrarMensagemSucesso = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _enviarFormulario() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _carregando = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _mostrarMensagemSucesso = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_mostrarMensagemSucesso) _construirBannerSucesso(),
          _construirTitulo(),
          const SizedBox(height: 22),

          _campoNome(),
          const SizedBox(height: 16),

          _campoEmail(),
          const SizedBox(height: 16),

          _campoSenha(),
          const SizedBox(height: 16),

          _campoConfirmarSenha(),
          const SizedBox(height: 24),

          _botaoCadastrar(),
          const SizedBox(height: 16),

          _linkJaTemConta(),
        ],
      ),
    );
  }

  Widget _construirTitulo() {
    return const Text(
      'Crie sua Conta',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _campoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Nome Completo'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nomeController,
          textInputAction: TextInputAction.next,
          decoration: _decoracaoInput(
            dica: 'Insera seu nome completo',
            icone: Icons.person_outline_rounded,
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
      ],
    );
  }

  Widget _campoEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('E-mail'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoracaoInput(
            dica: 'Insera seu e-mail',
            icone: Icons.mail_outline_rounded,
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
      ],
    );
  }

  Widget _campoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Senha'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _senhaController,
          obscureText: _ocultarSenha,
          textInputAction: TextInputAction.next,
          decoration: _decoracaoInput(
            dica: '••••••••••••',
            icone: Icons.lock_outline_rounded,
            sufixo: IconButton(
              icon: Icon(
                _ocultarSenha
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _ocultarSenha = !_ocultarSenha;
                });
              },
              tooltip: _ocultarSenha ? 'Ver senha' : 'Ocultar senha',
            ),
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
      ],
    );
  }

  Widget _campoConfirmarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirRotulo('Confirmar Senha'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: _ocultarConfirmarSenha,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _enviarFormulario(),
          decoration: _decoracaoInput(
            dica: '••••••••••••',
            icone: Icons.lock_outline_rounded,
            sufixo: IconButton(
              icon: Icon(
                _ocultarConfirmarSenha
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _ocultarConfirmarSenha = !_ocultarConfirmarSenha;
                });
              },
              tooltip: _ocultarConfirmarSenha ? 'Ver senha' : 'Ocultar senha',
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Confirme sua senha';
            }
            if (valor != _senhaController.text) {
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _botaoCadastrar() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _carregando ? null : _enviarFormulario,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Cadastrar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _linkJaTemConta() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Já tem uma conta? ',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        TextButton(
          onPressed: widget.aoIrParaLogin,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Já tenho uma conta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _construirBannerSucesso() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fundoSucesso,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bordaSucesso),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.verdeSucesso, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cadastro realizado com sucesso!',
              style: TextStyle(
                color: AppColors.textoSucesso,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRotulo(String rotulo) {
    return Row(
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  InputDecoration _decoracaoInput({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: Icon(icone, color: AppColors.textLight, size: 19),
      suffixIcon: sufixo,
      filled: true,
      fillColor: AppColors.inputBackground,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.vermelhoErro),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.vermelhoErro, width: 1.5),
      ),
    );
  }
}
