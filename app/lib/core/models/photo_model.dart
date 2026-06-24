import '../config/app_config.dart';

class AlbumItem {
  const AlbumItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.photoCount,
    required this.createdAt,
    required this.lastIndexedAt,
    required this.isDeleted,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int photoCount;
  final String createdAt;
  final String lastIndexedAt;
  final bool isDeleted;

  factory AlbumItem.fromFirestore(String id, Map<String, dynamic> doc) {
    return AlbumItem(
      id: id,
      title: doc['title'] ?? id,
      coverUrl: doc['cover_url'] ?? '',
      photoCount: (doc['photo_count'] ?? 0) as int,
      createdAt: doc['created_at'] ?? '',
      lastIndexedAt: doc['last_indexed_at'] ?? '',
      isDeleted: doc['is_deleted'] ?? false,
    );
  }
}

class PhotoItem {
  const PhotoItem({
    required this.id,
    required this.albumId,
    required this.name,
    required this.createdAt,
    required this.downloadUrl,
    required this.viewUrl,
    required this.thumbnailUrl,
    required this.mimeType,
    required this.isDeleted,
    required this.indexedAt,
  });

  final String id;
  final String albumId;
  final String name;
  final String createdAt;
  final String downloadUrl;
  final String viewUrl;
  final String thumbnailUrl;
  final String mimeType;
  final bool isDeleted;
  final String indexedAt;

  String get publicThumbnailUrl {
    return mediaUrl(thumbnail: true);
  }

  String get publicViewerUrl {
    return mediaUrl();
  }

  String get publicOpenUrl {
    return mediaUrl(download: true);
  }

  String mediaUrl({bool download = false, bool thumbnail = false}) {
    if (albumId.isEmpty || id.isEmpty) {
      if (downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
      if (viewUrl.isNotEmpty) {
        return viewUrl;
      }
      return thumbnailUrl;
    }

    final album = Uri.encodeComponent(albumId);
    final photo = Uri.encodeComponent(id);
    final base = AppConfig.backendBaseUrl;
    final query =
        download ? '?download=true' : (thumbnail ? '?thumbnail=true' : '');
    final suffix = query;
    return '$base/api/v1/media/albums/$album/photos/$photo$suffix';
  }

  factory PhotoItem.fromFirestore(String id, Map<String, dynamic> doc) {
    return PhotoItem(
      id: id,
      albumId: doc['album_id'] ?? '',
      name: doc['name'] ?? '',
      createdAt: doc['created_at'] ?? '',
      downloadUrl: doc['download_url'] ?? '',
      viewUrl: doc['view_url'] ?? '',
      thumbnailUrl: doc['thumbnail_url'] ?? '',
      mimeType: doc['mime_type'] ?? '',
      isDeleted: doc['is_deleted'] ?? false,
      indexedAt: doc['indexed_at'] ?? '',
    );
  }
}
