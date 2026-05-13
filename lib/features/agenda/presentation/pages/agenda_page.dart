// =============================================================================
//  AgendaPage
//  Pantalla de agenda / gestión de pedidos de clientes.
//
//  Muestra lista y calendario de pedidos, permite crear/editar desde OrderModel
//  y presenta una barra de estado con conteos por estado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/utils/helpers.dart';
import 'package:andicrochett/core/widgets/custom_button.dart';
import 'package:andicrochett/core/widgets/custom_input.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/agenda/presentation/widgets/calendar_widget.dart';
import 'package:andicrochett/features/agenda/data/repositories/order_repository.dart';

/// Pantalla de agenda con calendario y lista de pedidos.
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final OrderRepository _repo = OrderRepository();
  late final Stream<List<OrderModel>> _ordersStream;
  DateTime _selectedDay = DateTime.now();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _ordersStream = _repo.watchByUser(_userId);
  }

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  void _showOrderForm({OrderModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _OrderForm(
            existing: existing,
            defaultDate: _selectedDay,
            onSave: (order) async {
              if (existing != null) {
                await _repo.update(
                  order.copyWith(id: existing.id, userId: existing.userId),
                );
              } else {
                await _repo.create(order.copyWith(userId: _userId));
              }
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: Text('¿Eliminar el pedido de "${order.clientName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && order.id != null) await _repo.delete(order.id!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];
        final dayOrders = allOrders.where((o) {
          final dueDate = o.dueDate ?? o.createdAt;
          return dueDate.year == _selectedDay.year &&
              dueDate.month == _selectedDay.month &&
              dueDate.day == _selectedDay.day;
        }).toList();

        final pendingCount = allOrders
            .where((o) => o.status == OrderStatus.pending)
            .length;
        final inProgressCount = allOrders
            .where((o) => o.status == OrderStatus.inProgress)
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              color: AppColors.background,
              child: Column(
                children: [
                  // Header
                  _buildHeader(
                    isMobile: isMobile,
                    pendingCount: pendingCount,
                    inProgressCount: inProgressCount,
                  ),
                  // Content
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : isMobile
                        ? _buildMobileLayout(allOrders, dayOrders)
                        : _buildDesktopLayout(allOrders, dayOrders),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isMobile,
    required int pendingCount,
    required int inProgressCount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? Sizes.md : Sizes.lg,
        vertical: Sizes.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.lino, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agenda de Pedidos',
                  style: TextStyle(
                    fontSize: Sizes.fontSizeXxl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: Sizes.md,
                  children: [
                    Text(
                      'Pendientes: $pendingCount',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'En proceso: $inProgressCount',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.verdeOliva,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: Sizes.buttonHeightSm,
            child: ElevatedButton(
              onPressed: () => _showOrderForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.resaltado,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, Sizes.buttonHeightSm),
                padding: const EdgeInsets.symmetric(horizontal: Sizes.md),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Nuevo pedido',
                    style: TextStyle(
                      fontSize: Sizes.fontSizeSm,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    List<OrderModel> allOrders,
    List<OrderModel> dayOrders,
  ) {
    return Padding(
      padding: const EdgeInsets.all(Sizes.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendario
          SizedBox(
            width: 340,
            child: CalendarWidget(
              orders: allOrders,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
          ),
          const SizedBox(width: Sizes.lg),
          // Lista de pedidos del día
          Expanded(
            child: SingleChildScrollView(child: _buildOrdersList(dayOrders)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    List<OrderModel> allOrders,
    List<OrderModel> dayOrders,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.md),
      child: Column(
        children: [
          CalendarWidget(
            orders: allOrders,
            selectedDay: _selectedDay,
            onDaySelected: (day) => setState(() => _selectedDay = day),
          ),
          const SizedBox(height: Sizes.md),
          _buildOrdersList(dayOrders),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 48, color: AppColors.texto),
            const SizedBox(height: Sizes.sm),
            Text(
              'Sin pedidos para ${AppHelpers.formatDate(_selectedDay)}',
              style: TextStyle(
                fontSize: Sizes.fontSizeMd,
                color: AppColors.texto,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedidos para ${AppHelpers.formatDate(_selectedDay)}',
          style: const TextStyle(
            fontSize: Sizes.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: AppColors.textoFuerte,
          ),
        ),
        const SizedBox(height: Sizes.md),
        ...orders.map(
          (order) => _OrderCard(
            order: order,
            onTap: () => _showOrderForm(existing: order),
            onStatusChange: (status) {
              if (order.id != null) _repo.updateStatus(order.id!, status);
            },
            onDelete: () => _confirmDelete(order),
          ),
        ),
      ],
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onStatusChange,
    required this.onDelete,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final ValueChanged<OrderStatus> onStatusChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.inProgress => AppColors.verdeOliva,
      OrderStatus.completed => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        side: BorderSide(color: AppColors.lino),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: const TextStyle(
                        fontSize: Sizes.fontSizeLg,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoFuerte,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 18,
                    onSelected: (action) {
                      switch (action) {
                        case 'pending':
                          onStatusChange(OrderStatus.pending);
                        case 'in_progress':
                          onStatusChange(OrderStatus.inProgress);
                        case 'completed':
                          onStatusChange(OrderStatus.completed);
                        case 'cancelled':
                          onStatusChange(OrderStatus.cancelled);
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'pending',
                        child: Text('Pendiente'),
                      ),
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Text('En proceso'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Completado'),
                      ),
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelado'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.customerContact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.customerContact,
                  style: TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
              ],
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: Sizes.sm),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: TextStyle(
                            fontSize: Sizes.fontSizeSm,
                            fontWeight: FontWeight.w600,
                            color: AppColors.resaltado,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: Sizes.fontSizeSm,
                              color: AppColors.texto,
                            ),
                          ),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: Sizes.fontSizeSm,
                            color: AppColors.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: Sizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${order.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoFuerte,
                      ),
                    ),
                  ],
                ),
              ],
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: Sizes.sm),
                Text(
                  order.notes,
                  style: TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    fontStyle: FontStyle.italic,
                    color: AppColors.texto,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Form ──────────────────────────────────────────────────────────────

class _OrderForm extends StatefulWidget {
  const _OrderForm({
    this.existing,
    required this.defaultDate,
    required this.onSave,
  });

  final OrderModel? existing;
  final DateTime defaultDate;
  final Future<void> Function(OrderModel order) onSave;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _customerContactCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _totalPriceCtrl;
  late DateTime _dueDate;
  late OrderStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _customerNameCtrl = TextEditingController(text: e?.clientName ?? '');
    _customerContactCtrl = TextEditingController(
      text: e?.customerContact ?? '',
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _totalPriceCtrl = TextEditingController(
      text: e != null ? e.totalPrice.toStringAsFixed(0) : '',
    );
    _dueDate = e?.dueDate ?? widget.defaultDate;
    _status = e?.status ?? OrderStatus.pending;
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerContactCtrl.dispose();
    _notesCtrl.dispose();
    _totalPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final order = OrderModel(
      id: widget.existing?.id,
      userId: widget.existing?.userId ?? '',
      clientName: _customerNameCtrl.text.trim(),
      customerContact: _customerContactCtrl.text.trim(),
      items: widget.existing?.items ?? [],
      totalPrice: double.tryParse(_totalPriceCtrl.text.trim()) ?? 0,
      status: _status,
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(order);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Editar Pedido' : 'Nuevo Pedido',
              style: const TextStyle(
                fontSize: Sizes.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            const SizedBox(height: Sizes.lg),

            AppInput(
              controller: _customerNameCtrl,
              labelText: 'Nombre del cliente',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: Sizes.md),

            AppInput(
              controller: _customerContactCtrl,
              labelText: 'Contacto (teléfono o email)',
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: Sizes.md),

            // Fecha de entrega
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de entrega',
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Sizes.radiusLg),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(AppHelpers.formatDate(_dueDate)),
              ),
            ),
            const SizedBox(height: Sizes.md),

            AppInput(
              controller: _totalPriceCtrl,
              labelText: 'Precio total',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Sizes.md),

            // Estado
            DropdownButtonFormField<OrderStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Sizes.md,
                  vertical: Sizes.sm + 4,
                ),
              ),
              items: OrderStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _status = v ?? OrderStatus.pending),
            ),
            const SizedBox(height: Sizes.md),

            AppInput(
              controller: _notesCtrl,
              labelText: 'Notas',
              prefixIcon: Icons.note_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: Sizes.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outlined(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: Sizes.md),
                AppButton.primary(
                  label: isEditing ? 'Actualizar' : 'Crear',
                  icon: isEditing ? Icons.save : Icons.add,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
