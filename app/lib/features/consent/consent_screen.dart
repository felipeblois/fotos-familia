import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/consent_provider.dart';

class ConsentScreen extends ConsumerWidget {
  const ConsentScreen({super.key});

  static const _heroAspectRatio = 2740 / 761;

  void _handleDecline(BuildContext context) {
    if (context.mounted) {
      context.go('/access-limited');
      return;
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    if (AppConfig.bypassConsent) {
      if (context.mounted) {
        context.go('/home');
      }
      return;
    }

    final accepted = await ref.read(consentProvider.notifier).agreeToTerms();
    if (accepted && context.mounted) {
      context.go('/home');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel registrar o aceite agora. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.bypassConsent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
    }

    final theme = Theme.of(context);
    final isLoading = ref.watch(consentProvider).isLoading;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
                    child: ColoredBox(
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: _heroAspectRatio,
                        child: Image.asset(
                          'assets/images/bemvindo.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/consent_hero.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 18,
                      vertical: isMobile ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consentimento de uso',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Antes de entrar, confirme o uso comunitario das galerias.',
                          style: (isMobile
                                  ? theme.textTheme.titleMedium
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.04,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Esse aceite ajuda a proteger a comunidade e manter as fotos disponiveis com respeito e responsabilidade.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 18 : 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ConsentTopic(
                          icon: Icons.storage_outlined,
                          title: 'Coleta minima de dados',
                          body:
                              'Guardamos apenas o aceite do termo e os dados tecnicos necessarios para operar o app.',
                        ),
                        SizedBox(height: 16),
                        _ConsentTopic(
                          icon: Icons.people_outline,
                          title: 'Uso comunitario',
                          body:
                              'As fotos sao publicadas para consulta pelos fieis e podem ser removidas mediante solicitacao.',
                        ),
                        SizedBox(height: 16),
                        _ConsentTopic(
                          icon: Icons.security_outlined,
                          title: 'Uso etico',
                          body:
                              'O conteudo nao deve ser reutilizado para fins ilicitos, difamatorios ou comerciais sem autorizacao.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ao continuar, voce confirma que leu e concorda com o uso pastoral e comunitario das galerias.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => _handleAccept(context, ref),
                          child: const Text('Concordo'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _handleDecline(context),
                          child: const Text('Nao aceito'),
                        ),
                      ],
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

class _ConsentTopic extends StatelessWidget {
  const _ConsentTopic({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
