import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/password_reset_service.dart';

/// Tela de redefinição de senha acessada pelo link no e-mail.
/// Recebe o [token] via argumentos de rota ou query string.
class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _service = PasswordResetService();

  bool _isValidatingToken = true;
  bool _tokenValid = false;
  bool _isLoading = false;
  bool _success = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      await _service.validateToken(widget.token);
      if (!mounted) return;
      setState(() {
        _tokenValid = true;
        _isValidatingToken = false;
      });
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() {
        _tokenValid = false;
        _isValidatingToken = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final nova = _newPasswordController.text;
    final confirma = _confirmController.text;

    if (nova.isEmpty || confirma.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos.');
      return;
    }
    if (nova != confirma) {
      setState(() => _errorMessage = 'As senhas não coincidem.');
      return;
    }
    if (!_passwordStrong(nova)) {
      setState(() => _errorMessage =
          'A senha deve ter no mínimo 8 caracteres, letra maiúscula, minúscula, número e caractere especial.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _service.confirmReset(
        token: widget.token,
        novaSenha: nova,
        confirmarNovaSenha: confirma,
      );
      if (!mounted) return;
      setState(() {
        _success = true;
        _isLoading = false;
      });
    } on PasswordResetException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  bool _passwordStrong(String p) {
    return p.length >= 8 &&
        p.contains(RegExp(r'[A-Z]')) &&
        p.contains(RegExp(r'[a-z]')) &&
        p.contains(RegExp(r'[0-9]')) &&
        p.contains(RegExp(r'[^A-Za-z0-9]'));
  }

  /// Calcula a força de senha: 0–4
  int _strength(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: BackButton(color: AppColors.textDark),
        title: const Text(
          'Nova Senha',
          style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isValidatingToken) {
      return const Center(
        key: ValueKey('loading'),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (!_tokenValid) return _buildInvalidToken();
    if (_success) return _buildSuccess();
    return _buildForm();
  }

  Widget _buildInvalidToken() {
    return Column(
      key: const ValueKey('invalid'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.link_off_rounded,
            size: 52, color: AppColors.vermelhoErro),
        const SizedBox(height: 16),
        const Text(
          'Link inválido ou expirado',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ??
              'O link de redefinição de senha é inválido ou já expirou. Solicite um novo link.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textGray, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed('/forgot-password'),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Solicitar novo link'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 56, color: AppColors.verdeSucesso),
        const SizedBox(height: 20),
        const Text(
          'Senha redefinida!',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sua senha foi alterada com sucesso. Faça login com a nova senha.',
          style: TextStyle(fontSize: 13, color: AppColors.textGray, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ir para o Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _newPasswordController,
      builder: (context, value, _) {
        final s = _strength(value.text);
        return Column(
          key: const ValueKey('form'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 44, color: AppColors.primaryPurple),
            const SizedBox(height: 16),
            const Text(
              'Crie uma nova senha',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha uma senha forte para proteger sua conta.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textGray, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],
            _fieldLabel('Nova senha'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textLight, size: 20),
                hintText: 'Mínimo 8 caracteres',
                hintStyle:
                    const TextStyle(color: AppColors.textLight, fontSize: 13),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildStrengthBar(s),
            const SizedBox(height: 16),
            _fieldLabel('Confirmar nova senha'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textLight, size: 20),
                hintText: 'Repita a senha',
                hintStyle:
                    const TextStyle(color: AppColors.textLight, fontSize: 13),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)),
                      )
                    : const Text('Redefinir senha',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrengthBar(int strength) {
    final labels = ['Muito fraca', 'Fraca', 'Razoável', 'Forte', 'Muito forte'];
    final colors = [
      AppColors.vermelhoErro,
      Colors.orange,
      Colors.amber,
      AppColors.verdeSucesso,
      AppColors.verdeSucesso,
    ];
    final label = strength == 0 ? '' : labels[strength - 1];
    final color = strength == 0 ? AppColors.inputBorder : colors[strength - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength ? color : AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark));
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
