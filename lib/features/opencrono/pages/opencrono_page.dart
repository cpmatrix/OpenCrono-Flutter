import 'package:flutter/material.dart';
import 'dart:convert';

import '../../appliances/models/my_device.dart';
import '../services/opencrono_xml_parser.dart';
import '../../../opencrono/factory/opencrono_element_factory.dart';
import '../../../opencrono/models/elements/opencrono_element.dart';
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
  int _currentGroupId = 0;
  String _currentGroupTitle = 'Home';
  final List<_GroupState> _groupStack = [];

  final OpenCronoXmlParser _xmlParser = OpenCronoXmlParser();

  @override
  void initState() {
    super.initState();
    print('[OPENCRONO] Auto caricamento elementi');
    _loadElementsStatus();
  }

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
    final elementType = element.type ?? -1;
    final elementId = int.tryParse(element.id ?? '') ?? 0;
    final elementTitle = element.title ?? '';

    print(
      '[OPENCRONO UI] Tap elemento: $elementTitle id=$elementId type=$elementType',
    );

    if (elementType == 11) {
      final nextTitle =
          elementTitle.trim().isEmpty ? 'Gruppo $elementId' : elementTitle;

      setState(() {
        _currentGroupId = elementId;
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

      final parsedElementsData = _xmlParser.parseElementsStatus(trimmed);
      final parsedElements = <OpenCronoElement>[];

      for (final elementData in parsedElementsData) {
        try {
          final createdElement = OpenCronoElementFactory.create(
            type: elementData.type,
            id: elementData.id.toString(),
            status: elementData.status,
            currentValue: elementData.currentValue,
            title: elementData.title,
            labelValue: elementData.labelValue,
            idGroup: elementData.idGroup,
            currentTextValue: elementData.currentTextValue,
            userProperty: elementData.userPropertyRaw,
          );

          print(
            '[FACTORY] type=${elementData.type} -> ${createdElement.runtimeType} -> ${elementData.title}',
          );
          parsedElements.add(createdElement);
        } on UnsupportedError {
          print(
            '[FACTORY] type=${elementData.type} -> Unsupported -> ${elementData.title}',
          );
        }
      }

      final homeElements =
          parsedElements.where((element) => element.idGroup == 0).toList();

      print('[OPENCRONO] Elementi caricati: ${parsedElements.length}');

      print(
          '[OPENCRONO PARSER] Elementi trovati: ${parsedElementsData.length}');
      print('[OPENCRONO PARSER] Home elements: ${homeElements.length}');
      for (final element in homeElements) {
        print(
          '[OPENCRONO PARSER] Elemento: id=${element.id ?? ''} type=${element.type ?? -1} title=${element.title ?? ''} idGroup=${element.idGroup ?? -1}',
        );
      }

      setState(() {
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
              Text(
                _currentGroupTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 14),
              if (_elementsError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _elementsError!,
                      style: const TextStyle(color: Color(0xFFFF8A80)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _loadElementsStatus,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              if (_isLoadingElements)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Caricamento elementi...'),
                      ],
                    ),
                  ),
                )
              else ...[
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
                        final icon = switch (element.type ?? -1) {
                          11 => Icons.folder_open,
                          5 => Icons.visibility_outlined,
                          6 => Icons.power_settings_new,
                          _ => Icons.widgets_outlined,
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
                                        (element.title ?? '').isEmpty
                                            ? 'Elemento ${element.id ?? ''}'
                                            : (element.title ?? ''),
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
                                Row(
                                  children: [
                                    Icon(
                                      active
                                          ? Icons.toggle_on
                                          : Icons.toggle_off_outlined,
                                      color: active
                                          ? const Color(0xFF7CF3A0)
                                          : Colors.white38,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? const Color(0xFF7CF3A0)
                                            : const Color(0xFF4A5563),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
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
