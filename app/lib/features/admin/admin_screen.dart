import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/admin_api_service.dart';

final adminApiProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  String? _selectedAlbumId;
  List<Map<String, dynamic>> _albums = const [];
  List<Map<String, dynamic>> _photos = const [];
  List<Map<String, dynamic>> _auditLogs = const [];

  bool get _isAdmin => FirebaseAuth.instance.currentUser != null;

  Future<void> _openInstagram() async {
    final uri = Uri.parse(AppConfig.instagramUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o Instagram agora.'),
        ),
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _loadDashboard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao autenticar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final albums = await ref.read(adminApiProvider).fetchAlbums();
      final selectedAlbumId = albums.isNotEmpty
          ? (_selectedAlbumId != null &&
                  albums.any((album) => album['id'] == _selectedAlbumId)
              ? _selectedAlbumId
              : albums.first['id'] as String)
          : null;

      final auditLogs = await ref.read(adminApiProvider).fetchAuditLogs();
      final photos = selectedAlbumId == null
          ? const <Map<String, dynamic>>[]
          : await ref.read(adminApiProvider).fetchAlbumPhotos(selectedAlbumId);

      setState(() {
        _albums = albums;
        _selectedAlbumId = selectedAlbumId;
        _auditLogs = auditLogs;
        _photos = photos;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar painel admin: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPhotos(String albumId) async {
    setState(() => _isLoading = true);
    try {
      final photos = await ref.read(adminApiProvider).fetchAlbumPhotos(albumId);
      setState(() {
        _selectedAlbumId = albumId;
        _photos = photos;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar fotos: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete(String albumId, String photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover foto'),
        content: const Text(
          'A foto sera ocultada do app, mantendo auditoria da operacao.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminApiProvider).deletePhoto(albumId, photoId);
      await _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto ocultada com sucesso.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao remover foto: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    setState(() {
      _albums = const [];
      _photos = const [];
      _auditLogs = const [];
      _selectedAlbumId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Scaffold(
        appBar: AppBar(title: const Text('Administração')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/image.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppConfig.appName,
                          textAlign: TextAlign.center,
                          style: AppTheme.brandStyle(
                            color: colorScheme.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConfig.parishName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Acesso administrativo restrito. Use uma conta Google autorizada no backend.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.72),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: _openInstagram,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text(AppConfig.instagramLabel),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _handleSignIn,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Entrar com Google'),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel ${AppConfig.appName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1100;
                if (isCompact) {
                  return ListView(
                    children: [
                      SizedBox(
                        height: 280,
                        child: _AlbumList(
                          albums: _albums,
                          selectedAlbumId: _selectedAlbumId,
                          onSelect: _loadPhotos,
                        ),
                      ),
                      const Divider(height: 1),
                      SizedBox(
                        height: 360,
                        child: _PhotoList(
                          albumId: _selectedAlbumId,
                          photos: _photos,
                          onDelete: _handleDelete,
                        ),
                      ),
                      const Divider(height: 1),
                      SizedBox(
                        height: 320,
                        child: _AuditLogList(logs: _auditLogs),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _AlbumList(
                        albums: _albums,
                        selectedAlbumId: _selectedAlbumId,
                        onSelect: _loadPhotos,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: _PhotoList(
                        albumId: _selectedAlbumId,
                        photos: _photos,
                        onDelete: _handleDelete,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: _AuditLogList(logs: _auditLogs),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

class _AlbumList extends StatelessWidget {
  const _AlbumList({
    required this.albums,
    required this.selectedAlbumId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> albums;
  final String? selectedAlbumId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
      title: 'Albuns',
      child: albums.isEmpty
          ? const Center(child: Text('Nenhum album disponivel.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: albums.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final album = albums[index];
                final albumId = album['id'] as String;
                return ListTile(
                  selected: albumId == selectedAlbumId,
                  title: Text(album['title']?.toString() ?? albumId),
                  subtitle: Text('${album['photo_count'] ?? 0} foto(s)'),
                  onTap: () => onSelect(albumId),
                );
              },
            ),
    );
  }
}

class _PhotoList extends StatelessWidget {
  const _PhotoList({
    required this.albumId,
    required this.photos,
    required this.onDelete,
  });

  final String? albumId;
  final List<Map<String, dynamic>> photos;
  final Future<void> Function(String albumId, String photoId) onDelete;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
      title: albumId == null ? 'Fotos' : 'Fotos do album $albumId',
      child: albumId == null
          ? const Center(child: Text('Selecione um album.'))
          : photos.isEmpty
              ? const Center(
                  child: Text('Nenhuma foto disponivel neste album.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final photoId = photo['id']?.toString() ?? '';
                    final title = photo['name']?.toString().isNotEmpty == true
                        ? photo['name'].toString()
                        : photoId;
                    return ListTile(
                      title: Text(title),
                      subtitle: Text(photo['created_at']?.toString() ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () => onDelete(albumId!, photoId),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AuditLogList extends StatelessWidget {
  const _AuditLogList({required this.logs});

  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
      title: 'Auditoria recente',
      child: logs.isEmpty
          ? const Center(child: Text('Nenhuma acao auditada ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final log = logs[index];
                final action = log['action']?.toString() ?? 'acao.desconhecida';
                final photoId = log['photo_id']?.toString() ?? '-';
                final albumId = log['album_id']?.toString() ?? '-';
                final adminUid = log['admin_uid']?.toString() ?? '-';
                final createdAt = log['created_at']?.toString() ??
                    log['timestamp']?.toString() ??
                    '';

                return ListTile(
                  dense: true,
                  title: Text(action),
                  subtitle: Text(
                    'album: $albumId\nfoto: $photoId\nadmin: $adminUid\n$createdAt',
                  ),
                );
              },
            ),
    );
  }
}
