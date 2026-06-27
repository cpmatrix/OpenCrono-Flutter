# OpenCrono - Copilot Instructions

## Descrizione del progetto
OpenCrono e una app Flutter che si autentica verso backend Inceptium, elenca device cloud MyShelter e apre una UI OpenCrono per monitorare/controllare elementi PLC remoti (switch, timer, input, gruppi, monitor, message, scheduler).

Entrypoint reale:
- lib/main.dart
- lib/app.dart

Landing reale:
- LoginPage (features/auth/pages/login_page.dart)

## Obiettivi
- Fornire login cloud Inceptium con persistenza credenziali locali.
- Visualizzare appliance cloud disponibili e stato online/offline.
- Aprire la vista OpenCrono per singolo device.
- Caricare stato elementi da XML remoto, con cache locale per resilienza.
- Inviare comandi agli elementi supportati e aggiornare stato via refresh periodico.

## Filosofia del progetto
- Approccio pragmatico e incrementale.
- Focus su integrazione con backend Inceptium/MyShelter.
- UI operativa orientata al controllo device.
- Tolleranza agli errori di rete con fallback (cache XML e messaggi utente).

## Stack tecnologico
- Flutter + Dart (sdk ^3.5.4)
- http
- xml
- shared_preferences
- path_provider
- flutter_launcher_icons

## Architettura generale
Struttura principale:
- core: config, utilita, layer Inceptium condiviso
- features/auth: login e persistenza credenziali
- features/appliances: elenco device cloud e navigazione tab
- features/opencrono: pagina OpenCrono, parser XML, cache XML
- opencrono: factory e modelli widgetizzati degli elementi
- shared: tema e widget UI riusabili

Flusso principale:
1. LoginPage -> AuthService.login
2. AuthService -> InceptiumHttpClient.getNewWebSession
3. Login ok -> ApplianceTabsPage
4. CloudAppliancesPage -> ApplianceService.loadAppliances
5. Tap device -> OpenCronoPage
6. OpenCronoPage -> executeMethod(get elements status) + OpenCronoXmlParser + OpenCronoElementFactory
7. Render GridView con widget specifici per tipo elemento

## Convenzioni di sviluppo
- Organizzazione per feature con separazione pages/services/models.
- Modelli con costruttori immutabili dove possibile.
- Parsing difensivo (try/catch, fallback su array/stringhe vuote).
- Comandi remoti costruiti in modo esplicito e loggati.

## Regole di codifica
Regole obbligatorie:
- NON usare mai print().
- Utilizzare esclusivamente la classe AppLog gia presente nel progetto.
- Ogni nuova funzionalita deve aggiornare automaticamente la documentazione.
- NON effettuare grossi refactoring se non richiesti.
- NON modificare classi funzionanti senza motivo.
- Preferire modifiche incrementali.
- Preferire componenti riutilizzabili.
- Preferire metodi piccoli.
- Preferire classi piccole.

Regole operative aggiuntive:
- Preferire import relativi gia in uso nel progetto.
- Evitare side effects fuori da servizi/page state.
- Gestire sempre mounted prima di aggiornare stato dopo async in StatefulWidget.

Nota stato attuale codice:
- Nel codice esistente sono presenti chiamate print/debugPrint in varie classi. Nuove modifiche devono convergere verso AppLog, senza refactor massivi non richiesti.

## Regole UI
- Tema centrale: AppTheme.dark (lib/shared/theme/app_theme.dart).
- Palette dark con accento teal.
- Schermate principali attive:
  - LoginPage
  - ApplianceTabsPage
  - CloudAppliancesPage
  - OpenCronoPage
- Tab Local e AppliancesPage sono placeholder nel codice corrente.
- Rendering elementi OpenCrono via immagini asset per stato on/off.

## Gestione dello stato
- Stato locale con StatefulWidget + setState.
- Nessuna libreria esterna di state management.
- Stato OpenCrono significativo:
  - mappa globale elementi per id
  - stack gruppi navigazione
  - pending command per elemento
  - timer refresh periodico ogni 1500 ms

## Gestione Networking
Client principali presenti:
- core/inceptium/services/inceptium_http_client.dart (client completo, usato da auth/appliances/opencrono)
- core/services/inceptium_http_client.dart (client semplificato, non nel flusso principale corrente)

Pattern reale:
- Apertura sessione web Inceptium (get_new_inceptium_session)
- Invio comandi con sessione e credenziali codificate
- load app remoto + wait task
- executeMethod per chiamate remote su MyDevice
- timeout, gestione unauthorized, session timeout, connection error

## Gestione Errori
- Try/catch diffuso in servizi e pagine.
- In UI: messaggi errore + retry button dove presenti.
- In OpenCrono: fallback cache XML se server non disponibile.
- In parser XML: ritorno lista vuota in caso di parse failure.

## Regole per Copilot
- Basarsi solo su classi e cartelle reali esistenti.
- Non introdurre nuove architetture senza richiesta esplicita.
- Non rimuovere codice placeholder senza richiesta.
- Se aggiungi feature significativa:
  1. aggiorna copilot-instructions.md
  2. aggiorna architecture.md
  3. aggiorna decisions.md
  4. aggiorna roadmap.md
  5. aggiorna changelog.md
- In ogni PR/patch ricordare esplicitamente l aggiornamento documentazione tecnica .github.

## Prestazioni
- Refresh OpenCrono ogni 1500 ms con guardia _isRefreshingElements.
- Merge incrementale elementi ricevuti nel refresh parziale.
- Cache XML per device su file locale in documents directory.
- Parsing XML in memoria con mapping attributi string->tipo.

## Compatibilita Android
- Presente cartella android e build Gradle standard Flutter.
- applicationId: com.opencrono.opencrono
- minSdk/targetSdk delegati a valori Flutter (flutter.minSdkVersion / flutter.targetSdkVersion).
- Release signing attuale configurato con debug key placeholder nel template.

## Compatibilita iOS
- Presente cartella ios e setup CocoaPods standard Flutter.
- Podfile usa configurazione Flutter default.
- Versione minima iOS non esplicitamente fissata nel Podfile (linea platform commentata).

## Compatibilita Web
- Nel repository corrente non e presente cartella web.
- Web non risulta configurato come target di build dedicato nel codice del progetto.

## Gestione documentazione
Documentazione tecnica permanente in:
- .github/copilot-instructions.md
- .github/architecture.md
- .github/decisions.md
- .github/roadmap.md
- .github/changelog.md

Regola di manutenzione:
- Ogni cambiamento significativo di architettura, servizi, parser, modelli, UI flow o compatibilita deve aggiornare i 5 file sopra.

## Roadmap sintetica
- Completato: login cloud, elenco appliance cloud, apertura OpenCrono, parser XML, cache XML, factory elementi.
- In sviluppo: tab Local (placeholder), hardening logging uniforme, consolidamento classi duplicate/legacy.
- Pianificato: estensione comandi elemento oltre switch/timer, maggiore copertura test, allineamento definitivo documentazione-codice.

## Decisioni architetturali principali
- Comunicazione backend centralizzata su InceptiumHttpClient.
- Parsing XML dedicato con OpenCronoXmlParser.
- Cache per device su file con OpenCronoXmlCacheService.
- Creazione polimorfica elementi via OpenCronoElementFactory.
- Navigazione gerarchica gruppi in OpenCronoPage con stack locale.
- Persistenza credenziali con shared_preferences.
