import 'package:flutter/material.dart';
import 'dart:convert';

import '../../appliances/models/my_device.dart';
import '../../../core/inceptium/services/inceptium_http_client.dart';

class OpenCronoPage extends StatefulWidget {
  const OpenCronoPage({
    super.key,
    required this.device,
    required this.client,
    required this.serverVersion,
  });

  final MyDevice device;
  final InceptiumHttpClient client;
  final String serverVersion;

  @override
  State<OpenCronoPage> createState() => _OpenCronoPageState();
}

class _OpenCronoPageState extends State<OpenCronoPage> {
  static const _myDeviceClass =
      'com.incappmyshelteradmin.data.mydevice.MyDevice';
  static const _executeCommandToRemoteClientMethod =
      '_executeCommandToRemoteClient';

  bool _isLoadingElements = false;
  String? _elementsError;
  String? _elementsPreview;

  Future<void> _loadElementsStatus() async {
    if (_isLoadingElements) {
      return;
    }

    setState(() {
      _isLoadingElements = true;
      _elementsError = null;
    });

    try {
      print('[OPENCRONO] Caricamento elementi');

      const openCronoCommand = 'command=get?elements_status';
      final commandB64 = 'cmd:${base64Encode(utf8.encode(openCronoCommand))}';
      print('[OPENCRONO] commandB64: $commandB64');

      final params =
          'serialdevice=${widget.device.serialDevice}::softwarecode=${widget.device.softwareCode}::command_64=$commandB64';

      final response = await widget.client.executeMethod(
        _myDeviceClass,
        _executeCommandToRemoteClientMethod,
        params,
      );

      final trimmed = response.trim();
      if (trimmed.isEmpty || trimmed == 'ERROR') {
        setState(() {
          _elementsError = 'Risposta vuota o ERROR';
          _elementsPreview = null;
          _isLoadingElements = false;
        });
        return;
      }

      print('[OPENCRONO] Risposta lunga: ${trimmed.length} caratteri');
      final preview300 =
          trimmed.length <= 300 ? trimmed : trimmed.substring(0, 300);
      print('[OPENCRONO] Anteprima XML: $preview300');

      final preview1000 =
          trimmed.length <= 1000 ? trimmed : trimmed.substring(0, 1000);

      setState(() {
        _elementsPreview = preview1000;
        _elementsError = null;
        _isLoadingElements = false;
      });
    } catch (e) {
      setState(() {
        _elementsError = 'Errore caricamento elementi: $e';
        _elementsPreview = null;
        _isLoadingElements = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localPort =
        widget.device.localPort.trim().isEmpty ? '-' : widget.device.localPort;
    final localIp =
        widget.device.localIp.trim().isEmpty ? '-' : widget.device.localIp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenCrono'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.deviceName.isEmpty
                  ? 'Device senza nome'
                  : widget.device.deviceName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'softwareCode', value: widget.device.softwareCode),
            _InfoLine(label: 'serialDevice', value: widget.device.serialDevice),
            _InfoLine(label: 'localIP/localPort', value: '$localIp/$localPort'),
            _InfoLine(
              label: 'online/offline',
              value: widget.device.online ? 'online' : 'offline',
            ),
            _InfoLine(label: 'serverVersion', value: widget.serverVersion),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _isLoadingElements ? null : _loadElementsStatus,
              child: _isLoadingElements
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Carica elementi'),
            ),
            const SizedBox(height: 12),
            if (_elementsError != null)
              Text(
                _elementsError!,
                style: const TextStyle(color: Color(0xFFFF8A80)),
              ),
            if (_elementsPreview != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1720),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C3A48)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _elementsPreview!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}
