import 'package:go_router/go_router.dart';
import '../../features/chatbot/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/telemedicine/presentation/telemedicine_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final initialMessage = state.uri.queryParameters['message'];
        return ChatScreen(initialMessage: initialMessage);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/telemedicine',
      builder: (context, state) => const TelemedicineScreen(),
    ),
  ],
);
