import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/inceptium/models/inceptium_config.dart';
import '../../../core/inceptium/models/inceptium_credentials.dart';
import '../../appliances/pages/appliance_tabs_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _inceptiumConfig = InceptiumConfig.myshelter();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedCredentials = await _authService.loadSavedCredentials();
    if (!mounted) {
      return;
    }

    _usernameController.text = savedCredentials.username;
    _passwordController.text = savedCredentials.password;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final credentials = InceptiumCredentials(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      inceptiumId: _inceptiumConfig.inceptiumId,
    );

    bool isAuthenticated = false;
    try {
      isAuthenticated = await _authService.login(credentials);
    } on Exception catch (error) {
      debugPrint('[AUTH][ERROR] Eccezione durante il login: $error');
      isAuthenticated = false;
    }

    if (!mounted) {
      return;
    }

    if (isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      final client = _authService.inceptiumClient;
      debugPrint('[AUTH] Login riuscito');
      print(
          '[AUTH] Client session prima navigazione: ${client.currentWebSession}');
      debugPrint('[AUTH] Apertura ApplianceTabsPage');
      print('[APPLIANCES] Apertura pagina appliance');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ApplianceTabsPage(inceptiumClient: client),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage =
          'Login non riuscito. Verifica username/password oppure connessione al cloud.';
    });
    debugPrint('[AUTH][ERROR] Login fallito');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B121A), Color(0xFF162433), Color(0xFF0D1924)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 16,
                  color: const Color(0xFF131D28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFF233446),
                          child: Icon(
                            Icons.lock_clock_outlined,
                            size: 30,
                            color: Color(0xFF41B6A6),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppConfig.appName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Client for your Virtual PLC',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Inserisci username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Inserisci password',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _onLoginPressed,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF041014),
                                  ),
                                )
                              : const Text('Accedi'),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF8A80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'by MakerCaputo - 2026',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
