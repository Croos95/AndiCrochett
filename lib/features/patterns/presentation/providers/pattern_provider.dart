import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternProvider
//  ChangeNotifier that drives the patterns UI.
// ─────────────────────────────────────────────────────────────────────────────

/// Estado de carga del provider (distinto de [PatternStatus] del modelo).
enum PatternLoadStatus { initial, loading, success, failure }

class PatternProvider extends ChangeNotifier {
  PatternProvider({PatternRepository? repository})
    : _repository = repository ?? PatternRepository();

  final PatternRepository _repository;
  StreamSubscription<List<PatternDocument>>? _subscription;

  // ── State ─────────────────────────────────────────────────────────────────

  PatternLoadStatus _status = PatternLoadStatus.initial;
  PatternLoadStatus get status => _status;

  List<PatternDocument> _patterns = [];
  List<PatternDocument> get patterns => _filteredPatterns;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  PatternType? _selectedType;
  PatternType? get selectedType => _selectedType;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Derived ───────────────────────────────────────────────────────────────

  List<PatternDocument> get _filteredPatterns {
    return _patterns.where((p) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || p.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  // ── Streaming ─────────────────────────────────────────────────────────────

  void listenToPatterns() {
    // Cancel any previous subscription before opening a new one.
    _subscription?.cancel();
    _setStatus(PatternLoadStatus.loading);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _errorMessage = 'Usuario no autenticado';
      _setStatus(PatternLoadStatus.failure);
      return;
    }

    _subscription = _repository
        .watchByUser(userId)
        .listen(
          (data) {
            _patterns = data;
            _setStatus(PatternLoadStatus.success);
          },
          onError: (Object e) {
            _errorMessage = e.toString();
            _setStatus(PatternLoadStatus.failure);
          },
        );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<String?> createPattern(PatternDocument pattern) async {
    try {
      _setStatus(PatternLoadStatus.loading);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final id = await _repository.create(pattern.copyWith(userId: userId));
      _setStatus(PatternLoadStatus.success);
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(PatternLoadStatus.failure);
      return null;
    }
  }

  Future<bool> updatePattern(PatternDocument pattern) async {
    try {
      _setStatus(PatternLoadStatus.loading);
      await _repository.update(pattern);
      _setStatus(PatternLoadStatus.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(PatternLoadStatus.failure);
      return false;
    }
  }

  Future<bool> deletePattern(String id) async {
    try {
      await _repository.delete(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setType(PatternType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _setStatus(PatternLoadStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
