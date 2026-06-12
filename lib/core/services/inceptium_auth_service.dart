class InceptiumAuthService {
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return email.isNotEmpty && password.isNotEmpty;
  }
}
