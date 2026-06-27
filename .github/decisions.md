# OpenCrono - Registro Decisioni Architetturali

Formato decisione:
- Data
- Motivazione
- Impatto
- Possibili evoluzioni

## ADR-001 - Client Inceptium centralizzato
Data: 2026-06-27

Motivazione:
Il progetto concentra la comunicazione remota in InceptiumHttpClient (layer core/inceptium/services), includendo sessione, invio comandi, executeMethod, waitTask e load app.

Impatto:
- Riduce duplicazione logica HTTP nei feature service.
- Standardizza gestione errori/stati connessione.
- Espone stream eventi utile a debug e tracciamento runtime.

Possibili evoluzioni:
- Decommissionare definitivamente il client legacy in core/services.
- Introdurre interfaccia astratta per test/mocking avanzato.

## ADR-002 - Persistenza credenziali con shared_preferences
Data: 2026-06-27

Motivazione:
AuthService salva credenziali e inceptiumId localmente per semplificare login successivi.

Impatto:
- Migliora UX all avvio.
- Richiede attenzione a sicurezza locale dei dati.

Possibili evoluzioni:
- Valutare storage sicuro (es. keychain/keystore) per password.
- Aggiungere policy di scadenza e pulizia credenziali.

## ADR-003 - Parsing XML dedicato OpenCronoXmlParser
Data: 2026-06-27

Motivazione:
La risposta elementi OpenCrono arriva in XML. Parser dedicato converte attributi stringa in DTO tipizzato OpenCronoElementData.

Impatto:
- Isola complessita di parsing da UI/service.
- Fornisce fallback robusto (lista vuota in errore).

Possibili evoluzioni:
- Aggiungere diagnostica parse error piu granulari.
- Introdurre validazione schema minima se payload evolve.

## ADR-004 - Cache XML per device su filesystem
Data: 2026-06-27

Motivazione:
OpenCronoXmlCacheService salva XML per device usando identificatore sanitizzato (softwareCode/serial/deviceName).

Impatto:
- Permette bootstrap/fallback quando risposta server manca.
- Riduce impatto di indisponibilita temporanee backend.

Possibili evoluzioni:
- Introdurre TTL cache.
- Salvare metadati (timestamp, versione server).

## ADR-005 - Factory degli elementi OpenCrono
Data: 2026-06-27

Motivazione:
OpenCronoElementFactory mappa type numerico backend a sottoclassi elemento UI.

Impatto:
- Mantiene la pagina OpenCrono disaccoppiata dai dettagli di rendering per tipo.
- Semplifica estensione nuovi tipi elemento.

Possibili evoluzioni:
- Estrarre mapping in registry configurabile.
- Gestire tipo sconosciuto con placeholder dedicato invece fallback implicito.

## ADR-006 - Navigazione gerarchica gruppi in OpenCronoPage
Data: 2026-06-27

Motivazione:
La UI OpenCrono usa idGroup e stack locale _groupStack per navigare gruppi annidati.

Impatto:
- Esperienza coerente con struttura logica elementi.
- Gestione back custom (WillPopScope + stack).

Possibili evoluzioni:
- Breadcrumb visuale.
- Persistenza gruppo corrente tra aperture pagina.

## ADR-007 - Refresh periodico stato elementi
Data: 2026-06-27

Motivazione:
OpenCronoPage avvia Timer.periodic a 1500 ms per aggiornare elementi del gruppo corrente.

Impatto:
- Allinea UI allo stato remoto quasi real-time.
- Tradeoff su traffico rete e consumo batteria.

Possibili evoluzioni:
- Backoff dinamico su errori o app in background.
- Refresh adattivo su interazione utente.

## ADR-008 - Tracciamento comandi pendenti per elemento
Data: 2026-06-27

Motivazione:
OpenCronoPage mantiene _pendingCommandsByElementId con expectedStatus e timestamp per confermare comando al successivo refresh XML.

Impatto:
- Feedback visivo immediato (badge pending).
- Riduce race condition su comandi concorrenti stesso elemento.

Possibili evoluzioni:
- Timeout pending con errore esplicito in UI.
- Coda comandi per elemento.

## ADR-009 - Stato locale con StatefulWidget + setState
Data: 2026-06-27

Motivazione:
Tutte le schermate principali usano stato locale senza librerie esterne.

Impatto:
- Bassa complessita iniziale.
- Maggiore responsabilita manuale su mounted, timer e sync async.

Possibili evoluzioni:
- Valutare state management condiviso se cresce complessita cross-feature.

## ADR-010 - Logging operativo e direzione verso AppLog
Data: 2026-06-27

Motivazione:
Nel codice convivono AppLog, debugPrint e print. Le regole di progetto stabiliscono di convergere su AppLog e vietare print per nuove modifiche.

Impatto:
- Situazione attuale eterogenea.
- Direzione futura definita per uniformita logging.

Possibili evoluzioni:
- Migrazione incrementale a AppLog.
- Eventuale estensione AppLog con livelli, tag e sink strutturati.
