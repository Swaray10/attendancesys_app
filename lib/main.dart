import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'services/nfc_service.dart';
import 'services/storage_service.dart';
import 'services/connectivity_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/course/course_bloc.dart';
import 'blocs/session/session_bloc.dart';
import 'blocs/nfc/nfc_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService().initialize();
  await ConnectivityService().initialize();

  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService()),
        RepositoryProvider(create: (_) => NfcService()),
        RepositoryProvider(create: (_) => StorageService()),
        RepositoryProvider(create: (_) => ConnectivityService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => CourseBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider(
            create: (context) => SessionBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider(
            create: (context) => NfcBloc(
              nfcService: context.read<NfcService>(),
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
              connectivityService: context.read<ConnectivityService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Smart Attendance',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial) {
                return const SplashScreen();
              } else if (state is AuthAuthenticated) {
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}
