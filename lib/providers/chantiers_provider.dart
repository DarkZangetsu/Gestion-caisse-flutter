import 'package:gestion_caisse_flutter/providers/users_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chantier.dart';
import '../services/database_helper.dart';

final chantiersStateProvider = StateNotifierProvider<ChantiersNotifier, AsyncValue<List<Chantier>>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return ChantiersNotifier(ref, ref.read(databaseHelperProvider), userId ?? '');
});

final chantiersProvider = FutureProvider.family<List<Chantier>, String>((ref, userId) {
  return ref.read(chantiersStateProvider.notifier).getChantiers(userId);
});

class ChantiersNotifier extends StateNotifier<AsyncValue<List<Chantier>>> {
  final Ref _ref;
  final DatabaseHelper _db;
  final String _userId;

  ChantiersNotifier(this._ref, this._db, this._userId) : super(const AsyncValue.loading()) {
    loadChantiers(_userId);
  }

  Future<List<Chantier>> getChantiers(String userId) async {
    try {
      final chantiers = await _db.getChantiers(userId);
      state = AsyncValue.data(chantiers);
      return chantiers;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw Exception("Erreur lors du chargement du chantier: $e");
    }
  }

  Future<void> loadChantiers(String userId) async {
    state = const AsyncValue.loading();
    try {
      final chantiers = await _db.getChantiers(userId);
      state = AsyncValue.data(chantiers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createChantier(Chantier chantier) async {
    try {
      await _db.createChantier(chantier);
      await loadChantiers(_userId);
      // Force refresh of other providers
      _ref.invalidate(chantiersProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateChantier(Chantier chantier) async {
    try {
      await _db.updateChantier(chantier);
      await loadChantiers(_userId);
      // Force refresh of other providers
      _ref.invalidate(chantiersProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteChantier(String chantierId) async {
    try {
      await _db.deleteChantier(chantierId);
      await loadChantiers(_userId);
      // Force refresh of other providers
      _ref.invalidate(chantiersProvider);
      _ref.invalidate(currentUserProvider);
      // Add other providers that might need refreshing
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}