import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../appliances/models/my_device.dart';
import '../services/opencrono_xml_cache_service.dart';
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
  bool _isRefreshingElements = false;
  Timer? _refreshTimer;

  final OpenCronoXmlCacheService _xmlCacheService =
      const OpenCronoXmlCacheService();
  final OpenCronoXmlParser _xmlParser = OpenCronoXmlParser();

  @override
  void initState() {
    super.initState();
    print('[OPENCRONO] Auto caricamento elementi');
    _loadElementsStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    print('[OPENCRONO REFRESH] Stop refresh');
    super.dispose();
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

    final oldGroupId = _currentGroupId;

    _groupStack.removeLast();
    final previous = _groupStack.isNotEmpty
        ? _groupStack.last
        : const _GroupState(0, 'Home');

    print(
      '[OPENCRONO UI] animazione gruppo da $oldGroupId a ${previous.id}',
    );

    setState(() {
      _currentGroupId = previous.id;
      _currentGroupTitle = previous.title;
    });

    _logCurrentGroupState();
  }

  void _openGroup(OpenCronoElement element) {
    final oldGroupId = _currentGroupId;
    final elementId = int.tryParse(element.id ?? '') ?? 0;
    final elementTitle = (element.title ?? '').trim().isEmpty
        ? 'Gruppo $elementId'
        : element.title!.trim();

    print(
      '[OPENCRONO UI] tap gruppo $elementTitle id=$elementId',
    );
    print('[OPENCRONO UI] animazione gruppo da $oldGroupId a $elementId');

    setState(() {
      _currentGroupId = elementId;
      _currentGroupTitle = elementTitle;
      _groupStack.add(_GroupState(_currentGroupId, _currentGroupTitle));
    });

    print('[OPENCRONO UI] apertura gruppo $elementTitle');
    print('[OPENCRONO UI] elementi gruppo: ${_visibleElements.length}');
    _logCurrentGroupState();
  }

  void _onNonGroupElementTap(OpenCronoElement element) {
    final elementTitle = (element.title ?? '').trim().isEmpty
        ? 'Elemento ${element.id ?? ''}'
        : element.title!.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comando non ancora implementato'),
      ),
    );

    print('[OPENCRONO UI] tap elemento non gruppo $elementTitle');
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

      final hasCache = await _xmlCacheService.hasCachedXml(widget.device);
      if (hasCache) {
        print(
          '[OPENCRONO CACHE] Cache trovata per ${widget.device.deviceName}',
        );
        final cachedXml = await _xmlCacheService.readCachedXml(widget.device);
        final trimmedCache = cachedXml?.trim() ?? '';
        if (trimmedCache.isNotEmpty) {
          final cachedElements = _buildElementsFromXml(trimmedCache);
          print(
            '[OPENCRONO CACHE] Elementi caricati da cache: ${cachedElements.length}',
          );
          if (mounted) {
            setState(() {
              _allElements = cachedElements;
              _currentGroupId = 0;
              _currentGroupTitle = 'Home';
              _groupStack
                ..clear()
                ..add(const _GroupState(0, 'Home'));
              _elementsError = null;
              _isLoadingElements = false;
            });
          }
        }
      }

      final serverXml = await _fetchElementsXml();
      if (serverXml == null) {
        if (!mounted) {
          return;
        }

        if (_allElements.isEmpty) {
          setState(() {
            _elementsError = 'Risposta vuota o ERROR';
            _isLoadingElements = false;
          });
        }
        _startPeriodicRefresh();
        return;
      }

      print('[OPENCRONO SYNC] XML server ricevuto');
      await _xmlCacheService.saveCachedXml(widget.device, serverXml);
      print('[OPENCRONO CACHE] Cache aggiornata');

      final parsedElements = _buildElementsFromXml(serverXml);
      if (!mounted) {
        return;
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
      _startPeriodicRefresh();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _elementsError = 'Errore caricamento elementi: $e';
        _isLoadingElements = false;
      });
    }
  }

  Future<String?> _fetchElementsXml() async {
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
      return null;
    }

    print('[OPENCRONO] Risposta lunga: ${trimmed.length} caratteri');
    final preview300 =
        trimmed.length <= 300 ? trimmed : trimmed.substring(0, 300);
    print('[OPENCRONO] Anteprima XML: $preview300');
    return trimmed;
  }

  List<OpenCronoElement> _buildElementsFromXml(String xml) {
    final parsedElementsData = _xmlParser.parseElementsStatus(xml);
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

    return parsedElements;
  }

  void _startPeriodicRefresh() {
    if (_refreshTimer != null) {
      return;
    }

    print('[OPENCRONO REFRESH] Avvio refresh periodico 1500ms');
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _refreshElementsStatus(),
    );
  }

  Future<void> _refreshElementsStatus() async {
    if (_isRefreshingElements || !mounted) {
      return;
    }

    _isRefreshingElements = true;
    try {
      print('[OPENCRONO REFRESH] Aggiornamento XML');
      final serverXml = await _fetchElementsXml();
      if (serverXml == null || !mounted) {
        return;
      }

      await _xmlCacheService.saveCachedXml(widget.device, serverXml);
      print('[OPENCRONO CACHE] Cache aggiornata');

      final updatedElements = _buildElementsFromXml(serverXml);
      if (!mounted) {
        return;
      }

      setState(() {
        _allElements = updatedElements;
        _elementsError = null;
      });

      print(
          '[OPENCRONO REFRESH] Elementi aggiornati: ${updatedElements.length}');
    } finally {
      _isRefreshingElements = false;
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
          leading: BackButton(
            onPressed: _goBackPressed,
          ),
          title: Text(
            widget.device.deviceName.isEmpty
                ? 'Device senza nome'
                : widget.device.deviceName,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _currentGroupTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              const SizedBox(height: 10),
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
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: visibleElements.isNotEmpty
                        ? GridView.builder(
                            key: ValueKey('grid-$_currentGroupId'),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.80,
                            ),
                            itemCount: visibleElements.length,
                            itemBuilder: (context, index) {
                              final element = visibleElements[index];
                              final title = (element.title ?? '').isEmpty
                                  ? 'Elemento ${element.id ?? ''}'
                                  : (element.title ?? '');
                              print(
                                '[OPENCRONO UI] uso buildElementWidget per $title',
                              );
                              final widget =
                                  element.buildElementWidget(context);

                              if (element.type == 11) {
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _openGroup(element),
                                  child: widget,
                                );
                              }

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _onNonGroupElementTap(element),
                                child: widget,
                              );
                            },
                          )
                        : Center(
                            key: ValueKey('empty-$_currentGroupId'),
                            child: const Text(
                              'Nessun elemento nel gruppo corrente',
                              style: TextStyle(color: Colors.white70),
                            ),
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
