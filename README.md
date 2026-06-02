# CameraApp (iOS)

Ten projekt jest przygotowany pod SwiftUI i AVFoundation. W tym folderze nie ma jeszcze pliku Xcodeproj, bo pracujesz na Windows. Ponizej kroki na Macu.

## Szybkie uruchomienie (XcodeGen)
1. Zainstaluj Xcode oraz XcodeGen.
2. W terminalu na Macu przejdz do katalogu projektu i uruchom:
   - `xcodegen`
3. Otworz wygenerowany `CameraApp.xcodeproj`.
4. Uruchom na urzadzeniu (kamera i zapisywanie do galerii wymagaja realnego urzadzenia).

## Alternatywnie (recznie w Xcode)
1. Utworz nowy projekt SwiftUI (App) w Xcode.
2. Skopiuj pliki z folderu `CameraApp` do projektu.
3. Dodaj `assets/cameratemplate.jpg` do zasobow projektu (Copy Bundle Resources).
4. Ustaw Info.plist na `CameraApp/Info.plist` lub skopiuj wartosci kluczy uprawnien.

## Najwazniejsze miejsca w kodzie
- Overlay i wyciecie ekranu: `CameraApp/Camera/OverlayProcessor.swift`
- Podglad kamery (pixel + film): `CameraApp/Camera/CameraFilters.swift`
- Zapis z data: `CameraApp/Camera/PixelDateRenderer.swift`
- Przyciski glosnosci: `CameraApp/Camera/VolumeButtonListener.swift`

## Dostosowanie
- Pozycja przycisku migawki: `CameraApp/ContentView.swift`
- Stopien pixelacji: `CameraApp/Camera/CameraFilters.swift`
- Format daty: `CameraApp/Camera/PixelDateRenderer.swift`
