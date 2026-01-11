import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signIn(email, password));
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signUp(email, password));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signInWithGoogle());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }

  Future<void> updateProfile({String? displayName}) async {
    if (displayName == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.updateDisplayName(displayName));
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.sendPasswordResetEmail(email));
  }
}
