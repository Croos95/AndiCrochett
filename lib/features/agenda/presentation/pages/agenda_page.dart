// =============================================================================
//  AgendaPage
//  Pantalla de agenda / gestión de pedidos de clientes.
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
//  Actualmente el dashboard muestra el texto 'Agenda' como placeholder.
//  Esta pantalla reemplazará ese placeholder y mostrará:
//    - Lista/calendario de pedidos.
//    - Creación y edición de pedidos desde OrderModel.
//    - Barra de estado con conteos (pendientes, en proceso, completados).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';

/// Pantalla de agenda — implementación pendiente.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Agenda — próximamente',
        style: TextStyle(fontSize: 18, color: AppColors.texto),
      ),
    );
  }
}
