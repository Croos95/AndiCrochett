import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Botón para compartir el enlace del catálogo público del usuario.
///
/// Copia el enlace al portapapeles y muestra un SnackBar de confirmación.
/// Cuando `share_plus` se agregue al proyecto, se puede extender con
/// el compartir nativo del dispositivo.
class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.catalogUrl,
    this.label = 'Compartir catálogo',
  });

  /// URL del catálogo público que se va a compartir.
  final String catalogUrl;

  /// Texto visible en el botón.
  final String label;

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: catalogUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enlace copiado al portapapeles'),
          backgroundColor: AppColors.verdeOliva,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.radiusMd),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _share(context),
      icon: const Icon(Icons.share, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.resaltado,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
