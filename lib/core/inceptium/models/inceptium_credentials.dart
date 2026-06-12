class InceptiumCredentials {
  const InceptiumCredentials({
    required this.username,
    required this.password,
    required this.inceptiumId,
  });

  final String username;
  final String password;
  final String inceptiumId;

  bool get isValid =>
      username.trim().isNotEmpty &&
      password.isNotEmpty &&
      inceptiumId.trim().isNotEmpty;
}
