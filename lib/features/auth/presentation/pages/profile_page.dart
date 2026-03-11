import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/services/auth_service.dart';
import 'package:andicrochett/core/utils/helpers.dart';
import 'package:andicrochett/core/widgets/custom_button.dart';
import 'package:andicrochett/core/widgets/custom_input.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';

/// Página de perfil del usuario autenticado.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;
  String get _uid => _user?.uid ?? '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await _authService.updateDisplayName(name);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre actualizado'),
          backgroundColor: AppColors.verdeOliva,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(
        child: Text('No hay sesión activa',
            style: TextStyle(color: AppColors.texto)),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: _authService.watchProfile(_uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        // Pre-fill name controller when data arrives
        if (profile != null && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = profile.displayName;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.bronce.withValues(alpha: 0.2),
                    backgroundImage: _user!.photoURL != null &&
                            _user!.photoURL!.isNotEmpty
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                    child: _user!.photoURL == null || _user!.photoURL!.isEmpty
                        ? Text(
                            (_user!.displayName ?? _user!.email ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.bronce,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: Sizes.md),

                  // Email (read-only)
                  Text(
                    _user!.email ?? '',
                    style: const TextStyle(
                      fontSize: Sizes.fontSizeMd,
                      color: AppColors.texto,
                    ),
                  ),
                  if (profile != null)
                    Text(
                      'Miembro desde ${AppHelpers.formatShortDate(profile.createdAt)}',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.texto.withValues(alpha: 0.6),
                      ),
                    ),

                  const SizedBox(height: Sizes.xl),

                  // ── Editar nombre ──
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Sizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información personal',
                            style: TextStyle(
                              fontSize: Sizes.fontSizeLg,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textoFuerte,
                            ),
                          ),
                          const SizedBox(height: Sizes.md),
                          AppInput(
                            controller: _nameCtrl,
                            labelText: 'Nombre para mostrar',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: Sizes.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppButton.primary(
                              label: 'Guardar',
                              icon: Icons.save,
                              isLoading: _saving,
                              onPressed: _updateName,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Sizes.lg),

                  // ── Preferencias ──
                  if (profile != null)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Sizes.radiusLg),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Sizes.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferencias',
                              style: TextStyle(
                                fontSize: Sizes.fontSizeLg,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textoFuerte,
                              ),
                            ),
                            const SizedBox(height: Sizes.sm),
                            _PreferenceRow(
                              label: 'Tema',
                              value: profile.settings.theme == 'dark'
                                  ? 'Oscuro'
                                  : 'Claro',
                              icon: Icons.palette_outlined,
                            ),
                            _PreferenceRow(
                              label: 'Idioma',
                              value: profile.settings.language == 'en'
                                  ? 'English'
                                  : 'Español',
                              icon: Icons.language,
                            ),
                            _PreferenceRow(
                              label: 'Notificaciones',
                              value: profile.settings.notifications
                                  ? 'Activadas'
                                  : 'Desactivadas',
                              icon: Icons.notifications_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: Sizes.xl),

                  // ── Cerrar sesión ──
                  AppButton.danger(
                    label: 'Cerrar sesión',
                    icon: Icons.logout,
                    onPressed: _signOut,
                  ),

                  const SizedBox(height: Sizes.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.texto),
          const SizedBox(width: Sizes.sm),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textoFuerte)),
          ),
          Text(value,
              style: TextStyle(
                color: AppColors.texto,
                fontSize: Sizes.fontSizeSm,
              )),
        ],
      ),
    );
  }
}

