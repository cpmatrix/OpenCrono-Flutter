import 'package:flutter/material.dart';

import '../../../core/inceptium/services/inceptium_http_client.dart';
import '../../../core/utils/app_log.dart';
import '../../auth/pages/login_page.dart';
import 'cloud_appliances_page.dart';

class ApplianceTabsPage extends StatefulWidget {
  const ApplianceTabsPage({
    super.key,
    required this.inceptiumClient,
  });

  final InceptiumHttpClient inceptiumClient;

  @override
  State<ApplianceTabsPage> createState() => _ApplianceTabsPageState();
}

class _ApplianceTabsPageState extends State<ApplianceTabsPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AppLog.d(
        '[APPLIANCE TABS] Client session ricevuta: ${widget.inceptiumClient.currentWebSession}');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CloudAppliancesPage(inceptiumClient: widget.inceptiumClient),
      _TabPlaceholder(label: 'Local'),
      _SettingsTab(inceptiumClient: widget.inceptiumClient),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenCrono'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            activeIcon: Icon(Icons.cloud),
            label: 'Cloud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lan_outlined),
            activeIcon: Icon(Icons.lan),
            label: 'Local',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.inceptiumClient});

  final InceptiumHttpClient inceptiumClient;

  Future<void> _logout(BuildContext context) async {
    AppLog.d('[AUTH] Logout richiesto');
    inceptiumClient.currentWebSession = null;
    AppLog.d('[AUTH] Ritorno alla LoginPage');
    if (!context.mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
