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
import 'screens/auth/login_screen.dart';
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
            seedColor: const Color(0xFF5C6BC0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
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
          return const MainShell();
        }
        return const LoginScreen();
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
