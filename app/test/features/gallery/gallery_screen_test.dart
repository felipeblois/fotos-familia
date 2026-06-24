import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neviim/core/models/photo_model.dart';
import 'package:neviim/core/providers/gallery_provider.dart';
import 'package:neviim/features/gallery/gallery_screen.dart';

class _FakeAlbumPhotosNotifier extends AlbumPhotosNotifier {
  _FakeAlbumPhotosNotifier(List<PhotoItem> photos)
      : super(firestore: null, albumId: 'test') {
    state = AlbumPhotosState(
      photos: photos,
      isInitialLoading: false,
      hasMore: true,
    );
  }

  @override
  Future<void> loadMore() async {}
}

void main() {
  testWidgets('Galeria vazia renderiza mensagem principal', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          albumsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: GalleryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sem fotos ainda'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('Galeria preenchida mostra album e acao de carregar mais', (
    tester,
  ) async {
    const album = AlbumItem(
      id: '28-01-2026',
      title: '28-01-2026',
      coverUrl: '',
      photoCount: 100,
      createdAt: '2026-01-28T10:00:00Z',
      lastIndexedAt: '2026-01-28T10:00:00Z',
      isDeleted: false,
    );

    final photos = List<PhotoItem>.generate(
      10,
      (index) => PhotoItem(
        id: 'photo-$index',
        albumId: album.id,
        name: 'IMG_$index.JPG',
        createdAt: '2026-01-28T10:00:00Z',
        downloadUrl: '',
        viewUrl: '',
        thumbnailUrl: '',
        mimeType: 'image/jpeg',
        isDeleted: false,
        indexedAt: '2026-01-28T10:00:00Z',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          albumsProvider.overrideWith((ref) => Stream.value(const [album])),
          albumPhotosProvider(album.id).overrideWith(
            (ref) => _FakeAlbumPhotosNotifier(photos),
          ),
        ],
        child: const MaterialApp(
          home: GalleryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('28-01-2026'), findsOneWidget);
    expect(find.text('100 foto(s)'), findsOneWidget);
    expect(find.text('Carregar mais 20 fotos (90 restantes)'), findsOneWidget);
  });
}
