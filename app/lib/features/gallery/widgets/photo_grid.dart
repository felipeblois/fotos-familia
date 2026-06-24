import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/photo_model.dart';

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.album,
    required this.photos,
  });

  final AlbumItem album;
  final List<PhotoItem> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Nenhuma foto adicionada para este álbum.'),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final photo = photos[index];
            final screenWidth = MediaQuery.sizeOf(context).width;
            final pixelRatio = MediaQuery.devicePixelRatioOf(context);
            final cellWidth = (screenWidth - 48) / 3;
            final imageCacheSize =
                (cellWidth * pixelRatio).clamp(320, 900).round();
            final imageUrl = photo.publicThumbnailUrl.isNotEmpty
                ? photo.publicThumbnailUrl
                : (photo.thumbnailUrl.isNotEmpty
                    ? photo.thumbnailUrl
                    : (photo.downloadUrl.isNotEmpty
                        ? photo.downloadUrl
                        : photo.viewUrl));
            final Widget tile = imageUrl.isEmpty
                ? Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheKey: 'thumb_${photo.id}',
                    fit: BoxFit.cover,
                    memCacheWidth: imageCacheSize,
                    memCacheHeight: imageCacheSize,
                    maxWidthDiskCache: imageCacheSize,
                    maxHeightDiskCache: imageCacheSize,
                    fadeInDuration: const Duration(milliseconds: 120),
                    fadeOutDuration: const Duration(milliseconds: 80),
                    placeholder: (context, url) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.error_outline),
                    ),
                  );

            return GestureDetector(
              key: ValueKey(photo.id),
              onTap: () => context.push('/photo/${photo.id}', extra: photo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: tile,
                ),
              ),
            );
          },
          childCount: photos.length,
        ),
      ),
    );
  }
}
