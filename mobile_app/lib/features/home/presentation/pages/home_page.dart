import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navigationItems = [
    {
      'icon': Icons.dashboard,
      'label': 'Dashboard',
      'route': '/home',
    },
    {
      'icon': Icons.attach_money,
      'label': 'Finance',
      'route': '/home/finance',
    },
    {
      'icon': Icons.people,
      'label': 'Students',
      'route': '/home/students',
    },
    {
      'icon': Icons.event_available,
      'label': 'Attendance',
      'route': '/home/attendance',
    },
    {
      'icon': Icons.person,
      'label': 'Profile',
      'route': '/home/profile',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('School Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/home/notifications'),
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.firstName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8.w),
                    Text('Profile'),
                  ],
                ),
                onTap: () => context.push('/home/profile'),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8.w),
                    Text('Logout'),
                  ],
                ),
                onTap: () => _logout(),
              ),
            ],
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildDashboard(user) : Container(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index != 0) {
            context.push(_navigationItems[index]['route']);
          }
        },
        items: _navigationItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: item['label'],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboard(user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeCard(user),
          
          SizedBox(height: 20.h),
          
          // Quick actions based on role
          _buildQuickActions(user),
          
          SizedBox(height: 20.h),
          
          // Recent activity or stats
          _buildRecentActivity(user),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(user) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    user.role.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(user) {
    List<Map<String, dynamic>> actions = [];
    
    switch (user.role) {
      case 'admin':
        actions = [
          {'title': 'Finance Overview', 'icon': Icons.attach_money, 'route': '/home/finance'},
          {'title': 'Student Management', 'icon': Icons.people, 'route': '/home/students'},
          {'title': 'Attendance Reports', 'icon': Icons.assessment, 'route': '/home/attendance'},
          {'title': 'Announcements', 'icon': Icons.campaign, 'route': '/home/announcements'},
        ];
        break;
      case 'finance':
        actions = [
          {'title': 'Fee Management', 'icon': Icons.attach_money, 'route': '/home/finance'},
          {'title': 'Payment Reports', 'icon': Icons.assessment, 'route': '/home/finance'},
          {'title': 'Student Fees', 'icon': Icons.people, 'route': '/home/students'},
          {'title': 'Overdue Payments', 'icon': Icons.warning, 'route': '/home/finance'},
        ];
        break;
      case 'staff':
        actions = [
          {'title': 'My Classes', 'icon': Icons.class_, 'route': '/home/students'},
          {'title': 'Mark Attendance', 'icon': Icons.event_available, 'route': '/home/attendance'},
          {'title': 'Student Fees', 'icon': Icons.attach_money, 'route': '/home/finance'},
          {'title': 'Timetable', 'icon': Icons.schedule, 'route': '/home/timetable'},
        ];
        break;
      case 'parent':
        actions = [
          {'title': 'Fee Status', 'icon': Icons.attach_money, 'route': '/home/finance'},
          {'title': 'Attendance', 'icon': Icons.event_available, 'route': '/home/attendance'},
          {'title': 'Announcements', 'icon': Icons.campaign, 'route': '/home/announcements'},
          {'title': 'Timetable', 'icon': Icons.schedule, 'route': '/home/timetable'},
        ];
        break;
      default:
        actions = [
          {'title': 'My Fees', 'icon': Icons.attach_money, 'route': '/home/finance'},
          {'title': 'My Attendance', 'icon': Icons.event_available, 'route': '/home/attendance'},
          {'title': 'Announcements', 'icon': Icons.campaign, 'route': '/home/announcements'},
          {'title': 'Timetable', 'icon': Icons.schedule, 'route': '/home/timetable'},
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              child: InkWell(
                onTap: () => context.push(action['route']),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action['icon'],
                        size: 32.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        action['title'],
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 12.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildActivityItem(
                  icon: Icons.attach_money,
                  title: 'Fee Payment Received',
                  subtitle: 'Payment of ₹5,000 received from John Doe',
                  time: '2 hours ago',
                ),
                Divider(),
                _buildActivityItem(
                  icon: Icons.campaign,
                  title: 'New Announcement',
                  subtitle: 'Annual Sports Day scheduled for next month',
                  time: '5 hours ago',
                ),
                Divider(),
                _buildActivityItem(
                  icon: Icons.event_available,
                  title: 'Attendance Marked',
                  subtitle: 'Today\'s attendance has been recorded',
                  time: '1 day ago',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }
}
