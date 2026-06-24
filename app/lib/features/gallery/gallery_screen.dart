import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/config/app_config.dart';
import '../../core/models/photo_model.dart';
import '../../core/providers/gallery_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/photo_grid.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icons/image.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConfig.appName,
              style: AppTheme.brandStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Home'),
            style: TextButton.styleFrom(
              foregroundColor: theme.appBarTheme.foregroundColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: albumsAsync.when(
        data: (albums) {
          if (albums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sem fotos ainda',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            key: const PageStorageKey('gallery-scroll'),
            cacheExtent: 1400,
            slivers: albums.map((album) {
              return SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _AlbumHeaderDelegate(album: album),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final photosState = ref.watch(
                        albumPhotosProvider(album.id),
                      );

                      if (photosState.isInitialLoading &&
                          photosState.photos.isEmpty) {
                        return const SliverToBoxAdapter(child: _ShimmerGrid());
                      }

                      if (photosState.error != null &&
                          photosState.photos.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Erro ao carregar fotos: ${photosState.error}',
                            ),
                          ),
                        );
                      }

                      final photos = photosState.photos;
                      final remainingPhotos = album.photoCount > photos.length
                          ? album.photoCount - photos.length
                          : 0;
                      final canLoadMore =
                          photosState.hasMore && remainingPhotos > 0;

                      return SliverMainAxisGroup(
                        slivers: [
                          PhotoGrid(album: album, photos: photos),
                          if (photosState.error != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  'Não foi possível carregar mais fotos agora.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          if (canLoadMore)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: photosState.isLoadingMore
                                      ? null
                                      : () {
                                          ref
                                              .read(
                                                albumPhotosProvider(album.id)
                                                    .notifier,
                                              )
                                              .loadMore();
                                        },
                                  icon: photosState.isLoadingMore
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.expand_more),
                                  label: Text(
                                    photosState.isLoadingMore
                                        ? 'Carregando fotos...'
                                        : _loadMoreLabel(remainingPhotos),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const _ShimmerList(),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}

String _loadMoreLabel(int remainingPhotos) {
  final nextBatch = remainingPhotos < AppConfig.galleryPageSize
      ? remainingPhotos
      : AppConfig.galleryPageSize;
  final suffix = nextBatch == 1 ? 'foto' : 'fotos';
  final remainingSuffix = remainingPhotos == 1 ? 'restante' : 'restantes';

  return 'Carregar mais $nextBatch $suffix '
      '($remainingPhotos $remainingSuffix)';
}

class _AlbumHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AlbumHeaderDelegate({required this.album});

  final AlbumItem album;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  '${album.photoCount} foto(s)',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AlbumHeaderDelegate oldDelegate) {
    return album.id != oldDelegate.album.id ||
        album.photoCount != oldDelegate.album.photoCount;
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: _ShimmerGrid(),
        );
      },
    );
  }
}
