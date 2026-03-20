import 'package:go_router/go_router.dart';
import '../../features/chatbot/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
