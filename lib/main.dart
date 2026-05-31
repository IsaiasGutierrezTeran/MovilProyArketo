import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/auth.dart';
import 'core/theme.dart';
import 'core/token_store.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/billing/billing_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/collaboration/collaboration_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/projects/project_detail_screen.dart';
import 'features/shell/home_shell.dart';

void main() {
  // Required before touching platform channels (secure storage in bootstrap()).
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final api = Api(tokens);
  final auth = AuthService(api, tokens)..bootstrap();

  runApp(MultiProvider(
    providers: [
      Provider<Api>.value(value: api),
      ChangeNotifierProvider<AuthService>.value(value: auth),
    ],
    child: const ArketoApp(),
  ));
}

class ArketoApp extends StatefulWidget {
  const ArketoApp({super.key});
  @override
  State<ArketoApp> createState() => _ArketoAppState();
}

class _ArketoAppState extends State<ArketoApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _router = GoRouter(
      refreshListenable: auth,
      initialLocation: '/splash',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (!auth.ready) return loc == '/splash' ? null : '/splash';
        final onAuth = loc == '/login' || loc == '/register';
        if (!auth.isAuthed) return onAuth ? null : '/login';
        if (onAuth || loc == '/splash') return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const _Splash()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/', builder: (_, __) => const HomeShell()),
        GoRoute(
          path: '/projects/:id',
          builder: (_, s) => ProjectDetailScreen(id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/projects/:id/budget',
          builder: (_, s) => BudgetScreen(projectId: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/projects/:id/collab',
          builder: (_, s) => CollaborationScreen(projectId: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(path: '/billing', builder: (_, __) => const BillingScreen()),
        GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Arketo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary)));
  }
}
