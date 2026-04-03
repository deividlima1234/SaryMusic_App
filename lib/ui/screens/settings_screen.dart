import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../data/database/isar_service.dart';
import 'equalizer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppTheme.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'AJUSTES',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primary.withOpacity(0.15),
                        AppTheme.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('CUENTA'),
                _buildProfileCard(context, ref, user),

                _buildSectionHeader('EXPERIENCIA DE AUDIO'),
                _buildSettingTile(
                  icon: Icons.equalizer_rounded,
                  title: 'Ecualizador',
                  subtitle: 'Personaliza los bajos y agudos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.high_quality_rounded,
                  title: 'Calidad de Audio',
                  subtitle: 'Alta (320kbps)',
                  onTap: () {},
                ),

                _buildSectionHeader('ALMACENAMIENTO'),
                FutureBuilder<int>(
                    future: ref
                        .read(isarServiceProvider)
                        .getDownloadedTracks()
                        .then((value) => value.length),
                    builder: (context, snapshot) {
                      return _buildSettingTile(
                        icon: Icons.storage_rounded,
                        title: 'Datos Locales',
                        subtitle: '${snapshot.data ?? 0} pistas descargadas',
                        onTap: () {},
                      );
                    }),
                _buildSettingTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Limpiar caché',
                  subtitle: 'Borra archivos temporales de búsqueda',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Caché limpiada con éxito')));
                  },
                ),
                _buildSettingTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reiniciar Aplicación',
                  subtitle: 'Borra perfil y todas las descargas',
                  onTap: () => _showResetDialog(context, ref),
                  color: Colors.redAccent,
                ),

                _buildSectionHeader('ACERCA DE'),
                _buildAboutCard(),

                const SizedBox(height: 100), // Espacio para el mini player
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                Color(int.parse(user.avatarColorHex.replaceFirst('#', '0xFF'))),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Usuario Sary',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${user.preferredGenres.join(", ")}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => _showEditNameDialog(context, ref, user.name),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/images/sarymusic_logo.png', height: 40),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SaryMusic',
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '...';
                      return Text(
                        'Version V$version',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 10),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          _buildAboutRow('Creado por', 'Eddam Eloy'),
          const SizedBox(height: 12),
          _buildAboutRow('Compañía', 'EddamCore'),
          const SizedBox(height: 12),
          _buildAboutRow('Desarrollo', 'Advanced AI Systems'),
          const SizedBox(height: 24),
          Text(
            '© 2026 EddamCore. Todos los derechos reservados.',
            style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  void _showEditNameDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Editar Nombre',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppTheme.primary.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final currentProfile = ref.read(userProfileProvider);
                await ref
                    .read(userProfileProvider.notifier)
                    .saveProfile(currentProfile.copyWith(name: newName));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('¿Reiniciar aplicación?',
            style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 16)),
        content: const Text(
          'Se eliminarán todas tus listas, descargas y perfil. Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userProfileProvider.notifier).resetProfile();
              // Reiniciar la app o navegar a splash
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                // Aquí podrías forzar un reinicio total o navegar al inicio del onboarding
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REINICIAR TODO'),
          ),
        ],
      ),
    );
  }
}
