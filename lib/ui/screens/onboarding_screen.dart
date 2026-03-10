import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../services/user_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _selectedColor = '#00FFFF';
  final List<String> _selectedGenres = [];

  final List<String> _colors = [
    '#00FFFF', // Cyan
    '#FF00FF', // Magenta
    '#00FF00', // Neon Green
    '#FF3333', // Neon Red
    '#FFB800', // Gold
  ];

  final List<String> _genres = [
    'Reggaeton',
    'Trap Latino',
    'Pop',
    'Rock',
    'Electrónica',
    'Lofi & Chill',
    'Hip-Hop',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu nombre')),
      );
      return;
    }

    ref.read(userProfileProvider.notifier).completeOnboarding(
          name,
          _selectedColor,
          _selectedGenres,
        );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/sarymusic_logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Bienvenido a\nSaryMusic',
                style: GoogleFonts.orbitron(
                  color: AppTheme.textMain,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Personaliza tu experiencia musical.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Nombre
              Text(
                '¿Cómo te llamamos?',
                style: GoogleFonts.inter(
                  color: AppTheme.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tu nombre o apodo',
                  hintStyle:
                      TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Color Avatar
              Text(
                'Elige un color para tu perfil',
                style: GoogleFonts.inter(
                  color: AppTheme.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colors.map((hex) => _buildColorBubble(hex)).toList(),
              ),
              const SizedBox(height: 40),

              // Géneros
              Text(
                'Tus géneros favoritos (Opcional)',
                style: GoogleFonts.inter(
                  color: AppTheme.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genres.map((g) => _buildGenreChip(g)).toList(),
              ),
              const SizedBox(height: 60),

              // Botón Continuar
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 10,
                    shadowColor: AppTheme.primary.withOpacity(0.5),
                  ),
                  onPressed: _completeOnboarding,
                  child: Text(
                    'COMENZAR',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorBubble(String hex) {
    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    final isSelected = _selectedColor == hex;

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = hex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2)
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = _selectedGenres.contains(genre);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGenres.remove(genre);
          } else {
            _selectedGenres.add(genre);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          genre,
          style: GoogleFonts.inter(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
