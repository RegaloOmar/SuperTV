# SuperTV

Reproductor IPTV (Xtream Codes) para **iPhone, iPad y Apple TV**. **SwiftUI + TCA (The Composable Architecture)**, iOS/tvOS 18+, principios SOLID y arquitectura modular.

> SuperTV es un **reproductor**: no incluye ni distribuye contenido. El usuario introduce las credenciales de su propia suscripción compatible (Xtream Codes) y la app reproduce sus streams. La interfaz de la app está en inglés.

**Estado:** ✅ MVP completo en las 3 plataformas · 📤 iOS/iPad + tvOS **enviadas a revisión de App Store**.

---

## Arquitectura

App Xcode delgada + un paquete SPM local modular (`Packages/`, "IPTVKit"). La **lógica está separada de las vistas**, de modo que iPhone, iPad y tvOS **reutilizan el 100% de los reducers**; solo las vistas son propias de cada plataforma.

```
SuperTV/
├── SuperTV.xcodeproj          # 2 targets de app: SuperTV (iOS/iPad) + SuperTVtvOS (tvOS)
├── SuperTV/                   # Entry point iOS  → SuperTVRootView()   (importa IPTVUI)
├── SuperTVtvOS/               # Entry point tvOS → SuperTVTVRootView() (importa IPTVUITV)
├── Info.plist                 # iOS: ATS (NSAllowsArbitraryLoads) + UIBackgroundModes audio
├── Info-tvOS.plist            # tvOS: misma excepción ATS + audio
├── demo-server/               # Servidor demo Xtream (Python) para la review de Apple
├── docs/                      # Público (GitHub Pages): privacy.html, support.html
├── notes/                     # Interno: copy y checklist de App Store
└── Packages/                  # Paquete SPM "IPTVKit"
    └── Sources/
        ├── IPTVCore/          # Dominio puro: modelos + protocolos + DI (sin UI/red/persistencia)
        ├── IPTVNetworking/    # XtreamCodesClient, DTOs tolerantes, mapeo a dominio
        ├── IPTVPersistence/   # Repositorio cache-first (SwiftData) + Keychain
        ├── IPTVPlayerKit/     # PlayerEngine (protocolo) + wrapper AVPlayer
        ├── IPTVDesignSystem/  # Tokens (negro + oro rosa), componentes, caché de imágenes
        ├── IPTVFeatures/      # Reducers TCA (compartidos por las 3 plataformas)
        ├── IPTVUI/            # Vistas SwiftUI iPhone/iPad (adaptativas)
        └── IPTVUITV/          # Vistas SwiftUI tvOS (focus engine)  [#if os(tvOS)]
```

### Regla de dependencias

```
IPTVUI / IPTVUITV ─▶ IPTVFeatures, Core, PlayerKit, DesignSystem, ComposableArchitecture
IPTVFeatures      ─▶ Core, Networking, Persistence, PlayerKit, DesignSystem, ComposableArchitecture
Networking        ─▶ Core      (liveValue de IPTVProviderProtocol y PlayableStreamProviding)
Persistence       ─▶ Core      (liveValue de ChannelRepositoryProtocol)
PlayerKit         ─▶ Core      (liveValue de PlayerEngine)
Core              ─▶ swift-dependencies   (solo la capa de inyección)
```

Las Features dependen de **protocolos** definidos en `IPTVCore`, nunca de implementaciones concretas. Los `liveValue` se registran en las capas concretas con `extension …Key: DependencyKey` → Dependency Inversion real. Por eso el **target separado de tvOS** reutiliza toda la lógica sin tocar los módulos de dominio.

---

## Plataformas y UI

| Plataforma | Navegación | Notas |
|---|---|---|
| **iPhone** | `NavigationStack` (categorías → canales → reproductor) | compact |
| **iPad** | `NavigationSplitView` (sidebar categorías \| detalle canales) | adaptativo por `horizontalSizeClass` |
| **Apple TV** | `NavigationStack` + focus engine (tarjetas `.card`, `.focusSection()`) | vistas propias en `IPTVUITV` |

**Diseño:** identidad **negro + oro rosa** (dark-first). Tokens en `IPTVDesignSystem`:
`accent #E4ABA0` · `accentStrong #C78A7F` · `background #0B0B0E` · `surface #18181C` · `textPrimary #F5F5F8`.

**Reproductor:** `AVPlayerViewController` nativo (controles, fullscreen, PiP en iOS), `NowPlaying`/Control Center, audio en segundo plano. Todas las mutaciones de `AVPlayer` corren en el main thread (evita el crash de layout de UIKit).

**Caché de logos:** 3 niveles (memoria `NSCache` → disco por hash SHA-256 → red) en `IPTVDesignSystem`.

---

## Estado por fases

- [x] **Fase 0 — Fundaciones**: paquete SPM modular, DI con `@Dependency`, `AppFeature` raíz, CI, tests base.
- [x] **Fase 1 — Autenticación Xtream**: `AuthFeature`, `KeychainCredentialStore`, restauración de sesión.
- [x] **Fase 2 — Categorías y canales**: DTOs tolerantes, repositorio cache-first (SwiftData, TTL 6h, fallback offline), búsqueda y pull-to-refresh.
- [x] **Fase 3 — Reproductor**: `AVPlayerEngine` (KVO), `PlayerFeature` (loading/buffering/playing/error/reconnect + backoff), PiP, NowPlaying, audio en background.
- [x] **Fase 4 — Settings y pulido**: `SettingsFeature`, accesibilidad, estados vacíos/error (`StatusView`).
- [x] **Fase 5 — App Store**: `PrivacyInfo.xcprivacy`, política de privacidad + soporte (GitHub Pages), servidor demo, copy/notas de review. **Enviada a revisión.**
- [x] **Multi-dispositivo**: iPad (split view) + tvOS (target `SuperTVtvOS`), reutilizando reducers.
- [x] **Localización a inglés** de toda la UI.

**Deuda técnica:** snapshot tests (pendientes de ubicar en un target de UI test iOS, compartidos para las 3 plataformas). **Opcional:** iPad hover/teclado.

---

## Servidor demo (review de Apple)

`demo-server/server.py` — servidor compatible con Xtream Codes (Python stdlib, sin dependencias) que sirve un catálogo de prueba con **streams HLS públicos y legales** (Big Buck Bunny, Tears of Steel, Apple BipBop, Mux). Redirige `/live/<user>/<pass>/<id>.m3u8` al HLS real con un `302`.

```bash
cd demo-server && python3 server.py     # http://localhost:8080  (demo / demo)
```

Desplegado en **Render** como Web Service (Root Directory `demo-server`, Start Command `python3 server.py`). Ver [demo-server/README.md](demo-server/README.md).

---

## Desarrollo

```bash
# Tests de los módulos (headless, sin simulador)
cd Packages && swift test

# Build iOS
xcodebuild build -project SuperTV.xcodeproj -scheme SuperTV \
  -destination 'generic/platform=iOS Simulator' -skipMacroValidation
```

> **tvOS:** compila y ejecuta desde **Xcode.app** (scheme `SuperTVtvOS`). El build por CLI de `xcodebuild` para tvOS falla con los plugins de macros de TCA (bug de módulos explícitos de swift-syntax); Xcode.app lo maneja bien. Los 33 tests de lógica se validan con `swift test`.

CI (GitHub Actions): [.github/workflows/ci.yml](.github/workflows/ci.yml).

---

## Stack

SwiftUI · The Composable Architecture 1.26 · AVKit/AVFoundation · SwiftData · Security (Keychain) · MediaPlayer (NowPlaying) · Swift Package Manager.
