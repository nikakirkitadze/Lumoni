import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/core/di/injection.dart';

// ──────────────────────── State ──────────────────────────────────────────────

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentPage = 0,
    this.isCompleted = false,
  });

  final int currentPage;
  final bool isCompleted;

  static const int totalPages = 3;

  bool get isFirstPage => currentPage == 0;
  bool get isLastPage => currentPage == totalPages - 1;
  double get progress => (currentPage + 1) / totalPages;

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [currentPage, isCompleted];
}

// ──────────────────────── Cubit ─────────────────────────────────────────────

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  final LocalStorageService _storage = getIt<LocalStorageService>();

  /// Advances to the next onboarding page.
  ///
  /// Does nothing if already on the last page.
  void nextPage() {
    if (state.isLastPage) return;
    emit(state.copyWith(currentPage: state.currentPage + 1));
  }

  /// Returns to the previous onboarding page.
  ///
  /// Does nothing if already on the first page.
  void previousPage() {
    if (state.isFirstPage) return;
    emit(state.copyWith(currentPage: state.currentPage - 1));
  }

  /// Jumps directly to a specific page index.
  void goToPage(int page) {
    if (page < 0 || page >= OnboardingState.totalPages) return;
    emit(state.copyWith(currentPage: page));
  }

  /// Marks onboarding as completed and persists the flag in local storage.
  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    emit(state.copyWith(isCompleted: true));
  }

  /// Checks whether onboarding was previously completed.
  Future<bool> wasOnboardingCompleted() async {
    return _storage.getOnboardingCompleted();
  }
}
