import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _heroAspectRatio = 2752 / 758;

  static final Uri _prayerGroupUri = Uri.parse(
    'https://chat.whatsapp.com/FF6kf7a09DnEvwWFdgxRMa?utm_source=ig&utm_medium=social&utm_content=link_in_bio&fbclid=PAZXh0bgNhZW0CMTEAc3J0YwZhcHBfaWQMMjU2MjgxMDQwNTU4AAGnHW1I67WW69iXgvducD3V59XCA_1SatWVpa-XfdCP48WAaMqoR8IDkHWIr9k_aem_b6mFwZuHZKzhWxg1xr9C1g',
  );
  static final Uri _instagramUri = Uri.parse(AppConfig.instagramUrl);

  Future<void> _openPrayerGroup(BuildContext context) async {
    if (!await launchUrl(_prayerGroupUri, mode: LaunchMode.platformDefault)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o grupo de oração agora.'),
        ),
      );
    }
  }

  Future<void> _openInstagram(BuildContext context) async {
    if (!await launchUrl(_instagramUri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o Instagram agora.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth >= 900;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/about'),
            tooltip: 'Sobre & Privacidade',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isMobile ? 16 : 24,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
                      child: ColoredBox(
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: _heroAspectRatio,
                          child: Image.asset(
                            'assets/images/neviim.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/home_hero.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 14),
                  Wrap(
                    spacing: isMobile ? 16 : 24,
                    runSpacing: isMobile ? 16 : 24,
                    children: [
                      SizedBox(
                        width: isWide ? 520 : double.infinity,
                        child: Card(
                          color: colorScheme.surfaceContainerHighest,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: colorScheme.primary.withOpacity(0.08),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Veja os registros dos encontros, salve as fotos no celular e compartilhe os melhores momentos da comunidade.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.75),
                                    height: 1.45,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 10 : 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.go('/gallery'),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Ver Galeria de Fotos'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.08),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 18 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lugar de novas experiências!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _InfoRow(
                            icon: Icons.schedule,
                            text: 'Quarta, às 20h.',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.alternate_email,
                            text: '@saojoseoperariocl',
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openInstagram(context),
                            child: _InfoRow(
                              icon: Icons.camera_alt_outlined,
                              text: AppConfig.instagramLabel,
                              emphasize: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: 'Rua Miguel Gonçalves Correia, 305.',
                          ),
                          SizedBox(height: isMobile ? 18 : 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _openPrayerGroup(context),
                              icon: const Icon(Icons.forum_outlined),
                              label: const Text('Entrar no grupo de oração'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.35,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
              color: emphasize ? theme.colorScheme.primary : null,
              decoration: emphasize ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}
