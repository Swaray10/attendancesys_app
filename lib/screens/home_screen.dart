import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/course/course_bloc.dart';
import '../blocs/session/session_bloc.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/course_card.dart';
import '../widgets/network_status_banner.dart';
import 'session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load courses on init
    context.read<CourseBloc>().add(CourseLoadRequested());
    context.read<SessionBloc>().add(SessionLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CourseBloc>().add(CourseRefreshRequested());
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  return Column(
                    children: [
                      // User greeting
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.md),
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              authState.user.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Active session banner
                      BlocBuilder<SessionBloc, SessionState>(
                        builder: (context, sessionState) {
                          if (sessionState is SessionsLoaded &&
                              sessionState.activeSession != null) {
                            return _buildActiveSessionBanner(
                                context, sessionState.activeSession!);
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Courses list
                      Expanded(
                        child: BlocBuilder<CourseBloc, CourseState>(
                          builder: (context, courseState) {
                            if (courseState is CourseLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (courseState is CourseLoaded) {
                              if (courseState.courses.isEmpty) {
                                return _buildEmptyState();
                              }
                              return _buildCoursesList(courseState.courses);
                            } else if (courseState is CourseError) {
                              return _buildErrorState(courseState.message);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionBanner(
      BuildContext context, AttendanceSession session) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.md),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.successColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  session.course?.name ?? 'Unknown Course',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionScreen(session: session),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.successColor,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<Course> courses) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CourseBloc>().add(CourseRefreshRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.md),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CourseCard(
            course: courses[index],
            onTap: () => _navigateToSession(courses[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            'No courses assigned',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            'Contact admin to get courses assigned',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            'Error loading courses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.lg),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CourseBloc>().add(CourseLoadRequested());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToSession(Course course) {
    // Show dialog to start new session
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Attendance Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${course.name}'),
            const SizedBox(height: 8),
            Text('Code: ${course.code}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SessionBloc>().add(
                    SessionCreateRequested(
                      courseId: course.id,
                      sessionType: 'lecture',
                      autoCloseDuration: 120, // 2 hours
                    ),
                  );
            },
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
