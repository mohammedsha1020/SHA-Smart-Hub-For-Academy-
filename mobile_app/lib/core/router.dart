import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/finance/presentation/pages/finance_dashboard_page.dart';
import '../features/finance/presentation/pages/fee_details_page.dart';
import '../features/finance/presentation/pages/payment_page.dart';
import '../features/students/presentation/pages/student_list_page.dart';
import '../features/students/presentation/pages/student_profile_page.dart';
import '../features/attendance/presentation/pages/attendance_page.dart';
import '../features/announcements/presentation/pages/announcements_page.dart';
import '../features/timetable/presentation/pages/timetable_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash and Auth routes
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    
    // Main app routes
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
      routes: [
        // Finance routes
        GoRoute(
          path: 'finance',
          builder: (context, state) => const FinanceDashboardPage(),
          routes: [
            GoRoute(
              path: 'fee/:feeId',
              builder: (context, state) => FeeDetailsPage(
                feeId: state.pathParameters['feeId']!,
              ),
            ),
            GoRoute(
              path: 'payment/:feeId',
              builder: (context, state) => PaymentPage(
                feeId: state.pathParameters['feeId']!,
              ),
            ),
          ],
        ),
        
        // Students routes
        GoRoute(
          path: 'students',
          builder: (context, state) => const StudentListPage(),
          routes: [
            GoRoute(
              path: ':studentId',
              builder: (context, state) => StudentProfilePage(
                studentId: state.pathParameters['studentId']!,
              ),
            ),
          ],
        ),
        
        // Attendance routes
        GoRoute(
          path: 'attendance',
          builder: (context, state) => const AttendancePage(),
        ),
        
        // Announcements routes
        GoRoute(
          path: 'announcements',
          builder: (context, state) => const AnnouncementsPage(),
        ),
        
        // Timetable routes
        GoRoute(
          path: 'timetable',
          builder: (context, state) => const TimetablePage(),
        ),
        
        // Notifications routes
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        
        // Profile routes
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
