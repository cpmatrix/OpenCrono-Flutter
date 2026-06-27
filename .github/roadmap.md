# OpenCrono - Roadmap Tecnica

## ✅ Completato
- Bootstrap app Flutter con tema centralizzato AppTheme.dark.
- Flusso login cloud con AuthService + InceptiumHttpClient.
- Persistenza credenziali in shared_preferences.
- Shell navigazione a tab con ApplianceTabsPage.
- Elenco appliance cloud con CloudAppliancesPage.
- Parsing robusto JSON device con MyDevice.fromJson.
- Caricamento versione server device (command=get?version).
- Apertura OpenCronoPage per device selezionato.
- Caricamento XML elementi da backend remoto.
- Cache XML locale per device con OpenCronoXmlCacheService.
- Parser XML dedicato OpenCronoXmlParser.
- Factory polimorfica OpenCronoElementFactory per type backend.
- Rendering grid elementi con asset on/off per tipo.
- Navigazione gruppi annidati in OpenCronoPage.
- Invio comandi elemento (set_active/set_deactive) con pending confirmation.
- Refresh periodico stato gruppo corrente (1500 ms).
- Test widget base su schermata login.

## 🚧 In sviluppo
- Consolidamento logging: nel codice attuale coesistono AppLog, debugPrint e print.
- Razionalizzazione moduli duplicati/legacy (es. client in core/services vs core/inceptium/services).
- Copertura funzionale tab Local: attualmente placeholder nella tab bar.
- Riduzione componenti placeholder non ancora integrate (es. AppliancesPage, OpenCronoService, AppliancesService).

## 📌 Pianificato
- Estensione comandi OpenCrono oltre switch/timer con UX dedicata per ogni tipo elemento.
- Rafforzamento gestione errori con messaggi contestuali e retry mirati per scenario.
- Incremento test automatici su servizi parser/networking e flussi UI principali.
- Uniformare tutte le immagini elemento con risorse centralizzate dove necessario.
- Documentare ad ogni rilascio variazioni architetturali e funzionali nei file .github.

## Criterio aggiornamento roadmap
Aggiornare questo file quando cambia almeno una delle seguenti aree:
- stato delle feature utente principali
- architettura servizi/parser/cache/factory
- livello copertura test
- supporto piattaforme o release process
