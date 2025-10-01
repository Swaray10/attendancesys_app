import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

// Events
abstract class CourseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CourseLoadRequested extends CourseEvent {}

class CourseRefreshRequested extends CourseEvent {}

// States
abstract class CourseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<Course> courses;

  CourseLoaded({required this.courses});

  @override
  List<Object?> get props => [courses];
}

class CourseError extends CourseState {
  final String message;

  CourseError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final ApiService _apiService;

  CourseBloc({required ApiService apiService})
      : _apiService = apiService,
        super(CourseInitial()) {
    on<CourseLoadRequested>(_onLoadRequested);
    on<CourseRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    CourseLoadRequested event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    await _loadCourses(emit);
  }

  Future<void> _onRefreshRequested(
    CourseRefreshRequested event,
    Emitter<CourseState> emit,
  ) async {
    // Don't show loading state for refresh
    await _loadCourses(emit);
  }

  Future<void> _loadCourses(Emitter<CourseState> emit) async {
    try {
      final response = await _apiService.getCourses();

      if (response.success && response.data != null) {
        emit(CourseLoaded(courses: response.data!));
      } else {
        emit(CourseError(message: response.error ?? 'Failed to load courses'));
      }
    } catch (e) {
      emit(CourseError(message: 'Error loading courses: $e'));
    }
  }
}
