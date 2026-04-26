class GoogleAuthSession {
  const GoogleAuthSession({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.serverAuthCode,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? serverAuthCode;
}

class GoogleAuthTokens {
  const GoogleAuthTokens({this.accessToken, this.idToken, this.serverAuthCode});

  final String? accessToken;
  final String? idToken;
  final String? serverAuthCode;
}

class GoogleAuthState {
  const GoogleAuthState({
    required this.isLoading,
    required this.isBusy,
    required this.session,
    this.errorMessage,
  });

  factory GoogleAuthState.initial({GoogleAuthSession? session}) {
    return GoogleAuthState(
      isLoading: session == null,
      isBusy: false,
      session: session,
    );
  }

  final bool isLoading;
  final bool isBusy;
  final GoogleAuthSession? session;
  final String? errorMessage;

  bool get isSignedIn => session != null;

  GoogleAuthState copyWith({
    bool? isLoading,
    bool? isBusy,
    Object? session = _googleAuthUnset,
    Object? errorMessage = _googleAuthUnset,
  }) {
    return GoogleAuthState(
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      session: session == _googleAuthUnset
          ? this.session
          : session as GoogleAuthSession?,
      errorMessage: errorMessage == _googleAuthUnset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _googleAuthUnset = Object();
