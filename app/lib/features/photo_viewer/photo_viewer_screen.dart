import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/photo_model.dart';
import '../../core/theme/app_theme.dart';

class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photoId,
    this.photo,
  });

  final String photoId;
  final PhotoItem? photo;

  Future<void> _downloadImage(BuildContext context) async {
    final urlString = photo?.publicOpenUrl ?? '';
    if (urlString.isEmpty) {
      return;
    }

    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel iniciar o download.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = photo == null
        ? ''
        : (photo!.publicViewerUrl.isNotEmpty
            ? photo!.publicViewerUrl
            : (photo!.publicThumbnailUrl.isNotEmpty
                ? photo!.publicThumbnailUrl
                : (photo!.thumbnailUrl.isNotEmpty
                    ? photo!.thumbnailUrl
                    : (photo!.downloadUrl.isNotEmpty
                        ? photo!.downloadUrl
                        : photo!.viewUrl))));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(photo?.name ?? 'Foto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Baixar original',
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: photo == null
            ? const Text(
                'Dados nao encontrados',
                style: TextStyle(color: Colors.white),
              )
            : InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: 'photo_$photoId',
                  child: CachedNetworkImage(
                    imageUrl: imageUrl.isNotEmpty
                        ? imageUrl
                        : 'https://via.placeholder.com/1000',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                      color: AppTheme.goldLight,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
