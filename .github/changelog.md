# OpenCrono - Changelog

Tutte le modifiche tecniche rilevanti del progetto devono essere registrate qui.

## [Unreleased]
### Changed
- Migrazione toolchain Android per compatibilita con Flutter aggiornato:
  - Android Gradle Plugin aggiornato a 8.6.1
  - Gradle Wrapper aggiornato a 8.7 (bin)
  - Kotlin Android Plugin aggiornato a 1.9.24
  - Rimozione flag obsoleti in android/gradle.properties (android.builtInKotlin, android.newDsl)

### Added
- Documentazione tecnica permanente in .github:
  - copilot-instructions.md
  - architecture.md
  - decisions.md
  - roadmap.md
  - changelog.md

### Docs
- Descritta architettura reale del codice Flutter corrente.
- Documentati componenti richiesti:
  - AppLog
  - OpenCronoService
  - OpenCronoXmlParser
  - OpenCronoXmlCacheService
  - OpenCronoElementFactory
  - schermate principali
  - servizi Inceptium
  - modelli
  - parser
  - widget principali

## [1.0.0+1] - Baseline dal codice attuale
### Added
- Entrypoint app Flutter con OpenCronoApp e tema dark.
- LoginPage con login cloud Inceptium.
- AuthService con salvataggio credenziali in shared_preferences.
- InceptiumHttpClient completo nel layer core/inceptium/services.
- ApplianceTabsPage con tab Cloud, Local placeholder, Impostazioni.
- CloudAppliancesPage con caricamento lista appliance cloud.
- ApplianceService con fetch records device e lettura versione server.
- OpenCronoPage con:
  - fetch XML stato elementi
  - cache XML locale per device
  - parser XML dedicato
  - factory elementi per tipo
  - refresh periodico
  - invio comando switch/timer

### Known limitations
- Presenza di moduli placeholder o non integrati nel flow principale.
- Presenza di logging eterogeneo (AppLog + debugPrint + print).
- Target web non configurato nel repository corrente (assenza cartella web).

## Regola di aggiornamento
Per ogni nuova funzionalita significativa aggiornare:
- .github/copilot-instructions.md
- .github/architecture.md
- .github/decisions.md
- .github/roadmap.md
- .github/changelog.md
