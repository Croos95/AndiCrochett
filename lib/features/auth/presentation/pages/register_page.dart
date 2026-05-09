import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showVerificationNotice = false;
  String? _registeredEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _showVerificationNotice = false;
      _registeredEmail = null;
    });

    final ok = await context.read<AuthProvider>().register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      setState(() {
        _showVerificationNotice = true;
        _registeredEmail = _emailController.text.trim();
      });
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final ok = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ??
                'No se pudo continuar con Google.',
          ),
        ),
      );
    }
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          return Row(
            children: [
              if (isWide) const Expanded(child: _RegisterHeroPanel()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sizes.xl,
                      vertical: Sizes.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RegisterHeader(),
                          const SizedBox(height: Sizes.xl),
                          if (_showVerificationNotice)
                            _VerificationNotice(
                              email:
                                  _registeredEmail ??
                                  _emailController.text.trim(),
                              onGoToLogin: _goToLogin,
                              onResend: () async {
                                final success = await context
                                    .read<AuthProvider>()
                                    .resendVerificationEmail();
                                if (!mounted) return;
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context
                                                .read<AuthProvider>()
                                                .errorMessage ??
                                            'No se pudo reenviar el correo.',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Correo de verificación reenviado.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onVerified: () async {
                                final verified = await context
                                    .read<AuthProvider>()
                                    .refreshVerificationStatus();
                                if (!mounted) return;
                                if (!verified) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Aún no vemos la verificación. Revisa tu correo e inténtalo otra vez.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          else
                            _RegisterCard(
                              formKey: _formKey,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              obscurePassword: _obscurePassword,
                              obscureConfirmPassword: _obscureConfirmPassword,
                              isLoading: auth.status == AuthStatus.loading,
                              errorMessage: auth.errorMessage,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirmPassword: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              onSubmit: _handleRegister,
                              onGoogleSignIn: _handleGoogleSignIn,
                            ),
                          const SizedBox(height: Sizes.xl),
                          _LoginFooter(onLogin: _goToLogin),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RegisterHeroPanel extends StatelessWidget {
  const _RegisterHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1509343256512-d77a5cb3791b?auto=format&fit=crop&w=1200&q=80',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.lino),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.texto.withValues(alpha: 0.96),
                AppColors.texto.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
        Positioned(
          left: 48,
          right: 48,
          bottom: 48,
          child: Container(
            padding: const EdgeInsets.all(Sizes.xl),
            decoration: BoxDecoration(
              color: AppColors.lino.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(Sizes.radiusXl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Empieza con una cuenta clara y segura',
                  style: TextStyle(
                    color: AppColors.textoFuerte,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    fontFamily: 'Lora',
                  ),
                ),
                const SizedBox(height: Sizes.md),
                Text(
                  'Registra tu taller con email o Google, confirma tu correo y accede a tu panel cuando todo quede verificado.',
                  style: TextStyle(
                    color: AppColors.texto,
                    fontSize: Sizes.fontSizeMd,
                    fontFamily: 'Lora',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.bronce.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset('assets/images/logoAndi.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: Sizes.md),
        const Text(
          'Crear cuenta',
          style: TextStyle(
            color: AppColors.textoFuerte,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontFamily: 'Lora',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Sizes.xs),
        Text(
          'Email, Google y verificación en un flujo limpio.',
          style: TextStyle(
            color: AppColors.texto,
            fontSize: Sizes.fontSizeMd,
            fontFamily: 'Lora',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
    required this.onGoogleSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.bronce.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.bronce.withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: 'Regístrate en segundos',
              subtitle: 'Usa Google o crea una cuenta con correo y contraseña.',
            ),
            const SizedBox(height: Sizes.lg),
            _SocialActionButton(
              label: 'Continuar con Google',
              icon: Icons.g_mobiledata_rounded,
              onPressed: onGoogleSignIn,
            ),
            const SizedBox(height: Sizes.md),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.sm),
                  child: Text(
                    'o con email',
                    style: TextStyle(
                      color: AppColors.texto,
                      fontSize: Sizes.fontSizeSm,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: Sizes.lg),
            _FieldLabel('Correo electrónico'),
            const SizedBox(height: Sizes.xs),
            _AuthInputField(
              controller: emailController,
              hint: 'andi@crochet.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!value.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: Sizes.md),
            _FieldLabel('Contraseña'),
            const SizedBox(height: Sizes.xs),
            _AuthInputField(
              controller: passwordController,
              hint: 'Mínimo 6 caracteres',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              obscure: obscurePassword,
              onToggleObscure: onTogglePassword,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Ingresa tu contraseña';
                if (value.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: Sizes.md),
            _FieldLabel('Confirmar contraseña'),
            const SizedBox(height: Sizes.xs),
            _AuthInputField(
              controller: confirmPasswordController,
              hint: 'Repite tu contraseña',
              prefixIcon: Icons.password_outlined,
              obscureText: true,
              obscure: obscureConfirmPassword,
              onToggleObscure: onToggleConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: Sizes.lg),
            if (errorMessage != null) ...[
              _ErrorBanner(message: errorMessage!),
              const SizedBox(height: Sizes.md),
            ],
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: AppColors.texto,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.texto,
                      ),
                    )
                  : const Text(
                      'Crear cuenta y enviar verificación',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeMd,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: Sizes.md),
            Text(
              'Al registrarte, recibirás un correo para verificar tu acceso antes de entrar al panel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.texto.withValues(alpha: 0.75),
                fontSize: Sizes.fontSizeSm,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice({
    required this.email,
    required this.onGoToLogin,
    required this.onResend,
    required this.onVerified,
  });

  final String email;
  final Future<void> Function() onGoToLogin;
  final Future<void> Function() onResend;
  final Future<void> Function() onVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.verdeOliva.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeOliva.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.verdeOliva,
            size: 40,
          ),
          const SizedBox(height: Sizes.md),
          const Text(
            'Verifica tu correo',
            style: TextStyle(
              color: AppColors.textoFuerte,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Lora',
            ),
          ),
          const SizedBox(height: Sizes.xs),
          Text(
            'Te enviamos un enlace a $email. Abre el correo, confirma tu cuenta y luego inicia sesión.',
            style: TextStyle(
              color: AppColors.texto,
              fontSize: Sizes.fontSizeMd,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Sizes.lg),
          Wrap(
            spacing: Sizes.md,
            runSpacing: Sizes.md,
            children: [
              SizedBox(
                width: 150,
                child: OutlinedButton(
                  onPressed: onResend,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                    ),
                  ),
                  child: const Text('Reenviar correo'),
                ),
              ),
              SizedBox(
                width: 170,
                child: ElevatedButton(
                  onPressed: onVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeOliva,
                    foregroundColor: AppColors.texto,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                    ),
                  ),
                  child: const Text('Ya verifiqué'),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextButton(
                  onPressed: onGoToLogin,
                  child: const Text('Ir a iniciar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.onLogin});

  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: TextStyle(color: AppColors.texto, fontSize: Sizes.fontSizeSm),
        ),
        GestureDetector(
          onTap: onLogin,
          child: const Text(
            'Inicia sesión',
            style: TextStyle(
              color: AppColors.resaltado,
              fontSize: Sizes.fontSizeSm,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textoFuerte,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Lora',
          ),
        ),
        const SizedBox(height: Sizes.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.texto,
            fontSize: Sizes.fontSizeMd,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textoFuerte,
        fontSize: Sizes.fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.obscure = false,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText && obscure,
      validator: validator,
      style: const TextStyle(
        color: AppColors.texto,
        fontSize: Sizes.fontSizeMd,
        fontFamily: 'Lora',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.texto.withValues(alpha: 0.42),
          fontSize: Sizes.fontSizeMd,
          fontFamily: 'Lora',
        ),
        filled: true,
        fillColor: AppColors.lino,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.texto,
          size: Sizes.iconMd,
        ),
        suffixIcon: obscureText
            ? IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.verdeOliva,
                  size: Sizes.iconMd,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.bronce, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  const _SocialActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: Sizes.iconMd, color: AppColors.textoFuerte),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.textoFuerte,
          fontWeight: FontWeight.w600,
          fontSize: Sizes.fontSizeSm,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusMd),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.md,
        vertical: Sizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: Sizes.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: Sizes.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
