enum AppStatus {
  loading,
  searchingDriver,
  waitingForRequest,
  tripActive,
  readyForRequest,
}

class AppState {
  final AppStatus status;
  final String userRole;

  const AppState({
    this.status = AppStatus.loading,
    this.userRole = 'passageiro',
  });

  AppState copyWith({AppStatus? status, String? userRole}) {
    return AppState(
      status: status ?? this.status,
      userRole: userRole ?? this.userRole,
    );
  }
}
