import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/photo_model.dart';

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }
  return FirebaseFirestore.instance;
});

final albumsProvider = StreamProvider<List<AlbumItem>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    return Stream.value(const []);
  }

  return firestore.collection('albums').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => AlbumItem.fromFirestore(doc.id, doc.data()))
            .where((album) => !album.isDeleted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
});

class AlbumPhotosState {
  const AlbumPhotosState({
    this.photos = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.stackTrace,
  });

  final List<PhotoItem> photos;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final StackTrace? stackTrace;

  AlbumPhotosState copyWith({
    List<PhotoItem>? photos,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    StackTrace? stackTrace,
    bool clearError = false,
  }) {
    return AlbumPhotosState(
      photos: photos ?? this.photos,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
    );
  }
}

class AlbumPhotosNotifier extends StateNotifier<AlbumPhotosState> {
  AlbumPhotosNotifier({
    required FirebaseFirestore? firestore,
    required this.albumId,
  })  : _firestore = firestore,
        super(const AlbumPhotosState()) {
    unawaited(loadInitial());
  }

  final FirebaseFirestore? _firestore;
  final String albumId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _requestInProgress = false;

  CollectionReference<Map<String, dynamic>>? get _photosCollection {
    final firestore = _firestore;
    if (firestore == null) {
      return null;
    }

    return firestore.collection('albums').doc(albumId).collection('photos');
  }

  Query<Map<String, dynamic>>? _baseQuery() {
    final collection = _photosCollection;
    if (collection == null) {
      return null;
    }

    return collection
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .limit(AppConfig.galleryPageSize);
  }

  Future<void> loadInitial() async {
    if (_firestore == null) {
      state = const AlbumPhotosState(
        isInitialLoading: false,
        hasMore: false,
      );
      return;
    }

    _lastDocument = null;
    state = const AlbumPhotosState(isInitialLoading: true);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isInitialLoading || state.isLoadingMore) {
      return;
    }
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final baseQuery = _baseQuery();
    if (baseQuery == null || _requestInProgress) {
      return;
    }

    _requestInProgress = true;
    state = state.copyWith(
      isInitialLoading: reset && state.photos.isEmpty,
      isLoadingMore: !reset,
      clearError: true,
    );

    try {
      final query = !reset && _lastDocument != null
          ? baseQuery.startAfterDocument(_lastDocument!)
          : baseQuery;
      final snapshot = await query.get();
      final loadedPhotos = snapshot.docs
          .map((doc) => PhotoItem.fromFirestore(doc.id, doc.data()))
          .where((item) => item.id.isNotEmpty)
          .where((item) => !item.isDeleted)
          .toList();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      state = AlbumPhotosState(
        photos: reset ? loadedPhotos : [...state.photos, ...loadedPhotos],
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: snapshot.docs.length == AppConfig.galleryPageSize,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _requestInProgress = false;
    }
  }
}

final albumPhotosProvider =
    StateNotifierProvider.family<AlbumPhotosNotifier, AlbumPhotosState, String>(
  (ref, albumId) {
    return AlbumPhotosNotifier(
      firestore: ref.watch(firestoreProvider),
      albumId: albumId,
    );
  },
);
