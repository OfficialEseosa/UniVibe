import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/fcm_service.dart';
import 'services/study_match_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/message_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/club_repository.dart';
import 'repositories/study_match_repository.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/discover/study_match_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UniVibeApp());
}

class UniVibeApp extends StatelessWidget {
  const UniVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final storageService = StorageService();
    final fcmService = FcmService();
    final authService = AuthService();
    final studyMatchService = StudyMatchService();

    return MultiProvider(
      providers: [
        Provider(create: (_) => firestoreService),
        Provider(create: (_) => storageService),
        Provider(create: (_) => fcmService),
        Provider(
          create: (_) => AuthRepository(
            authService: authService,
            fcmService: fcmService,
          ),
        ),
        Provider(
          create: (_) => PostRepository(
            firestore: firestoreService,
            storage: storageService,
          ),
        ),
        Provider(
          create: (_) => MessageRepository(firestore: firestoreService),
        ),
        Provider(
          create: (_) => EventRepository(
            firestore: firestoreService,
            storage: storageService,
          ),
        ),
        Provider(
          create: (_) => ClubRepository(
            firestore: firestoreService,
            storage: storageService,
          ),
        ),
        Provider(
          create: (_) => StudyMatchRepository(
            firestore: firestoreService,
            matchService: studyMatchService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'UniVibe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFF0F2F5), // Facebook-style light gray bg
            onSurface: const Color(0xFF1C1E21),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(),
            color: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 2,
            highlightElevation: 4,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            shadowColor: Colors.black26,
            elevation: 8,
            indicatorColor: const Color(0xFF1A73E8).withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1A73E8)
                    : Colors.black54,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? const Color(0xFF1A73E8) : Colors.black54,
                size: 24,
              );
            }),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // Once Firebase Auth is ready, check whether this user has finished
          // onboarding. New accounts created before the onboarding flow existed
          // are treated as already-onboarded so we don't bug them on every login.
          return _OnboardingGate(uid: snapshot.data!.uid);
        }
        return const LoginScreen();
      },
    );
  }
}

/// Decides whether a freshly-authenticated user should see the onboarding
/// wizard or jump straight into the main app shell. Streams the user doc so
/// the gate flips automatically when the user finishes onboarding.
class _OnboardingGate extends StatelessWidget {
  final String uid;
  const _OnboardingGate({required this.uid});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<UserModel>(
      stream: firestore.userStream(uid),
      builder: (context, snap) {
        // Stream errored — most likely the user document was deleted while the
        // Auth session was still alive (e.g. a partial account-deletion). Sign
        // out so _AuthGate rebuilds to LoginScreen and the user gets a clean slate.
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseAuth.instance.signOut();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!;
        // Treat anyone with a non-empty profile (bio/courses/photo) as already
        // onboarded — this covers users created before the onboarding flag.
        final legacyComplete = user.bio.isNotEmpty ||
            user.courses.isNotEmpty ||
            user.profilePhotoUrl.isNotEmpty;
        if (user.onboardingComplete || legacyComplete) {
          return const MainShell();
        }
        return const OnboardingScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    FeedScreen(),
    StudyMatchScreen(),
    MessagesScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
