# KarteiApp

Eine Karteikarten-Lern-App für iOS – gebaut mit **Swift** und **SwiftUI**.
KarteiApp hilft beim Lernen mit digitalen Karteikarten: Stapel anlegen, Karten
abfragen, Fortschritt per Lern-Streak verfolgen und Kartensätze importieren
oder exportieren.

> Persönliches Lernprojekt zur Vertiefung von SwiftUI, dokumentbasierten Apps
> und sauberer App-Architektur.

## Features

- **Kartenstapel verwalten** – mehrere Decks anlegen, bearbeiten und durchsuchen
- **Lernmodus** – Karten abfragen und per Tippen umdrehen (Frage/Antwort)
- **Anpassbare Umdreh-Animationen** – verschiedene Flip-Stile über die Einstellungen wählbar
- **Lern-Streak** – tägliche Lernserie zur Motivation
- **Import & Export** – Kartensätze aus Text einlesen und wieder ausgeben
- **Dokumentbasiert** – jeder Stapel wird als eigene Datei gespeichert
- **Papierkorb** – gelöschte Stapel lassen sich wiederherstellen
- **KI-Anbindung** – automatische Erstellung von Karteikarten über die Claude-API *(optional)*

## Screenshots

<!-- Ersetze diese Zeile durch ein oder zwei Screenshots deiner App:
     1. Screenshot im Simulator/iPhone machen
     2. Bild in einen Ordner `screenshots/` im Repo legen
     3. hier einbinden, z. B.: -->

<!-- ![Lernansicht](screenshots/study.png) -->

## Tech Stack

- **Sprache:** Swift
- **UI:** SwiftUI
- **Architektur:** dokumentbasierte App (`FileDocument`), aufgeteilt in Views, Models und Manager
- **Weitere:** Anthropic Claude API (für die KI-gestützte Kartenerstellung)

## Projektstruktur

```
KarteiApp/
├── KarteiApp.swift        # App-Einstiegspunkt
├── Models.swift           # Datenmodelle (Karten, Stapel)
├── KarteiDocument.swift    # Dokument-/Dateiformat
├── DeckListView.swift     # Übersicht aller Stapel
├── DeckDetailView.swift   # Detailansicht eines Stapels
├── StudyView.swift        # Lernmodus
├── FlipView / FlipStyle / FlipSettingsView   # Karten-Umdrehen & Animationen
├── StreakManager.swift    # Lern-Streak-Logik
├── ImportView / ExportView / CardParser      # Import & Export von Karten
├── TrashView.swift        # Papierkorb
└── ClaudeLink.swift       # Anbindung an die Claude-API
```

## Installation

1. Repository klonen:
   ```bash
   git clone https://github.com/hagenr0/KarteiApp.git
   ```
2. `KarteiApp.xcodeproj` in **Xcode** öffnen
3. Ein Ziel (Simulator oder Gerät) auswählen und mit **⌘R** starten

> Für die KI-Funktion muss ein eigener Anthropic-API-Key hinterlegt werden
> (siehe `ClaudeLink.swift`). Der Key ist **nicht** Teil dieses Repositories.

## Tests

Das Projekt enthält Unit- und UI-Tests (`KarteiAppTests`, `KarteiAppUITests`).
Ausführen in Xcode mit **⌘U**.

## Autor

**Hagen Roth** – Informatikstudent an der HFT Stuttgart
</content>

<img width="645" height="1398" alt="Bildschirmfoto 2026-08-15 um 12 33 11" src="https://github.com/user-attachments/assets/3efba543-76f3-4954-9bce-aaa63a4aefa0" />

<img width="645" height="1398" alt="Bildschirmfoto 2026-08-15 um 12 33 48" src="https://github.com/user-attachments/assets/fe1fa588-ab83-4bc2-a65e-4e3e176e3140" />
