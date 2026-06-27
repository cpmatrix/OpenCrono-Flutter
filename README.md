# opencrono

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Build Toolchain Migration

Per compatibilita con la versione Flutter corrente, la toolchain Android e stata aggiornata con:

- Android Gradle Plugin: 8.6.1
- Gradle Wrapper: 8.7 (bin)
- Kotlin Android Plugin: 1.9.24

Questa migrazione mantiene invariati namespace, applicationId, versionCode, versionName e signing config.

## Aggiornamenti UI e Refresh Elementi (2026-06-27)

Sono state applicate correzioni incrementali alla UI OpenCrono e alla logica di refresh, senza modificare architettura, parser XML o comunicazione Inceptium:

- Ingressi analogici e digitali: valore (numero + unita) riallineato verticalmente verso l'alto per migliorare la centratura nell'area grafica.
- Pending command (quadratino giallo): introdotto timeout di fallback a 5 secondi. Se non arriva variazione stato, l'indicatore viene comunque rimosso automaticamente.
- Aggiornamento valori ingresso: resa piu robusta la visualizzazione del valore ricevuto in refresh (inclusi valori 0 e fallback su status quando il valore numerico non e presente), per mantenere il ridisegno coerente con gli aggiornamenti Inceptium.
- Refresh periodico OpenCrono dinamico su lifecycle: 800 ms quando l'app e in primo piano, 1500 ms fuori foreground.
- Regola aggiuntiva ingresso: se l'unita XML (label_value) e esattamente "mV", viene nascosta solo l'unita e resta visibile il valore numerico.
