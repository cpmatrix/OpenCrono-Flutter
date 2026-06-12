import 'package:flutter/material.dart';

import '../../../core/inceptium/services/inceptium_http_client.dart';
import '../../opencrono/pages/opencrono_page.dart';
import '../models/my_device.dart';
import '../services/appliance_service.dart';

class CloudAppliancesPage extends StatefulWidget {
  const CloudAppliancesPage({
    super.key,
    required this.inceptiumClient,
  });

  final InceptiumHttpClient inceptiumClient;

  @override
  State<CloudAppliancesPage> createState() => _CloudAppliancesPageState();
}

class _CloudAppliancesPageState extends State<CloudAppliancesPage> {
  late final ApplianceService _applianceService;

  bool _isLoading = true;
  String? _error;
  List<MyDevice> _devices = const [];
  final Map<String, String> _realVersionsByDevice = {};
  final Set<String> _versionLoadingKeys = {};

  @override
  void initState() {
    super.initState();
    _applianceService = ApplianceService(client: widget.inceptiumClient);
    print(
      '[APPLIANCES PAGE] Client session ricevuta: ${widget.inceptiumClient.currentWebSession}',
    );
    print('[APPLIANCES PAGE] initState');
    _loadAppliances();
  }

  Future<void> _loadAppliances() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final devices = await _applianceService.loadAppliances();
      if (!mounted) {
        return;
      }

      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Errore nel caricamento appliance: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyVersion(MyDevice device) async {
    final key = _deviceKey(device);
    if (_versionLoadingKeys.contains(key)) {
      return;
    }

    setState(() {
      _versionLoadingKeys.add(key);
    });

    final version = await _applianceService.loadApplianceVersion(device);

    if (!mounted) {
      return;
    }

    setState(() {
      _realVersionsByDevice[key] = version;
      _versionLoadingKeys.remove(key);
    });
  }

  Future<void> _openOpenCronoPage(MyDevice device) async {
    final key = _deviceKey(device);

    setState(() {
      _versionLoadingKeys.add(key);
    });

    print('[OPENCRONO] Device selezionato: ${device.deviceName}');
    final serverVersion = await _applianceService.loadApplianceVersion(device);
    print('[OPENCRONO] Versione server: $serverVersion');

    if (!mounted) {
      return;
    }

    setState(() {
      _realVersionsByDevice[key] = serverVersion;
      _versionLoadingKeys.remove(key);
    });

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OpenCronoPage(
          device: device,
          client: widget.inceptiumClient,
          serverVersion: serverVersion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('[APPLIANCES PAGE] build');
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFFF8A80), size: 36),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAppliances,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadAppliances,
        child: _devices.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(
                    child: Text('Nessuna appliance cloud disponibile'),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final deviceKey = _deviceKey(device);
                  final isCheckingVersion =
                      _versionLoadingKeys.contains(deviceKey);
                  final realVersion = _realVersionsByDevice[deviceKey] ?? '-';
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isCheckingVersion
                        ? null
                        : () => _openOpenCronoPage(device),
                    child: Card(
                      elevation: 4,
                      color: const Color(0xFF131D28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device.deviceName.isEmpty
                                        ? 'Device senza nome'
                                        : device.deviceName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                _StatusChip(online: device.online),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _InfoLine(
                              label: 'Codice',
                              value: _fallback(device.deviceCode),
                            ),
                            _InfoLine(
                              label: 'IP locale',
                              value: _fallback(device.localIp),
                            ),
                            _InfoLine(
                              label: 'Versione server',
                              value: _fallback(device.serverVersion),
                            ),
                            _InfoLine(
                              label: 'Versione lista',
                              value: _fallback(device.deviceVersionDescription),
                            ),
                            _InfoLine(
                              label: 'Versione server reale',
                              value: isCheckingVersion
                                  ? 'Verifica...'
                                  : realVersion,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton(
                                onPressed: isCheckingVersion
                                    ? null
                                    : () => _verifyVersion(device),
                                child: const Text('Verifica versione'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    } catch (e, stack) {
      print('[APPLIANCES BUILD ERROR] $e');
      print(stack);
      return const SizedBox.shrink();
    }
  }

  String _deviceKey(MyDevice device) {
    return '${device.serialDevice}|${device.softwareCode}|${device.deviceName}';
  }

  String _fallback(String value) => value.isEmpty ? '-' : value;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: online ? const Color(0xFF1A4F3F) : const Color(0xFF5C2B2B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'Online' : 'Offline',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
