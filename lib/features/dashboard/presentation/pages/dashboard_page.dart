import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/agenda/presentation/pages/agenda_page.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/dashboard_footer.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/sidebar_menu.dart';
import 'package:andicrochett/features/designs/presentation/pages/designs_page.dart';
import 'package:andicrochett/features/inventory/presentation/pages/inventory_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedRoute = 'home';

  void _onMenuItemSelected(String route) {
    setState(() {
      _selectedRoute = route;
    });
  }

  /// Construye el widget de contenido según la ruta activa del sidebar.
  ///
  /// Notas de cada ruta:
  ///   'home'      → Resumen estádtico; TODO: conectar a datos reales.
  ///   'inventory' → Pantalla de inventario (UI estática, pendiente Firestore).
  ///   'agenda'    → Pantalla de agenda / pedidos (pendiente implementación).
  ///   'designs'   → Pantalla de diseños con Firestore activo.
  ///   'profile'   → Herramienta de desarrollo: siembra datos en Firestore.
  ///               PENDIENTE reemplazar con ProfilePage en producción.
  Widget _buildContent() {
    return switch (_selectedRoute) {
      'home' => const _HomeView(),
      'inventory' => const InventoryPage(),
      'agenda' => const AgendaPage(),
      'designs' => const DesignsPage(),
      // DESARROLLO: Ruta 'perfil' usa la herramienta de siembra de datos.
      // TODO: Crear ProfilePage y reemplazar _FirebaseTestView aquí.
      'profile' => const _FirebaseTestView(),
      _ => const _HomeView(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            // Layout de escritorio con grid
            return Row(
              children: [
                // div1: Menú lateral animado
                SidebarMenu(
                  selectedRoute: _selectedRoute,
                  onRouteSelected: _onMenuItemSelected,
                ),
                // div2 y div3: Contenido principal + footer (4 columnas de 5)
                Expanded(
                  child: Column(
                    children: [
                      // div2: Área de contenido (4 filas de 5)
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: AppColors.background,
                          child: _buildContent(),
                        ),
                      ),
                      // div3: Footer (1 fila de 5)
                      const SizedBox(height: 60, child: DashboardFooter()),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Layout móvil con Drawer
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: Colors.white,
                title: const Text('AndiCrochett'),
              ),
              drawer: Drawer(
                child: SidebarMenu(
                  selectedRoute: _selectedRoute,
                  onRouteSelected: (route) {
                    _onMenuItemSelected(route);
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Column(
                children: [
                  Expanded(child: _buildContent()),
                  const SizedBox(height: 60, child: DashboardFooter()),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// Vista de inicio temporal
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel Principal',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
              fontFamily: 'Lora',
            ),
          ),
          const SizedBox(height: Sizes.lg),
          Wrap(
            spacing: Sizes.md,
            runSpacing: Sizes.md,
            children: [
              _DashboardCard(
                title: 'Inventario',
                value: '124',
                subtitle: 'productos',
                color: AppColors.bronce,
                icon: Icons.inventory_2,
              ),
              _DashboardCard(
                title: 'Pedidos',
                value: '8',
                subtitle: 'pendientes',
                color: AppColors.verdeOliva,
                icon: Icons.receipt_long,
              ),
              _DashboardCard(
                title: 'Patrones',
                value: '32',
                subtitle: 'creados',
                color: AppColors.resaltado,
                icon: Icons.grid_on,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(Sizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Sizes.radiusMd),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: Sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    fontFamily: 'Lora',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Firebase Seed Data View ─────────────────────────────────────────────────

class _FirebaseTestView extends StatefulWidget {
  const _FirebaseTestView();

  @override
  State<_FirebaseTestView> createState() => _FirebaseTestViewState();
}

class _FirebaseTestViewState extends State<_FirebaseTestView>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Track status per collection
  final Map<String, _SeedStatus> _status = {
    'users': _SeedStatus.idle,
    'products': _SeedStatus.idle,
    'orders': _SeedStatus.idle,
    'patterns': _SeedStatus.idle,
    'catalog_settings': _SeedStatus.idle,
  };
  String _errorMessage = '';

  static const _collectionMeta = <String, (IconData, String)>{
    'users': (Icons.person_rounded, 'Usuarios'),
    'products': (Icons.inventory_2_rounded, 'Inventario'),
    'orders': (Icons.receipt_long_rounded, 'Pedidos / Agenda'),
    'patterns': (Icons.grid_on_rounded, 'Patrones Crochet'),
    'catalog_settings': (Icons.storefront_rounded, 'Catálogo Público'),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Seed all collections ──────────────────────────────────────────────────

  Future<void> _seedAll() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
      for (final k in _status.keys) {
        _status[k] = _SeedStatus.idle;
      }
    });

    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'demo_user_001';
    final now = FieldValue.serverTimestamp();

    try {
      // 1 ── users ──
      _setStatus('users', _SeedStatus.loading);
      await db.collection('users').doc(uid).set({
        'email': user?.email ?? 'andi@crochett.com',
        'displayName': user?.displayName ?? 'Andi Crochett',
        'photoUrl': user?.photoURL ?? '',
        'authProvider': user != null ? 'google' : 'demo',
        'createdAt': now,
        'updatedAt': now,
        'settings': {'theme': 'light', 'language': 'es', 'notifications': true},
      });
      _setStatus('users', _SeedStatus.done);

      // 2 ── products ──
      _setStatus('products', _SeedStatus.loading);

      final product1 = await db.collection('products').add({
        'userId': uid,
        'name': 'Lana Merino Rosa',
        'imageUrl': '',
        'category': 'Lana',
        'color': '#F48FB1',
        'weight': '100g',
        'currentStock': 15,
        'totalStock': 20,
        'status': 'available',
        'isPublic': true,
        'createdAt': now,
        'updatedAt': now,
      });

      final product2 = await db.collection('products').add({
        'userId': uid,
        'name': 'Hilo de Algodón Azul',
        'imageUrl': '',
        'category': 'Hilo',
        'color': '#64B5F6',
        'weight': '50g',
        'currentStock': 8,
        'totalStock': 12,
        'status': 'available',
        'isPublic': true,
        'createdAt': now,
        'updatedAt': now,
      });

      final product3 = await db.collection('products').add({
        'userId': uid,
        'name': 'Aguja Crochet 4mm',
        'imageUrl': '',
        'category': 'Herramientas',
        'color': '#BDBDBD',
        'weight': '15g',
        'currentStock': 3,
        'totalStock': 5,
        'status': 'low_stock',
        'isPublic': false,
        'createdAt': now,
        'updatedAt': now,
      });
      _setStatus('products', _SeedStatus.done);

      // 3 ── orders ──
      _setStatus('orders', _SeedStatus.loading);
      await db.collection('orders').add({
        'userId': uid,
        'customerName': 'María López',
        'customerContact': '+52 555 123 4567',
        'items': [
          {
            'productId': product1.id,
            'productName': 'Lana Merino Rosa',
            'quantity': 2,
            'unitPrice': 120,
          },
          {
            'productId': product3.id,
            'productName': 'Aguja Crochet 4mm',
            'quantity': 1,
            'unitPrice': 85,
          },
        ],
        'totalPrice': 325,
        'status': 'pending',
        'dueDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'notes': 'Entregar envuelto para regalo',
        'createdAt': now,
        'updatedAt': now,
      });

      await db.collection('orders').add({
        'userId': uid,
        'customerName': 'Carlos García',
        'customerContact': 'carlos@email.com',
        'items': [
          {
            'productId': product2.id,
            'productName': 'Hilo de Algodón Azul',
            'quantity': 4,
            'unitPrice': 95,
          },
        ],
        'totalPrice': 380,
        'status': 'in_progress',
        'dueDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'notes': 'Pedido para baby shower',
        'createdAt': now,
        'updatedAt': now,
      });
      _setStatus('orders', _SeedStatus.done);

      // 4 ── patterns ──
      _setStatus('patterns', _SeedStatus.loading);
      await db.collection('patterns').add({
        'userId': uid,
        'name': 'Corazón Amigurumi',
        'thumbnailUrl': '',
        'gridData': {
          'rows': 10,
          'columns': 10,
          'cells': [
            {'row': 2, 'col': 3, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 2, 'col': 4, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 2, 'col': 6, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 2, 'col': 7, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 3, 'col': 2, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 3, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 4, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 5, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 6, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 7, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 3, 'col': 8, 'color': '#E91E63', 'stitch': 'dc'},
            {'row': 4, 'col': 3, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 4, 'col': 4, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 4, 'col': 5, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 4, 'col': 6, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 4, 'col': 7, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 5, 'col': 4, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 5, 'col': 5, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 5, 'col': 6, 'color': '#E91E63', 'stitch': 'sc'},
            {'row': 6, 'col': 5, 'color': '#E91E63', 'stitch': 'sc'},
          ],
        },
        'materials': [
          {'name': 'Lana Merino Rosa', 'quantity': '50g'},
          {'name': 'Aguja 4mm', 'quantity': '1'},
          {'name': 'Relleno', 'quantity': '30g'},
        ],
        'isPublic': true,
        'createdAt': now,
        'updatedAt': now,
      });
      _setStatus('patterns', _SeedStatus.done);

      // 5 ── catalog_settings ──
      _setStatus('catalog_settings', _SeedStatus.loading);
      await db.collection('catalog_settings').doc(uid).set({
        'isPublicCatalogEnabled': true,
        'businessName': 'AndiCrochett',
        'contactInfo': {
          'email': user?.email ?? 'andi@crochett.com',
          'phone': '+52 555 987 6543',
          'instagram': '@andicrochett',
        },
        'featuredProducts': [product1.id, product2.id],
        'featuredPatterns': [],
        'updatedAt': now,
      });
      _setStatus('catalog_settings', _SeedStatus.done);
    } catch (e) {
      // Mark current loading one as error
      for (final k in _status.keys) {
        if (_status[k] == _SeedStatus.loading) {
          _status[k] = _SeedStatus.error;
        }
      }
      setState(() {
        _errorMessage = e.toString();
      });
    }

    setState(() => _loading = false);
  }

  void _setStatus(String key, _SeedStatus s) {
    if (mounted) setState(() => _status[key] = s);
  }

  bool get _allDone => _status.values.every((s) => s == _SeedStatus.done);
  bool get _hasError => _status.values.any((s) => s == _SeedStatus.error);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated icon ──
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _allDone
                        ? [AppColors.success, AppColors.verdeOliva]
                        : _hasError
                        ? [AppColors.error, AppColors.resaltado]
                        : [AppColors.bronce, AppColors.verdeOliva],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_allDone
                                  ? AppColors.success
                                  : _hasError
                                  ? AppColors.error
                                  : AppColors.bronce)
                              .withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _allDone
                      ? Icons.rocket_launch_rounded
                      : _hasError
                      ? Icons.cloud_off_rounded
                      : Icons.storage_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Title ──
            Text(
              _allDone ? '¡Datos sembrados!' : 'Sembrar datos de prueba',
              style: TextStyle(
                fontSize: Sizes.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _allDone
                  ? 'Todas las colecciones se crearon correctamente\nen Firestore. ¡Revisa la consola de Firebase!'
                  : 'Crea las 5 colecciones en Firestore con datos\nde ejemplo para probar toda la app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Sizes.fontSizeMd,
                color: AppColors.texto,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // ── Collection status cards ──
            SizedBox(
              width: 380,
              child: Column(
                children: _collectionMeta.entries.map((entry) {
                  final status = _status[entry.key]!;
                  final (icon, label) = entry.value;
                  return _CollectionStatusTile(
                    icon: icon,
                    label: label,
                    collectionName: entry.key,
                    status: status,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Seed button ──
            SizedBox(
              width: 280,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _seedAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allDone
                      ? AppColors.success
                      : AppColors.verdeOliva,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.verdeOliva.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.verdeOliva.withValues(alpha: 0.4),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _allDone
                                ? Icons.refresh_rounded
                                : Icons.bolt_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _allDone
                                ? 'Sembrar de nuevo'
                                : 'Sembrar datos en Firebase',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Error message ──
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: 380,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Schema overview ──
            Container(
              width: 380,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lino.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        size: 18,
                        color: AppColors.textoFuerte,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estructura Firestore',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.fontSizeMd,
                          color: AppColors.textoFuerte,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '  User (uid)\n'
                    '  ├── products      3 docs\n'
                    '  ├── orders        2 docs\n'
                    '  ├── patterns      1 doc\n'
                    '  └── catalog       1 doc',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.texto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status enum ──────────────────────────────────────────────────────────────

enum _SeedStatus { idle, loading, done, error }

// ── Collection status tile ───────────────────────────────────────────────────

class _CollectionStatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String collectionName;
  final _SeedStatus status;

  const _CollectionStatusTile({
    required this.icon,
    required this.label,
    required this.collectionName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: switch (status) {
            _SeedStatus.done => AppColors.success.withValues(alpha: 0.08),
            _SeedStatus.error => AppColors.error.withValues(alpha: 0.08),
            _SeedStatus.loading => AppColors.bronce.withValues(alpha: 0.08),
            _ => Colors.white.withValues(alpha: 0.6),
          },
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: switch (status) {
              _SeedStatus.done => AppColors.success.withValues(alpha: 0.4),
              _SeedStatus.error => AppColors.error.withValues(alpha: 0.4),
              _SeedStatus.loading => AppColors.bronce.withValues(alpha: 0.4),
              _ => AppColors.border,
            },
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textoFuerte),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textoFuerte,
                    ),
                  ),
                  Text(
                    collectionName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.texto.withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (status) {
                _SeedStatus.idle => Icon(
                  Icons.circle_outlined,
                  size: 20,
                  color: AppColors.border,
                  key: const ValueKey('idle'),
                ),
                _SeedStatus.loading => const SizedBox(
                  width: 20,
                  height: 20,
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.bronce,
                  ),
                ),
                _SeedStatus.done => const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.success,
                  key: ValueKey('done'),
                ),
                _SeedStatus.error => const Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: AppColors.error,
                  key: ValueKey('error'),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
