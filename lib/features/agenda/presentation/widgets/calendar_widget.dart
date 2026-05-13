import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Widget de calendario mensual simple para la vista de agenda.
///
/// No depende de paquetes externos (table_calendar).
/// Muestra días con pedidos marcados y permite seleccionar un día.
class CalendarWidget extends StatefulWidget {
  const CalendarWidget({
    super.key,
    required this.orders,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<OrderModel> orders;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  bool _hasOrders(DateTime day) {
    return widget.orders.any((o) {
      final dueDate = o.dueDate ?? o.createdAt;
      return dueDate.year == day.year &&
          dueDate.month == day.month &&
          dueDate.day == day.day;
    });
  }

  bool _isSelected(DateTime day) {
    return widget.selectedDay.year == day.year &&
        widget.selectedDay.month == day.month &&
        widget.selectedDay.day == day.day;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.lino),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con mes y flechas de navegación
          _buildMonthHeader(),
          const SizedBox(height: Sizes.sm),
          // Días de la semana
          _buildWeekDayHeaders(),
          const SizedBox(height: Sizes.xs),
          // Grid de días
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          color: AppColors.texto,
          splashRadius: 18,
        ),
        Text(
          '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
          style: const TextStyle(
            fontSize: Sizes.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: AppColors.textoFuerte,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          color: AppColors.texto,
          splashRadius: 18,
        ),
      ],
    );
  }

  Widget _buildWeekDayHeaders() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texto,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Lunes = 1, ajustar para que la semana empiece en lunes
    final startWeekday = firstDay.weekday; // 1=Mon...7=Sun
    final leadingBlanks = startWeekday - 1;

    final totalCells = leadingBlanks + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final index = row * 7 + col;
            final dayNum = index - leadingBlanks + 1;

            if (dayNum < 1 || dayNum > lastDay.day) {
              return const Expanded(child: SizedBox(height: 36));
            }

            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNum,
            );
            final selected = _isSelected(date);
            final today = _isToday(date);
            final hasOrders = _hasOrders(date);

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDaySelected(date),
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.verdeOliva
                        : today
                        ? AppColors.lino
                        : null,
                    borderRadius: BorderRadius.circular(Sizes.radiusMd),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected || today
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : AppColors.textoFuerte,
                        ),
                      ),
                      if (hasOrders)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? Colors.white
                                  : AppColors.resaltado,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
