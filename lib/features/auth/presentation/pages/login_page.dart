import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/constants/strings.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LoginPage
// ─────────────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final ok = await context.read<AuthProvider>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.read<AuthProvider>().errorMessage;
      });
    }
    // Si ok == true, el _AuthGate redirige automáticamente al Dashboard.
  }

  Future<void> _handleForgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'andi@crochet.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AuthProvider>().sendPasswordReset(
      emailCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Correo enviado. Revisa tu bandeja de entrada.'
              : context.read<AuthProvider>().errorMessage ?? 'Error',
        ),
        backgroundColor: ok ? AppColors.verdeOliva : AppColors.error,
      ),
    );
  }

  Future<void> _handleRegister() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear cuenta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerida';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final ok = await context.read<AuthProvider>().register(
      email: emailCtrl.text,
      password: passCtrl.text,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.read<AuthProvider>().errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Row(
            children: [
              // Panel izquierdo — solo en pantallas anchas
              if (isWide) const Expanded(child: _LeftPanel()),
              // Panel derecho — siempre visible
              Expanded(
                child: _RightPanel(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _handleSignIn,
                  onForgotPassword: _handleForgotPassword,
                  onRegister: _handleRegister,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Panel izquierdo con imagen + cita flotante
// ─────────────────────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen de fondo
        Image.network(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCyQQ-yDdvbJYYZtoNfVMiDMDeJotT9fRh_lwSTSnVv1GLst3kU6KBHU3jcdi7BZw6jiKs4TL2beRSMUh_LL3phjYO_E9-AOXmOancGVfc1P5LPXh6exXXXntAKNJEgNn_7ybE_KC_crtTSTzqeHkvoRP8NRYzxNnxcSedsnj85KKVPgzbr1Ki_FxpqkBbLQ3bL9fs_bJMSwuzUVDWM_uGalyHeO-ISoiiM-SKIxl_l0BdaA3CtaeXdUOoPjP-E8-WufHve5DA_mBs',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.lino),
        ),
        // Gradiente superpuesto
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.texto,
                AppColors.texto.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        // Cita flotante (parte inferior)
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.radiusXl),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lino.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(Sizes.radiusXl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(Sizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.texto,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        fontFamily: 'Lora',
                      ),
                      children: [
                        const TextSpan(text: 'Hecho a mano con '),
                        TextSpan(
                          text: 'amor',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 210, 138, 83),
                          ),
                        ),
                        const TextSpan(text: ',\ngestionado con '),
                        TextSpan(
                          text: 'corazón.',
                          style: const TextStyle(
                            color: Color.fromARGB(190, 105, 6, 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Sizes.md),
                  Text(
                    'Tu rincón creativo donde cada puntada cuenta\npara el éxito de tu negocio.',
                    style: TextStyle(
                      color: AppColors.textoFuerte,
                      fontSize: Sizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lora',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Panel derecho con el formulario
// ─────────────────────────────────────────────────────────────────────────────
class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onForgotPassword;
  final Future<void> Function() onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.xl,
            vertical: Sizes.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo + encabezado ──────────────────────────────────────
                _FormHeader(),
                const SizedBox(height: Sizes.xl),
                // ── Tarjeta del formulario ─────────────────────────────────
                _FormCard(
                  formKey: formKey,
                  emailController: emailController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  onTogglePassword: onTogglePassword,
                  onSubmit: onSubmit,
                  onForgotPassword: onForgotPassword,
                ),
                const SizedBox(height: Sizes.xl),
                // ── Footer ─────────────────────────────────────────────────
                _SignUpFooter(onRegister: onRegister),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Encabezado: ícono + título + subtítulo
// ─────────────────────────────────────────────────────────────────────────────
class _FormHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ícono circular
        Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            color: AppColors.bronce.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/images/logoAndi.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: Sizes.md),
        const Text(
          'Panel de Artesano',
          style: TextStyle(
            color: AppColors.textoFuerte,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            fontFamily: 'Lora',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Sizes.xs),
        Text(
          'Bienvenida a tu estudio digital.',
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

// ─────────────────────────────────────────────────────────────────────────────
//  Tarjeta con el formulario completo
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.bronce.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.bronce.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Sizes.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            _FieldLabel('Correo electrónico'),
            const SizedBox(height: Sizes.xs),
            _FilledField(
              controller: emailController,
              hint: 'andi@crochet.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: Sizes.md),
            // Contraseña
            _FieldLabel(AppStrings.password),
            const SizedBox(height: Sizes.xs),
            _FilledField(
              controller: passwordController,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              obscure: obscurePassword,
              onToggleObscure: onTogglePassword,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: Sizes.md),
            // ¿Olvidaste tu contraseña?
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPassword,
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: AppColors.resaltado,
                    fontSize: Sizes.fontSizeSm,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Sizes.xl),
            // Mensaje de error
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sizes.md,
                  vertical: Sizes.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Sizes.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: Sizes.sm),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: Sizes.fontSizeSm,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sizes.md),
            ],
            // Botón principal
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: AppColors.texto,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
                textStyle: const TextStyle(
                  fontSize: Sizes.fontSizeLg,
                  fontWeight: FontWeight.w700,
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
                  : const Text(AppStrings.login),
            ),
            const SizedBox(height: Sizes.xl),
            // Divisor "O continúa con"
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.sm),
                  child: Text(
                    'O continúa con',
                    style: TextStyle(
                      color: AppColors.texto,
                      fontSize: Sizes.fontSizeSm,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: Sizes.md),
            // Botones sociales
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                  ),
                ),
                const SizedBox(width: Sizes.md),
                Expanded(
                  child: _SocialButton(
                    label: 'Facebook',
                    icon: Icons.facebook_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets internos reutilizables
// ─────────────────────────────────────────────────────────────────────────────
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

class _FilledField extends StatelessWidget {
  const _FilledField({
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
          color: AppColors.texto.withValues(alpha: 0.4),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: autenticación social
      },
      icon: Icon(icon, size: Sizes.iconMd, color: AppColors.textoFuerte),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.textoFuerte,
          fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Footer "¿Aún no tienes cuenta?"
// ─────────────────────────────────────────────────────────────────────────────
class _SignUpFooter extends StatelessWidget {
  const _SignUpFooter({required this.onRegister});
  final Future<void> Function() onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Aún no tienes una cuenta? ',
          style: TextStyle(color: AppColors.texto, fontSize: Sizes.fontSizeSm),
        ),
        GestureDetector(
          onTap: onRegister,
          child: const Text(
            'Crear una cuenta',
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
