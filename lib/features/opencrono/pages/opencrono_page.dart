import 'package:flutter/material.dart';
import 'dart:convert';

import '../../appliances/models/my_device.dart';
import '../models/opencrono_element.dart';
import '../services/opencrono_xml_parser.dart';
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
  List<OpenCronoElement> _allElements = const [];
  int _totalElements = 0;
  int _homeElementsCount = 0;
  int _currentGroupId = 0;
  String _currentGroupTitle = 'Home';
  final List<_GroupState> _groupStack = [];

  final OpenCronoXmlParser _xmlParser = OpenCronoXmlParser();

  List<OpenCronoElement> get _visibleElements {
    return _allElements
        .where((element) => element.idGroup == _currentGroupId)
        .toList(growable: false);
  }

  Future<bool> _onWillPop() async {
    if (_currentGroupId == 0) {
      return true;
    }

    _goBackGroup();
    return false;
  }

  void _goBackPressed() {
    if (_currentGroupId == 0) {
      Navigator.of(context).pop();
      return;
    }

    _goBackGroup();
  }

  void _goBackGroup() {
    if (_groupStack.isEmpty) {
      return;
    }

    _groupStack.removeLast();
    final previous = _groupStack.isNotEmpty
        ? _groupStack.last
        : const _GroupState(0, 'Home');

    setState(() {
      _currentGroupId = previous.id;
      _currentGroupTitle = previous.title;
    });

    _logCurrentGroupState();
  }

  void _onElementTap(OpenCronoElement element) {
    print(
      '[OPENCRONO UI] Tap elemento: ${element.title} id=${element.id} type=${element.type}',
    );

    if (element.type == 11) {
      final nextTitle =
          element.title.trim().isEmpty ? 'Gruppo ${element.id}' : element.title;

      setState(() {
        _currentGroupId = element.id;
        _currentGroupTitle = nextTitle;
        _groupStack.add(_GroupState(_currentGroupId, _currentGroupTitle));
      });

      _logCurrentGroupState();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comando non ancora implementato'),
      ),
    );
  }

  void _logCurrentGroupState() {
    final shown = _visibleElements.length;
    print(
        '[OPENCRONO UI] Gruppo corrente: $_currentGroupTitle ($_currentGroupId)');
    print('[OPENCRONO UI] Elementi mostrati: $shown');
  }

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
          _totalElements = 0;
          _homeElementsCount = 0;
          _allElements = const [];
          _currentGroupId = 0;
          _currentGroupTitle = 'Home';
          _groupStack.clear();
          _isLoadingElements = false;
        });
        return;
      }

      print('[OPENCRONO] Risposta lunga: ${trimmed.length} caratteri');
      final preview300 =
          trimmed.length <= 300 ? trimmed : trimmed.substring(0, 300);
      print('[OPENCRONO] Anteprima XML: $preview300');

      final parsedElements = _xmlParser.parseElementsStatus(trimmed);
      final homeElements =
          parsedElements.where((element) => element.idGroup == 0).toList();

      print('[OPENCRONO PARSER] Elementi trovati: ${parsedElements.length}');
      print('[OPENCRONO PARSER] Home elements: ${homeElements.length}');
      for (final element in homeElements) {
        print(
          '[OPENCRONO PARSER] Elemento: id=${element.id} type=${element.type} title=${element.title} idGroup=${element.idGroup}',
        );
      }

      setState(() {
        _totalElements = parsedElements.length;
        _homeElementsCount = homeElements.length;
        _allElements = parsedElements;
        _currentGroupId = 0;
        _currentGroupTitle = 'Home';
        _groupStack
          ..clear()
          ..add(const _GroupState(0, 'Home'));
        _elementsError = null;
        _isLoadingElements = false;
      });
      _logCurrentGroupState();
    } catch (e) {
      setState(() {
        _elementsError = 'Errore caricamento elementi: $e';
        _totalElements = 0;
        _homeElementsCount = 0;
        _allElements = const [];
        _currentGroupId = 0;
        _currentGroupTitle = 'Home';
        _groupStack.clear();
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

    final visibleElements = _visibleElements;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B121A),
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBackPressed,
            icon: const Icon(Icons.arrow_back),
          ),
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
              _InfoLine(
                  label: 'softwareCode', value: widget.device.softwareCode),
              _InfoLine(
                  label: 'serialDevice', value: widget.device.serialDevice),
              _InfoLine(
                  label: 'localIP/localPort', value: '$localIp/$localPort'),
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
              const SizedBox(height: 8),
              Text('Totale elementi: $_totalElements'),
              Text('Elementi Home: $_homeElementsCount'),
              Text('Gruppo corrente: $_currentGroupTitle ($_currentGroupId)'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _goBackPressed,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(height: 8),
              if (visibleElements.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: visibleElements.length,
                    itemBuilder: (context, index) {
                      final element = visibleElements[index];
                      final active = element.status == 1;
                      final icon = switch (element.type) {
                        11 => Icons.folder_open,
                        5 => Icons.visibility_outlined,
                        6 => Icons.power_settings_new,
                        _ => Icons.widgets_outlined,
                      };
                      final statusText = switch (element.status) {
                        1 => 'ON',
                        0 => 'OFF',
                        _ => 'status=${element.status}',
                      };

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _onElementTap(element),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF1A3550)
                                : const Color(0xFF1A222D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF4BA3FF)
                                  : const Color(0xFF2E3947),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      element.title.isEmpty
                                          ? 'Elemento ${element.id}'
                                          : element.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'id: ${element.id}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'type: ${element.type}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: active
                                      ? const Color(0xFF7CF3A0)
                                      : Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'Nessun elemento nel gruppo corrente',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupState {
  const _GroupState(this.id, this.title);

  final int id;
  final String title;
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
