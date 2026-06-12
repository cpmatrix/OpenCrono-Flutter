import 'package:flutter/material.dart';

import '../../../core/inceptium/services/inceptium_http_client.dart';

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
    print(
      '[APPLIANCE TABS] Client session ricevuta: ${widget.inceptiumClient.currentWebSession}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CloudAppliancesPage(inceptiumClient: widget.inceptiumClient),
      _TabPlaceholder(label: 'Local'),
      _TabPlaceholder(label: 'Impostazioni'),
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
