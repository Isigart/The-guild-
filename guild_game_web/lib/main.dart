// lib/main.dart

import 'package:flutter/material.dart';
import 'data/data_loader.dart';
import 'data/remote_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/intro/titre_screen.dart';
import 'providers/game_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Charger les données locales immédiatement (toujours dispo)
  await DataLoader.chargerTout();

  // 2. Vérifier les mises à jour en arrière-plan (silencieux)
  DataLoader.verifierMisesAJour().then((result) {
    if (result.miseAJour) {
      debugPrint('✓ Contenu mis à jour: \${result.message}');
    }
  });

  runApp(
    const ProviderScope(
      child: GuildGameApp(),
    ),
  );
}

class GuildGameApp extends StatelessWidget {
  const GuildGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compagnie de Mercenaires',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0805),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC9A84C),    // or
          secondary: const Color(0xFF2D6A2D),  // vert
          error: const Color(0xFF8B1A1A),      // rouge sang
          surface: const Color(0xFF16130C),    // fond carte
        ),
        textTheme: GoogleFonts.imFellEnglishTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.uncialAntiqua(
            color: const Color(0xFFC9A84C),
            fontSize: 32,
          ),
          titleLarge: GoogleFonts.cinzel(
            color: const Color(0xFFC9A84C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.cinzel(
            color: const Color(0xFFC9A84C),
            fontSize: 14,
          ),
          titleSmall: GoogleFonts.cinzel(
            color: const Color(0xFF6B5A3A),
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        dividerColor: const Color(0xFF2A2015),
        cardColor: const Color(0xFF16130C),
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(gameProvider);
    
    // Pas de partie en cours → écran titre
    if (etat == null) {
      return const TitreScreen();
    }
    
    // Partie en cours → écran principal de la guilde
    return const GuildeRouterScreen();
  }
}

// Router pour les écrans en jeu
class GuildeRouterScreen extends ConsumerStatefulWidget {
  const GuildeRouterScreen({super.key});

  @override
  ConsumerState<GuildeRouterScreen> createState() => _GuildeRouterScreenState();
}

class _GuildeRouterScreenState extends ConsumerState<GuildeRouterScreen> {
  @override
  Widget build(BuildContext context) {
    // L'écran principal de la guilde
    // Navigation gérée via Navigator.push pour les sous-écrans
    return const Placeholder(); // TODO: GuildeScreen
  }
}


class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});
  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _charge = false;
  bool _introTerminee = false;

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    await ref.read(gameProvider.notifier).initialiser();
    if (mounted) setState(() => _charge = true);
  }

  @override
  Widget build(BuildContext context) {
    // En cours de chargement
    if (!_charge) return const LoadingScreen();

    final etat = ref.watch(gameProvider);

    // Partie existante → jeu directement
    if (etat != null || _introTerminee) {
      return const MainScreen();
    }

    // Aucune partie → intro
    return IntroScreen(
      onTermine: () => setState(() => _introTerminee = true),
    );
  }
}
