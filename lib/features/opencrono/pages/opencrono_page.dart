import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../appliances/models/my_device.dart';
import '../services/opencrono_xml_cache_service.dart';
import '../services/opencrono_xml_parser.dart';
import '../../../core/utils/app_log.dart';
import '../../../opencrono/factory/opencrono_element_factory.dart';
import '../../../opencrono/models/elements/opencrono_element.dart';
import '../../../opencrono/models/elements/opencrono_switch_element.dart';
import '../../../opencrono/models/elements/opencrono_timer_element.dart';
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

class _OpenCronoPageState extends State<OpenCronoPage>
    with WidgetsBindingObserver {
  static const _myDeviceClass =
      'com.incappmyshelteradmin.data.mydevice.MyDevice';
  static const _executeCommandToRemoteClientMethod =
      '_executeCommandToRemoteClient';
  static const Duration _pendingCommandFallbackTimeout = Duration(seconds: 5);
  static const Duration _foregroundRefreshInterval =
      Duration(milliseconds: 800);
  static const Duration _backgroundRefreshInterval =
      Duration(milliseconds: 1500);

  bool _isLoadingElements = false;
  String? _elementsError;

  /// Master map id -> element, populated from full XML on open and merged during partial refreshes.
  final Map<String, OpenCronoElement> _elementsById = {};
  int _currentGroupId = 0;
  String _currentGroupTitle = 'Home';
  final List<_GroupState> _groupStack = [];
  bool _isRefreshingElements = false;
  Timer? _refreshTimer;
  bool _isAppInForeground = true;

  /// Pending commands by element id, to support concurrent commands.
  final Map<int, PendingCommandInfo> _pendingCommandsByElementId = {};
  final Map<int, Timer> _pendingCommandTimeoutsByElementId = {};

  final OpenCronoXmlCacheService _xmlCacheService =
      const OpenCronoXmlCacheService();
  final OpenCronoXmlParser _xmlParser = OpenCronoXmlParser();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    _isAppInForeground =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    AppLog.d('[OPENCRONO] Auto caricamento elementi');
    _loadElementsStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (wasForeground != _isAppInForeground) {
      _restartPeriodicRefreshIfRunning();
      final mode = _isAppInForeground ? 'foreground' : 'background';
      AppLog.d(
        '[OPENCRONO REFRESH] Cambio lifecycle: $mode (${_currentRefreshInterval.inMilliseconds}ms)',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    for (final timer in _pendingCommandTimeoutsByElementId.values) {
      timer.cancel();
    }
    _pendingCommandTimeoutsByElementId.clear();
    AppLog.d('[OPENCRONO REFRESH] Stop refresh');
    super.dispose();
  }

  Duration get _currentRefreshInterval => _isAppInForeground
      ? _foregroundRefreshInterval
      : _backgroundRefreshInterval;

  void _restartPeriodicRefreshIfRunning() {
    if (_refreshTimer == null) {
      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = null;
    _startPeriodicRefresh();
  }

  void _removePendingCommandState(int id) {
    _pendingCommandTimeoutsByElementId.remove(id)?.cancel();
    _pendingCommandsByElementId.remove(id);
  }

  void _removePendingCommand(int id, {bool notifyUi = true, String? reason}) {
    if (!_pendingCommandsByElementId.containsKey(id)) {
      return;
    }

    if (notifyUi && mounted) {
      setState(() {
        _removePendingCommandState(id);
      });
    } else {
      _removePendingCommandState(id);
    }

    if (reason != null && reason.isNotEmpty) {
      AppLog.d('[OPENCRONO COMMAND] Pending rimosso id=$id motivo=$reason');
    }
  }

  void _schedulePendingCommandTimeout(int id) {
    _pendingCommandTimeoutsByElementId[id]?.cancel();
    _pendingCommandTimeoutsByElementId[id] = Timer(
      _pendingCommandFallbackTimeout,
      () {
        if (!mounted || !_pendingCommandsByElementId.containsKey(id)) {
          _pendingCommandTimeoutsByElementId.remove(id)?.cancel();
          return;
        }

        _removePendingCommand(id, reason: 'timeout_5s');
      },
    );
  }

  List<OpenCronoElement> get _visibleElements {
    return _elementsById.values
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

    AppLog.d(
        '[OPENCRONO UI] animazione gruppo da $oldGroupId a ${previous.id}');

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

    AppLog.d('[OPENCRONO UI] tap gruppo $elementTitle id=$elementId');
    AppLog.d('[OPENCRONO UI] animazione gruppo da $oldGroupId a $elementId');

    setState(() {
      _currentGroupId = elementId;
      _currentGroupTitle = elementTitle;
      _groupStack.add(_GroupState(_currentGroupId, _currentGroupTitle));
    });

    AppLog.d('[OPENCRONO UI] apertura gruppo $elementTitle');
    AppLog.d('[OPENCRONO UI] elementi gruppo: ${_visibleElements.length}');
    _logCurrentGroupState();
    _refreshGroupNow(elementId);
  }

  void _onNonGroupElementTap(OpenCronoElement element) {
    if (element is OpenCronoSwitchElement || element is OpenCronoTimerElement) {
      _sendElementCommand(element);
      return;
    }

    final elementTitle = (element.title ?? '').trim().isEmpty
        ? 'Elemento ${element.id ?? ''}'
        : element.title!.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comando non ancora implementato'),
      ),
    );

    AppLog.d('[OPENCRONO UI] tap elemento non gruppo $elementTitle');
  }

  Future<void> _sendElementCommand(OpenCronoElement element) async {
    final id = int.tryParse(element.id ?? '');
    if (id == null || _pendingCommandsByElementId.containsKey(id)) {
      return;
    }

    final currentStatus = element.status ?? 0;
    final expectedStatus = currentStatus == 1 ? 0 : 1;

    setState(() {
      _pendingCommandsByElementId[id] = PendingCommandInfo(
        expectedStatus: expectedStatus,
        startedAt: DateTime.now(),
      );
    });
    _schedulePendingCommandTimeout(id);

    try {
      final status = currentStatus;
      final command =
          status == 1 ? 'command=set_deactive?$id' : 'command=set_active?$id';

      AppLog.d(
          '[OPENCRONO COMMAND] Tap elemento ${element.title} id=$id status=$status');
      AppLog.d('[OPENCRONO COMMAND] Invio: $command');

      final commandB64 = 'cmd:${base64Encode(utf8.encode(command))}';
      final params =
          'serialdevice=${widget.device.serialDevice}::softwarecode=${widget.device.softwareCode}::command_64=$commandB64';

      final response = await widget.client.executeMethod(
        _myDeviceClass,
        _executeCommandToRemoteClientMethod,
        params,
      );

      final trimmed = response.trim();
      AppLog.d('[OPENCRONO COMMAND] Risposta: $trimmed');

      if (!mounted) return;

      if (trimmed.isEmpty || trimmed == 'ERROR') {
        _removePendingCommand(id, reason: 'command_error_response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comando non riuscito')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _removePendingCommand(id, reason: 'command_exception');
      AppLog.e('[OPENCRONO COMMAND] Errore invio comando id=$id: $e');
    } finally {
      AppLog.d(
          '[OPENCRONO COMMAND] Pending attivi: ${_pendingCommandsByElementId.length}');
    }
  }

  void _logCurrentGroupState() {
    final shown = _visibleElements.length;
    AppLog.d(
        '[OPENCRONO UI] Gruppo corrente: $_currentGroupTitle ($_currentGroupId)');
    AppLog.d('[OPENCRONO UI] Elementi mostrati: $shown');
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
      AppLog.d('[OPENCRONO] Caricamento elementi');

      final hasCache = await _xmlCacheService.hasCachedXml(widget.device);
      if (hasCache) {
        AppLog.d(
            '[OPENCRONO CACHE] Cache trovata per ${widget.device.deviceName}');
        final cachedXml = await _xmlCacheService.readCachedXml(widget.device);
        final trimmedCache = cachedXml?.trim() ?? '';
        if (trimmedCache.isNotEmpty) {
          final cachedElements = _buildElementsFromXml(trimmedCache);
          AppLog.d(
              '[OPENCRONO CACHE] Elementi caricati da cache: ${cachedElements.length}');
          if (mounted) {
            setState(() {
              _elementsById
                ..clear()
                ..addAll({for (final e in cachedElements) e.id ?? '': e});
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

      final serverXml = await _fetchElementsXml(null);
      if (serverXml == null) {
        if (!mounted) return;
        if (_elementsById.isEmpty) {
          setState(() {
            _elementsError = 'Risposta vuota o ERROR';
            _isLoadingElements = false;
          });
        }
        _startPeriodicRefresh();
        return;
      }

      AppLog.d('[OPENCRONO SYNC] XML server ricevuto');
      await _xmlCacheService.saveCachedXml(widget.device, serverXml);
      AppLog.d('[OPENCRONO CACHE] Cache aggiornata');

      final parsedElements = _buildElementsFromXml(serverXml);
      if (!mounted) return;

      setState(() {
        _elementsById
          ..clear()
          ..addAll({for (final e in parsedElements) e.id ?? '': e});
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
      if (!mounted) return;
      setState(() {
        _elementsError = 'Errore caricamento elementi: $e';
        _isLoadingElements = false;
      });
    }
  }

  Future<String?> _fetchElementsXml(int? groupId) async {
    final command = groupId == null
        ? 'command=get?elements_status'
        : 'command=get?elements_status::$groupId';
    final commandB64 = 'cmd:${base64Encode(utf8.encode(command))}';
    AppLog.d('[OPENCRONO] Comando: $command');

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

    AppLog.d('[OPENCRONO] Risposta lunga: ${trimmed.length} caratteri');
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

        AppLog.d(
            '[FACTORY] type=${elementData.type} -> ${createdElement.runtimeType} -> ${elementData.title}');
        parsedElements.add(createdElement);
      } on UnsupportedError {
        AppLog.w(
            '[FACTORY] type=${elementData.type} -> Unsupported -> ${elementData.title}');
      }
    }

    return parsedElements;
  }

  void _startPeriodicRefresh() {
    if (_refreshTimer != null) return;
    AppLog.d(
      '[OPENCRONO REFRESH] Avvio refresh periodico ${_currentRefreshInterval.inMilliseconds}ms',
    );
    _refreshTimer = Timer.periodic(
      _currentRefreshInterval,
      (_) => _refreshGroupElements(_currentGroupId),
    );
  }

  Future<void> _refreshGroupNow(int groupId) async {
    await _refreshGroupElements(groupId);
  }

  Future<void> _refreshGroupElements(int groupId) async {
    if (_isRefreshingElements || !mounted) return;

    _isRefreshingElements = true;
    try {
      AppLog.d('[OPENCRONO REFRESH] Gruppo corrente: $groupId');
      AppLog.d(
          '[OPENCRONO REFRESH] Comando: command=get?elements_status::$groupId');

      final xml = await _fetchElementsXml(groupId);
      if (xml == null || !mounted) return;

      final updated = _buildElementsFromXml(xml);
      AppLog.d('[OPENCRONO REFRESH] Elementi ricevuti: ${updated.length}');

      if (!mounted) return;

      int updatedCount = 0;
      setState(() {
        for (final e in updated) {
          final key = e.id ?? '';
          if (key.isNotEmpty) {
            _elementsById[key] = e;
            updatedCount++;

            final id = int.tryParse(key);
            if (id != null) {
              final pending = _pendingCommandsByElementId[id];
              if (pending != null && e.status == pending.expectedStatus) {
                _removePendingCommandState(id);
                AppLog.d(
                  '[OPENCRONO COMMAND] Conferma XML id=$id status=${e.status} in ${DateTime.now().difference(pending.startedAt).inMilliseconds}ms',
                );
              }
            }
          }
        }
        _elementsError = null;
      });

      AppLog.d(
          '[OPENCRONO REFRESH] Elementi aggiornati nella mappa globale: $updatedCount');
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
                              AppLog.d(
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

                              final elementId = int.tryParse(element.id ?? '');
                              final isPending = elementId != null &&
                                  _pendingCommandsByElementId
                                      .containsKey(elementId);

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _onNonGroupElementTap(element),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    widget,
                                    if (isPending)
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: _PendingCommandBadge(),
                                      ),
                                  ],
                                ),
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

class PendingCommandInfo {
  const PendingCommandInfo({
    required this.expectedStatus,
    required this.startedAt,
  });

  final int expectedStatus;
  final DateTime startedAt;
}

class _PendingCommandBadge extends StatefulWidget {
  const _PendingCommandBadge();

  @override
  State<_PendingCommandBadge> createState() => _PendingCommandBadgeState();
}

class _PendingCommandBadgeState extends State<_PendingCommandBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEB3B),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80FFEB3B),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
