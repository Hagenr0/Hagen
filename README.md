# KarteiApp

Eine Karteikarten-Lern-App für iOS – gebaut mit **Swift** und **SwiftUI**. KarteiApp hilft beim Lernen mit digitalen Karteikarten: Stapel anlegen, Karten mit einem **Leitner-System (Spaced Repetition)** abfragen, den Fortschritt per Lern-Streak verfolgen und Kartensätze im eigenen Textformat importieren oder exportieren.

> Persönliches Lernprojekt zur Vertiefung von SwiftUI, dokumentbasierten Apps, Spaced-Repetition-Algorithmen und sauberer App-Architektur.

<p align="center">
  <img src="https://github.com/user-attachments/assets/3efba543-76f3-4954-9bce-aaa63a4aefa0" width="270" alt="KarteiApp – Übersicht">
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/fe1fa588-ab83-4bc2-a65e-4e3e176e3140" width="270" alt="KarteiApp – Lernmodus">
</p>

## Features

- **Stapel & Karten verwalten** – Karten mit Vorderseite, Rückseite, optionaler Zusatzinfo und Thema; Stapel mit Papierkorb (gelöschte Stapel bleiben 7 Tage wiederherstellbar).
- **Leitner-System (Spaced Repetition)** – jede Karte wandert durch fünf Boxen mit wachsenden Wiederholungsintervallen (0 → 1 → 3 → 7 → 16 Tage). Richtig beantwortete Karten steigen auf, falsche fallen zurück in Box 1 und kommen bald wieder dran.
- **Lernmodus** – Karten werden gemischt abgefragt; antippen zum Umdrehen, Wischen nach rechts („Gewusst") oder links („Nochmal"), dazu Fortschrittsanzeige und eine Auswertung am Ende. Falsch beantwortete Karten werden in derselben Runde erneut gezeigt.
- **Lernpläne** – Karten lassen sich über mehrere Lerntage verteilen; die App zeigt gezielt die für heute fälligen Karten.
- **Lern-Streak** – zählt aufeinanderfolgende Lerntage (aktueller und längster Streak); ein ausgelassener Tag setzt den Zähler zurück.
- **Vier Flip-Stile** – 3D-Flip, Karteikarten-Flip, Überblenden und Schneller Flip, umschaltbar in den Einstellungen.
- **Import & Export** – eigenes, menschenlesbares Textformat (siehe unten).
- **Mit Claude erklären** – zu jeder Karte per Knopfdruck eine ausführlichere Erklärung von Claude holen.

## Eigenes Karteikarten-Format

KarteiApp nutzt für Import und Export ein einfaches Textformat – **eine Karte pro Zeile**:

```
[Stapelname] Vorderseite :: Rückseite :: Zusatzinfo
```

- Vorder- und Rückseite werden mit ` :: ` getrennt (Leerzeichen – zwei Doppelpunkte – Leerzeichen). `::` ohne Leerzeichen wird ebenfalls akzeptiert.
- `[Stapelname]` am Zeilenanfang ist **optional** und ordnet die Karte einem Stapel zu.
- Ein dritter Teil ` :: Zusatzinfo` ist **optional** (z. B. Details oder eine Eselsbrücke).
- Leere Zeilen werden ignoriert, überflüssige Leerzeichen automatisch entfernt.

**Beispiel:**

```
[Spanisch] la casa :: das Haus
el agua :: das Wasser :: „el" trotz weiblichem Wort – wegen betontem A
[Mathe] 2+2::4
```

Über **Export** werden deine Karten wieder in genau dieses Format geschrieben – so lassen sich Stapel sichern oder weitergeben.

## Karteikarten mit KI erstellen

Weil das Format so simpel ist, kann dir jede KI (z. B. Claude oder ChatGPT) fertige Karten liefern, die du nur noch importierst. Gib der KI diesen Prompt:

```
Erstelle mir Karteikarten zum Thema: <DEIN THEMA>.
Gib die Karten GENAU in diesem Format aus – eine Karte pro Zeile,
keine Nummerierung, keine Überschriften, kein zusätzlicher Text:

[Stapelname] Vorderseite :: Rückseite :: Zusatzinfo

Regeln:
- Trenne Vorderseite und Rückseite mit " :: " (Leerzeichen, zwei Doppelpunkte, Leerzeichen).
- "[Stapelname]" am Zeilenanfang ist optional und gibt den Stapel an.
- " :: Zusatzinfo" am Ende ist optional (kurze Erklärung oder Eselsbrücke).
- Gib ausschließlich die Kartenzeilen aus, sonst nichts.

Beispiel:
[Biologie] Was ist die Mitochondrie? :: Kraftwerk der Zelle :: erzeugt ATP
```

Danach kopierst du die Ausgabe und fügst sie in der App unter **Import** ein – fertig sind deine Karten.

## Karten mit Claude erklären lassen

In der App gibt es außerdem den Button **„Mit Claude erklären"**: Er baut aus einer Karte automatisch einen Erklär-Prompt, kopiert ihn in die Zwischenablage und öffnet die Claude-App (bzw. `claude.ai`). So bekommst du zu einer Karte schnell Hintergrund, Begründung und – wenn hilfreich – ein Beispiel oder eine Eselsbrücke.

> Hinweis: Das ist eine reine App-Verknüpfung über das URL-Schema (`claude://` / `https://claude.ai`) – **keine API und kein API-Key**.

## Technologien

- **Swift** & **SwiftUI** – komplette Benutzeroberfläche und App-Logik
- **Dokumentbasierte App** – Stapel als eigenes Dokumentformat
- **Spaced Repetition** – selbst implementiertes Leitner-System mit Boxen und Fälligkeitsterminen
- **UserDefaults** – Speicherung von Streak und Einstellungen
- **XCTest** – Unit- und UI-Tests

## Projektstruktur (Auszug)

- `Models.swift` – Datenmodell (Card, Deck) inkl. Leitner-Logik
- `StudyView.swift` – Lernmodus mit Flip, Wisch-Gesten und Auswertung
- `DeckListView.swift` / `DeckDetailView.swift` – Stapel- und Kartenverwaltung
- `ImportView.swift` / `ExportView.swift` / `CardParser.swift` – Import/Export im eigenen Format
- `FlipStyle.swift` / `FlipView.swift` / `FlipSettingsView.swift` – Flip-Animationen
- `StreakManager.swift` – Lern-Streak
- `ClaudeLink.swift` – „Mit Claude erklären"-Verknüpfung
- `TrashView.swift` – Papierkorb für gelöschte Stapel

## Installation

1. Repository klonen oder als ZIP herunterladen.
2. `KarteiApp.xcodeproj` in **Xcode** öffnen.
3. Ein iOS-Ziel (Simulator oder Gerät) auswählen und auf **Run** (⌘R) drücken.

Voraussetzungen: aktuelles Xcode mit iOS-SDK.

## Autor

**Hagen Roth** – Informatikstudent an der HFT Stuttgart
GitHub: [@Hagenr0](https://github.com/Hagenr0)
