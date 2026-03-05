import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';

// ── Internal data model ──────────────────────────────────────────────────────

class _RS {
  final String type;
  final int qty;
  _RS(this.type, this.qty);
  String get raw => qty == 1 ? type : '$qty$type';
  StitchDefinition get _def =>
      StitchRegistry.stitches[type] ?? const StitchDefinition(0, 0);
  int get produced => _def.produced * qty;
  int get consumed => _def.consumed * qty;
}

class _RB {
  final List<_RS> sts;
  final int mult;
  _RB(this.sts, this.mult);
  String get raw {
    final inner = sts.map((s) => s.raw).join(', ');
    return '[$inner]x$mult';
  }

  int get produced => sts.fold(0, (s, e) => s + e.produced) * mult;
  int get consumed => sts.fold(0, (s, e) => s + e.consumed) * mult;
}

sealed class _RE {
  String get raw;
  int get produced;
  int get consumed;
}

class _RSE extends _RE {
  final _RS s;
  _RSE(this.s);
  @override
  String get raw => s.raw;
  @override
  int get produced => s.produced;
  @override
  int get consumed => s.consumed;
}

class _RBE extends _RE {
  final _RB b;
  _RBE(this.b);
  @override
  String get raw => b.raw;
  @override
  int get produced => b.produced;
  @override
  int get consumed => b.consumed;
}

class _RD {
  final int nr;
  final List<_RE> els;
  final String note;
  _RD(this.nr, this.els, {this.note = ''});
  int get total => _cadContextualTotal(els);
  int get consumed => els.fold(0, (s, e) => s + e.consumed);
  String toRawLine() {
    final parts = els.map((e) => e.raw).join(', ');
    return 'R$nr: $parts ($total)';
  }
}

/// Computes the produced total for a row treating 'cad' chains contextually:
/// - before any structural stitch → 0 (lifting/subida chain).
/// - after a structural stitch    → +1 each (structural space).
/// Inside blocks, all chains are structural (always +1).
int _cadContextualTotal(List<_RE> els) {
  int total = 0;
  bool seenStructural = false;
  for (final e in els) {
    if (e is _RSE && e.s.type == 'cad') {
      if (seenStructural) total += e.s.qty;
    } else {
      final p = e.produced;
      total += p;
      if (p > 0) seenStructural = true;
    }
  }
  return total;
}

// ── Stitch catalog ───────────────────────────────────────────────────────────

class _SI {
  final String code, label;
  const _SI(this.code, this.label);
}

const _kStitches = [
  _SI('AM', 'Anillo\nm\u00e1gico'),
  _SI('cad', 'Cadena'),
  _SI('pb', 'P. bajo'),
  _SI('pa', 'P. alto'),
  _SI('pma', 'P. med.\nalto'),
  _SI('dpa', 'D.P.\nalto'),
  _SI('tpa', 'T.P.\nalto'),
  _SI('aum', 'Aumento'),
  _SI('aumtri', 'Aum.\ntriple'),
  _SI('dis', 'Dismin.'),
  _SI('pbub', 'P.\nburbuja'),
  _SI('pr', 'P. recto'),
  _SI('vcad', 'V.cad.\natr\u00e1s'),
  _SI('vcadf', 'V.cad.\ndel.'),
];

// =============================================================================
//  PatternEditorPage
// =============================================================================

class PatternEditorPage extends StatefulWidget {
  const PatternEditorPage({super.key, required this.designId, this.existing});

  final String designId;
  final PatternDocument? existing;

  @override
  State<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends State<PatternEditorPage> {
  final _nameCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _hookCtrl = TextEditingController();
  PatternType _type = PatternType.circular;
  PatternDifficulty _difficulty = PatternDifficulty.beginner;
  PatternStatus _status = PatternStatus.draft;

  final List<_RD> _rows = [];
  final List<_RE> _curr = [];
  bool _inBlk = false;
  final List<_RS> _blk = [];
  String? _note;
  bool _saving = false;

  final _repo = PatternRepository();

  bool get _isEditing => widget.existing != null;
  int get _prevTotal => _rows.isEmpty ? 0 : _rows.last.total;
  int get _currTotal => _cadContextualTotal(_curr);
  int get _currConsumed => _curr.fold(0, (s, e) => s + e.consumed);

  /// Stitches the block consumes per repetition.
  int get _blkConsumedPerRep => _blk.fold(0, (s, e) => s + e.consumed);

  /// True if closing the block with [mult] repetitions would exceed available stitches.
  /// Always false for row 1 (no previous row).
  bool _blkWouldExceed(int mult) {
    if (_rows.isEmpty) return false;
    return _currConsumed + _blkConsumedPerRep * mult > _prevTotal;
  }

  /// Maximum allowed multiplier so the block doesn't exceed available stitches.
  /// Returns null when there is no limit (row 1 or block produces nothing).
  int? get _blkMaxMult {
    if (_rows.isEmpty || _blkConsumedPerRep == 0) return null;
    final remaining = _prevTotal - _currConsumed;
    if (remaining <= 0) return 0;
    return remaining ~/ _blkConsumedPerRep;
  }

  /// True when inside a block and the block's per-rep consumption already fills
  /// all remaining stitches — no more stitches can be added to the block.
  bool get _blkIsFull =>
      _rows.isNotEmpty &&
      _inBlk &&
      _blkConsumedPerRep >= (_prevTotal - _currConsumed);

  /// True if adding [qty] of [info] to the current block would make even ×1
  /// exceed the available stitches from the previous row.
  bool _blkAddWouldExceed(_SI info, int qty) {
    if (_rows.isEmpty) return false;
    final def = StitchRegistry.stitches[info.code];
    if (def == null || def.consumed == 0) return false;
    return _currConsumed + _blkConsumedPerRep + def.consumed * qty > _prevTotal;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) _loadFromDoc(p);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _materialCtrl.dispose();
    _hookCtrl.dispose();
    super.dispose();
  }

  void _loadFromDoc(PatternDocument p) {
    _nameCtrl.text = p.name;
    _type = p.type;
    _difficulty = p.difficulty;
    _materialCtrl.text = p.suggestedMaterial;
    _hookCtrl.text = p.hookSize;
    _status = p.status;
    _rows
      ..clear()
      ..addAll(_parseRawText(p.rawText));
  }

  List<_RD> _parseRawText(String raw) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final result = <_RD>[];
    String? lastNote;
    for (final line in lines) {
      if (line.startsWith('#nota:')) {
        final n = line.substring(6).trim();
        if (result.isNotEmpty) {
          final last = result.removeLast();
          result.add(_RD(last.nr, last.els, note: n));
        } else {
          lastNote = n;
        }
        continue;
      }
      if (line.startsWith('#')) continue;
      try {
        final rp = PatternParser.parseRow(line);
        final els = _cvt(rp.elements);
        result.add(_RD(rp.number, els, note: lastNote ?? ''));
        lastNote = null;
      } catch (_) {}
    }
    return result;
  }

  List<_RE> _cvt(List<dynamic> els) => els.map<_RE>((e) {
    if (e is StitchElement) return _RSE(_RS(e.type, e.quantity));
    if (e is BlockElement) {
      final sts = e.stitches.map((s) => _RS(s.type, s.quantity)).toList();
      return _RBE(_RB(sts, e.multiplier));
    }
    return _RSE(_RS('pb', 1));
  }).toList();

  // ── Actions ──────────────────────────────────────────────────────────────

  /// True when all available stitches from the previous row have been consumed
  /// and the user cannot add more to the current row.
  /// Always false on row 1 (no limit) or while building a block (limit checked at close).
  bool get _rowIsFull =>
      _rows.isNotEmpty && !_inBlk && _currConsumed >= _prevTotal;

  // Returns true if adding AM is currently allowed.
  bool get _canAddAM =>
      _rows.isEmpty && // solo en la vuelta 1
      !_inBlk && // nunca dentro de un bloque
      _curr.isEmpty; // debe ser el primer elemento de la vuelta

  void _addStitch(_SI info, int qty) {
    if (qty <= 0) return;
    // Block adding stitches once all available points are consumed.
    if (_rowIsFull) {
      _snack(
        'Ya se consumieron todos los puntos disponibles (\u00d7$_prevTotal)',
      );
      return;
    }
    // Validate block capacity when inside a block.
    if (_inBlk && _blkAddWouldExceed(info, qty)) {
      final remaining = _prevTotal - _currConsumed - _blkConsumedPerRep;
      _snack(
        'El bloque ya no puede aceptar más puntos '
        '(quedan $remaining disponibles por repetición)',
      );
      return;
    }
    if (info.code == 'AM') {
      if (_rows.isNotEmpty) {
        _snack('El anillo mágico solo se puede usar en la primera vuelta');
        return;
      }
      if (_inBlk) {
        _snack('El anillo mágico no puede estar dentro de un bloque');
        return;
      }
      if (_curr.isNotEmpty) {
        _snack('El anillo mágico debe ser el primer elemento de la vuelta');
        return;
      }
    }
    setState(
      () => _inBlk
          ? _blk.add(_RS(info.code, qty))
          : _curr.add(_RSE(_RS(info.code, qty))),
    );
  }

  void _beginBlock() => setState(() {
    _inBlk = true;
    _blk.clear();
  });
  void _cancelBlock() => setState(() {
    _inBlk = false;
    _blk.clear();
  });

  void _endBlock(int mult) {
    if (_blk.isEmpty || mult <= 1) return;
    setState(() {
      _curr.add(_RBE(_RB(_compressStitches(List.from(_blk)), mult)));
      _blk.clear();
      _inBlk = false;
    });
  }

  /// Merges adjacent same-type stitches inside a block (e.g. [pb, pma, pma] → [pb, 2pma]).
  List<_RS> _compressStitches(List<_RS> sts) {
    final result = <_RS>[];
    for (final s in sts) {
      if (result.isNotEmpty && result.last.type == s.type) {
        result[result.length - 1] = _RS(s.type, result.last.qty + s.qty);
      } else {
        result.add(s);
      }
    }
    return result;
  }

  void _undoLast() => setState(() {
    if (_inBlk) {
      if (_blk.isNotEmpty) _blk.removeLast();
    } else {
      if (_curr.isNotEmpty) _curr.removeLast();
    }
  });

  void _finalizeRow() {
    if (_curr.isEmpty) return;
    setState(() {
      _rows.add(
        _RD(
          _rows.length + 1,
          _compressElements(List.from(_curr)),
          note: _note ?? '',
        ),
      );
      _curr.clear();
      _note = null;
      _inBlk = false;
      _blk.clear();
    });
  }

  /// Merges adjacent same-type stitches so output stays compact (e.g. 3pb).
  List<_RE> _compressElements(List<_RE> els) {
    final result = <_RE>[];
    for (final e in els) {
      if (e is _RSE && result.isNotEmpty && result.last is _RSE) {
        final prev = result.last as _RSE;
        if (prev.s.type == e.s.type) {
          result[result.length - 1] = _RSE(
            _RS(prev.s.type, prev.s.qty + e.s.qty),
          );
          continue;
        }
      }
      result.add(e);
    }
    return result;
  }

  /// Returns a map of stitch code -> total count in the current row/block.
  Map<String, int> _buildCurrCounts() {
    final counts = <String, int>{};
    if (_inBlk) {
      for (final s in _blk) {
        counts[s.type] = (counts[s.type] ?? 0) + s.qty;
      }
    } else {
      for (final e in _curr) {
        if (e is _RSE) {
          counts[e.s.type] = (counts[e.s.type] ?? 0) + e.s.qty;
        }
      }
    }
    return counts;
  }

  void _deleteRow(int idx) => setState(() {
    _rows.removeAt(idx);
    for (int i = idx; i < _rows.length; i++) {
      final r = _rows[i];
      _rows[i] = _RD(i + 1, r.els, note: r.note);
    }
  });

  Future<void> _editRow(int idx) async {
    final rowNr = _rows[idx].nr;
    final nextCount = _rows.length - 1 - idx; // rows that come after this one
    final hasNext = nextCount > 0;
    // Build the affected-rows label: single → "V4", multiple → "V4–V6"
    final nextLabel = nextCount == 1
        ? 'V${rowNr + 1}'
        : 'V${rowNr + 1}–V${_rows.last.nr}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: AppColors.bronce),
            SizedBox(width: Sizes.sm),
            Text('Editar vuelta', style: TextStyle(fontFamily: 'Lora')),
          ],
        ),
        content: Text(
          hasNext
              ? 'Vas a editar la V$rowNr. '
                    'La${nextCount == 1 ? ' siguiente vuelta ($nextLabel)' : 's vueltas siguientes ($nextLabel)'} '
                    '${nextCount == 1 ? 'será eliminada' : 'serán eliminadas'} porque '
                    '${nextCount == 1 ? 'depende' : 'dependen'} del total producido '
                    'por esta vuelta.\n\n¿Deseas continuar?'
              : 'Vas a editar la V$rowNr. '
                    'La vuelta volverá a la zona de construcción.\n\n'
                    '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.verdeOliva,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      final target = _rows[idx];
      // Remove this row and all subsequent ones.
      _rows.removeRange(idx, _rows.length);
      // Load its elements back into the builder area.
      _curr
        ..clear()
        ..addAll(List<_RE>.from(target.els));
      _note = target.note.isEmpty ? null : target.note;
      _inBlk = false;
      _blk.clear();
    });
  }

  String _buildRawText() {
    final sb = StringBuffer();
    for (final row in _rows) {
      sb.writeln(row.toRawLine());
      if (row.note.isNotEmpty) sb.writeln('#nota: ${row.note}');
    }
    return sb.toString().trim();
  }

  /// Validates the currently built rows in real-time.
  /// Returns an empty list when there are no rows yet.
  List<PatternError> get _liveErrors {
    if (_rows.isEmpty) return const [];
    final tmp = PatternDocument(
      id: '',
      name: 'tmp',
      type: _type,
      rawText: _buildRawText(),
      designId: widget.existing?.designId ?? widget.designId,
      userId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return tmp.validate();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Ingresa un nombre para el patr\u00f3n');
      return;
    }
    if (_rows.isEmpty) {
      _snack('Agrega al menos una vuelta');
      return;
    }

    final rawText = _buildRawText();
    final tmp = PatternDocument(
      id: '',
      name: name,
      type: _type,
      rawText: rawText,
      designId: widget.existing?.designId ?? widget.designId,
      userId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      difficulty: _difficulty,
      suggestedMaterial: _materialCtrl.text.trim(),
      hookSize: _hookCtrl.text.trim(),
      status: _status,
    );

    final errors = tmp.validate();
    final hasMath = errors.any(
      (e) =>
          e.message.contains('no coincide') ||
          e.message.contains('disponibles'),
    );

    if (hasMath && _status == PatternStatus.finished) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.radiusLg),
          ),
          title: const Text('Errores matem\u00e1ticos'),
          content: Text(
            'El patr\u00f3n tiene ${errors.length} error(es).\n\n'
            '\u00BFGuardar como borrador?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar borrador'),
            ),
          ],
        ),
      );
      if (go != true) return;
      setState(() => _status = PatternStatus.draft);
    }

    setState(() => _saving = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final now = DateTime.now();
      final doc = PatternDocument(
        id: widget.existing?.id ?? '',
        name: name,
        type: _type,
        rawText: rawText,
        designId: widget.existing?.designId ?? widget.designId,
        userId: userId,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
        difficulty: _difficulty,
        suggestedMaterial: _materialCtrl.text.trim(),
        hookSize: _hookCtrl.text.trim(),
        status: _status,
      );
      if (_isEditing)
        await _repo.update(doc);
      else
        await _repo.create(doc);
      if (mounted) {
        _snack(_isEditing ? 'Patr\u00f3n actualizado' : 'Patr\u00f3n creado');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  Future<void> _showBlockMultDialog() async {
    // Start at the minimum valid mult, clamped to max if there's a limit.
    final maxMult = _blkMaxMult;
    int mult = (maxMult != null && maxMult < 2)
        ? (maxMult < 1 ? 1 : maxMult)
        : 2;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final consumed = _currConsumed + _blkConsumedPerRep * mult;
          final available = _prevTotal;
          final hasLimit = _rows.isNotEmpty;
          final exceeds = hasLimit && consumed > available;
          final canClose = _blk.isNotEmpty && !exceeds;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Sizes.radiusLg),
            ),
            title: const Text(
              'Multiplicador del bloque',
              style: TextStyle(fontFamily: 'Lora'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: mult > 1 ? () => set(() => mult--) : null,
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.bronce,
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '\u00d7$mult',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Sizes.fontSizeXxl,
                          fontWeight: FontWeight.bold,
                          color: exceeds
                              ? AppColors.error
                              : AppColors.verdeOliva,
                        ),
                      ),
                    ),
                    IconButton(
                      // Disable + if next mult would exceed available stitches.
                      onPressed: (maxMult == null || mult < maxMult)
                          ? () => set(() => mult++)
                          : null,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: (maxMult == null || mult < maxMult)
                            ? AppColors.verdeOliva
                            : AppColors.border,
                      ),
                    ),
                  ],
                ),
                if (hasLimit) ...[
                  const SizedBox(height: Sizes.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sizes.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: exceeds
                          ? AppColors.error.withValues(alpha: 0.08)
                          : AppColors.verdeOliva.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Sizes.radiusMd),
                      border: Border.all(
                        color: exceeds
                            ? AppColors.error.withValues(alpha: 0.35)
                            : AppColors.verdeOliva.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          exceeds
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          size: 14,
                          color: exceeds
                              ? AppColors.error
                              : AppColors.verdeOliva,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Consume $consumed / $available disponibles',
                          style: TextStyle(
                            fontSize: Sizes.fontSizeSm,
                            color: exceeds
                                ? AppColors.error
                                : AppColors.verdeOliva,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (exceeds)
                    Padding(
                      padding: const EdgeInsets.only(top: Sizes.xs),
                      child: Text(
                        'Reduce el multiplicador para no exceder los puntos disponibles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: canClose
                      ? AppColors.verdeOliva
                      : AppColors.border,
                ),
                onPressed: canClose ? () => Navigator.pop(ctx, mult) : null,
                child: const Text('Cerrar bloque'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) _endBlock(result);
  }

  Future<void> _showNoteDialog() async {
    final ctrl = TextEditingController(text: _note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text(
          'Nota para esta vuelta',
          style: TextStyle(fontFamily: 'Lora'),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ej: cambiar a color azul',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.verdeOliva,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _note = result.isEmpty ? null : result);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.verdeOliva,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar patr\u00f3n' : 'Nuevo patr\u00f3n',
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Guardar',
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Sizes.lg),
                    child: _buildInfoSection(),
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Sizes.lg),
                    child: _buildBuilderSection(),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoSection(),
                const SizedBox(height: Sizes.md),
                _buildBuilderSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _fieldDeco(String label, {String? hint, IconData? icon}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.bronce)
            : null,
        labelStyle: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.verdeOliva, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm,
        ),
        isDense: true,
      );

  Widget _buildInfoSection() => _SectionCard(
    title: '\u2728  Informaci\u00f3n del patr\u00f3n',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: _fieldDeco(
            'Nombre del patr\u00f3n *',
            icon: Icons.auto_fix_high_outlined,
          ),
        ),
        const SizedBox(height: Sizes.md),
        _Label('Tipo de patr\u00f3n'),
        const SizedBox(height: Sizes.xs),
        Wrap(
          spacing: Sizes.sm,
          runSpacing: Sizes.xs,
          children: PatternType.values
              .map(
                (t) => ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  selectedColor: t.color.withValues(alpha: 0.22),
                  onSelected: (_) => setState(() => _type = t),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: Sizes.md),
        _Label('Dificultad'),
        const SizedBox(height: Sizes.xs),
        Wrap(
          spacing: Sizes.sm,
          runSpacing: Sizes.xs,
          children: PatternDifficulty.values
              .map(
                (d) => ChoiceChip(
                  label: Text(d.label),
                  selected: _difficulty == d,
                  selectedColor: d.color.withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: Sizes.md),
        TextField(
          controller: _materialCtrl,
          decoration: _fieldDeco(
            'Material sugerido',
            hint: 'Ej: estambre delgado azul',
            icon: Icons.layers_outlined,
          ),
        ),
        const SizedBox(height: Sizes.sm),
        TextField(
          controller: _hookCtrl,
          decoration: _fieldDeco(
            'Tama\u00f1o de gancho',
            hint: 'Ej: 2.5 mm',
            icon: Icons.straighten_outlined,
          ),
        ),
        const SizedBox(height: Sizes.md),
        _Label('Estado'),
        const SizedBox(height: Sizes.xs),
        Wrap(
          spacing: Sizes.sm,
          runSpacing: Sizes.xs,
          children: PatternStatus.values
              .map(
                (s) => ChoiceChip(
                  avatar: Icon(s.icon, size: 16),
                  label: Text(s.label),
                  selected: _status == s,
                  selectedColor: s.color.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _status = s),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _buildBuilderSection() {
    final errors = _liveErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errors.isNotEmpty) _buildErrorBanner(errors),
        if (_rows.isNotEmpty) ...[
          _buildCompletedRows(errors),
          const SizedBox(height: Sizes.md),
        ],
        _buildCurrentRow(),
        const SizedBox(height: Sizes.md),
        _buildPalette(),
        const SizedBox(height: Sizes.md),
        _buildControls(),
        const SizedBox(height: Sizes.xxl),
      ],
    );
  }

  Widget _buildErrorBanner(List<PatternError> errors) => Container(
    margin: const EdgeInsets.only(bottom: Sizes.md),
    padding: const EdgeInsets.symmetric(
      horizontal: Sizes.md,
      vertical: Sizes.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(Sizes.radiusLg),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: AppColors.error,
        ),
        const SizedBox(width: Sizes.sm),
        Expanded(
          child: Text(
            errors.length == 1
                ? '1 error en el patrón'
                : '${errors.length} errores en el patrón',
            style: const TextStyle(
              fontSize: Sizes.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCompletedRows(List<PatternError> liveErrors) => _SectionCard(
    title: '\u2728  Vueltas (${_rows.length})',
    child: Column(
      children: List.generate(_rows.length, (i) {
        final row = _rows[i];
        final rowErrors = liveErrors.where((e) => e.row == row.nr).toList();
        final hasError = rowErrors.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: Sizes.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.sm,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.45)
                  : AppColors.verdeOliva.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(Sizes.radiusMd),
            color: hasError
                ? AppColors.error.withValues(alpha: 0.04)
                : AppColors.background,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowBadge(nr: row.nr, hasError: hasError),
              const SizedBox(width: Sizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.toRawLine(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: Sizes.fontSizeSm,
                        color: hasError
                            ? AppColors.textoFuerte
                            : AppColors.textoFuerte,
                      ),
                    ),
                    if (row.note.isNotEmpty)
                      Text(
                        '\uD83D\uDCDD ${row.note}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.bronce,
                        ),
                      ),
                    if (hasError) ...[
                      const SizedBox(height: 4),
                      ...rowErrors.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 13,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e.message,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.bronce,
                ),
                onPressed: () => _editRow(i),
                tooltip: 'Editar vuelta',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () => _deleteRow(i),
                tooltip: 'Eliminar vuelta',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildCurrentRow() => _SectionCard(
    title: '\u{1FAA1}  Vuelta ${_rows.length + 1}',
    titleTrailing: _curr.isEmpty
        ? null
        : _StatsRow(
            produced: _currTotal,
            consumed: _currConsumed,
            available: _prevTotal,
          ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_inBlk) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sizes.sm,
              vertical: 6,
            ),
            margin: const EdgeInsets.only(bottom: Sizes.sm),
            decoration: BoxDecoration(
              color: AppColors.bronce.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Sizes.radiusSm),
              border: Border.all(
                color: AppColors.bronce.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.data_array, size: 16, color: AppColors.bronce),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _blk.isEmpty
                        ? 'Modo bloque activo - selecciona puntos'
                        : '[ ${_blk.map((s) => s.raw).join(', ')} ] \u00d7 ...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: Sizes.fontSizeSm,
                      color: AppColors.bronce,
                    ),
                  ),
                ),
                if (_blk.isNotEmpty && _rows.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _blkWouldExceed(2)
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.verdeOliva.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Sizes.radiusSm),
                    ),
                    child: Text(
                      '${_blkConsumedPerRep}/rep · ${_prevTotal - _currConsumed} libres',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _blkWouldExceed(2)
                            ? AppColors.error
                            : AppColors.verdeOliva,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_curr.isEmpty && !_inBlk)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: AppColors.bronce.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Toca los puntos de la paleta para agregarlos',
                  style: TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: Sizes.xs,
            runSpacing: Sizes.xs,
            children: _curr.map((e) => _ElementChip(raw: e.raw)).toList(),
          ),
        // ── Row full banner ───────────────────────────────────────────────
        if (_rowIsFull)
          Container(
            margin: const EdgeInsets.only(top: Sizes.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: Sizes.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.verdeOliva.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Sizes.radiusMd),
              border: Border.all(
                color: AppColors.verdeOliva.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 15,
                  color: AppColors.verdeOliva,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Todos los puntos consumidos ($_prevTotal/$_prevTotal). Confirma la vuelta o deshaz para editar.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.verdeOliva,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_note != null) ...[
          const SizedBox(height: Sizes.xs),
          GestureDetector(
            onTap: _showNoteDialog,
            child: Text(
              '\uD83D\uDCDD Nota: $_note  (toca para editar)',
              style: const TextStyle(fontSize: 12, color: AppColors.bronce),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildPalette() {
    final counts = _buildCurrCounts();
    final full = _rowIsFull;
    return _SectionCard(
      title: _inBlk
          ? '\u{1F9F6}  Paleta \u00b7 Modo Bloque'
          : '\u{1F9F6}  Paleta de puntos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sizes.sm,
            runSpacing: Sizes.sm,
            children: [
              ..._kStitches.map(
                (s) => _StitchBtn(
                  info: s,
                  count: counts[s.code] ?? 0,
                  onTap: () => _addStitch(s, 1),
                  disabled:
                      full ||
                      (_inBlk && _blkIsFull) ||
                      (s.code == 'AM' && !_canAddAM),
                ),
              ),
              if (!_inBlk)
                _BlockStartBtn(
                  onTap: full ? null : _beginBlock,
                  disabled: full,
                ),
            ],
          ),
          if (_inBlk) ...[
            const SizedBox(height: Sizes.sm),
            const Divider(color: AppColors.lino),
            Wrap(
              spacing: Sizes.sm,
              runSpacing: Sizes.sm,
              children: [
                FilledButton.icon(
                  // Disable if block is empty OR even ×2 would exceed stitches.
                  onPressed: (_blk.isNotEmpty && !_blkWouldExceed(2))
                      ? _showBlockMultDialog
                      : (_blk.isNotEmpty &&
                            _blkMaxMult != null &&
                            _blkMaxMult! >= 1)
                      ? _showBlockMultDialog
                      : null,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(
                    _blkMaxMult == 0
                        ? 'Sin puntos libres'
                        : 'Cerrar bloque \u00d7N',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: (_blkMaxMult == 0)
                        ? AppColors.error.withValues(alpha: 0.6)
                        : AppColors.verdeOliva,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _cancelBlock,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Cancelar bloque'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() => Wrap(
    spacing: Sizes.sm,
    runSpacing: Sizes.sm,
    children: [
      OutlinedButton.icon(
        onPressed: _undoLast,
        icon: const Icon(Icons.undo, size: 16),
        label: const Text('Deshacer'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textoFuerte,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: _showNoteDialog,
        icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
        label: Text(_note == null ? 'Agregar nota' : 'Editar nota \u2022'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bronce,
          side: BorderSide(color: AppColors.bronce.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      Tooltip(
        message: _curr.isEmpty
            ? 'Agrega puntos antes de confirmar'
            : (!_rows.isEmpty && _currConsumed < _prevTotal)
            ? 'Faltan ${_prevTotal - _currConsumed} punto(s) por usar'
            : '',
        child: FilledButton.icon(
          onPressed:
              _curr.isNotEmpty &&
                  !_inBlk &&
                  (_rows.isEmpty || _currConsumed >= _prevTotal)
              ? _finalizeRow
              : null,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Confirmar vuelta'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.verdeOliva,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _Label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: Sizes.fontSizeSm,
      fontWeight: FontWeight.w600,
      color: AppColors.textoFuerte,
    ),
  );
}

// =============================================================================
//  Shared sub-widgets
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleTrailing,
  });
  final String title;
  final Widget child;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Sizes.radiusXl),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.textoFuerte.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(Sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    fontFamily: 'Lora',
                  ),
                ),
              ),
              if (titleTrailing != null) titleTrailing!,
            ],
          ),
          const Divider(color: AppColors.lino),
          child,
        ],
      ),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.produced,
    required this.consumed,
    required this.available,
  });
  final int produced, consumed, available;
  @override
  Widget build(BuildContext context) {
    final over = available > 0 && consumed > available;
    return Wrap(
      spacing: 4,
      children: [
        _Chip('\u2191$produced', AppColors.verdeOliva),
        _Chip('\u2193$consumed', over ? AppColors.error : AppColors.bronce),
        _Chip('prev:$available', AppColors.texto),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _ElementChip extends StatelessWidget {
  const _ElementChip({required this.raw});
  final String raw;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.verdeOliva.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.verdeOliva.withValues(alpha: 0.35)),
    ),
    child: Text(
      raw,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.verdeOliva,
      ),
    ),
  );
}

class _RowBadge extends StatelessWidget {
  const _RowBadge({required this.nr, this.hasError = false});
  final int nr;
  final bool hasError;
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      gradient: hasError
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.error,
                AppColors.error.withValues(alpha: 0.75),
              ],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.verdeOliva, AppColors.bronce],
            ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: hasError
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.verdeOliva.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: hasError
        ? const Icon(Icons.warning_rounded, color: Colors.white, size: 16)
        : Text(
            'R$nr',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
  );
}

class _StitchBtn extends StatelessWidget {
  const _StitchBtn({
    required this.info,
    required this.onTap,
    this.count = 0,
    this.disabled = false,
  });
  final _SI info;
  final VoidCallback onTap;
  final int count;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0 && !disabled;
    return Tooltip(
      message: disabled ? 'Solo en la primera vuelta' : '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: disabled ? 0.35 : 1.0,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(Sizes.radiusXl),
              child: InkWell(
                onTap: disabled ? null : onTap,
                borderRadius: BorderRadius.circular(Sizes.radiusXl),
                splashColor: AppColors.verdeOliva.withValues(alpha: 0.25),
                highlightColor: AppColors.verdeOliva.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.verdeOliva.withValues(alpha: 0.15)
                        : AppColors.lino.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(Sizes.radiusXl),
                    border: Border.all(
                      color: isActive ? AppColors.verdeOliva : AppColors.border,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    info.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.verdeOliva
                          : AppColors.textoFuerte,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isActive)
            Positioned(
              top: -7,
              right: -7,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.resaltado,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.resaltado.withValues(alpha: 0.45),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockStartBtn extends StatelessWidget {
  const _BlockStartBtn({required this.onTap, this.disabled = false});
  final VoidCallback? onTap;
  final bool disabled;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: disabled ? 0.35 : 1.0,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Sizes.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        splashColor: AppColors.bronce.withValues(alpha: 0.25),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.bronce.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Sizes.radiusXl),
            border: Border.all(
              color: AppColors.bronce.withValues(alpha: 0.45),
              style: BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.data_array,
                size: 22,
                color: AppColors.bronce.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 2),
              const Text(
                'Bloque\n[ ]\u00d7N',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bronce,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
