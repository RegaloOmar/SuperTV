# SuperTV

App IPTV (Xtream Codes) para iOS. **SwiftUI + TCA (The Composable Architecture)**, iOS 18+, principios SOLID.

> Alcance MVP: iPhone. La arquitectura está preparada para iPad y tvOS sin reescribir los módulos de dominio.

## Arquitectura

App Xcode delgada que consume un paquete SPM local modular (`Packages/`). Cada módulo es un target-producto aislado; el compilador fuerza el grafo de dependencias (Dependency Inversion real).

```
SuperTV/
├── SuperTV.xcodeproj          # App target (delgado): solo SuperTVApp + Assets
├── SuperTV/                   # Entry point → SuperTVRootView()
└── Packages/                  # Paquete SPM local "IPTVKit"
    └── Sources/
        ├── IPTVCore/          # Dominio puro: modelos + protocolos + DI (sin UI/red/persistencia)
        ├── IPTVNetworking/    # XtreamCodesClient, DTOs, mapeo a dominio  (liveValue del proveedor)
        ├── IPTVPersistence/   # Repositorio cache-first (SwiftData en Fase 2)
        ├── IPTVPlayerKit/     # PlayerEngine (protocolo) + wrapper AVPlayer
        ├── IPTVDesignSystem/  # Tokens + componentes UI reutilizables (StatusView)
        └── IPTVFeatures/      # Features TCA: AppFeature (raíz), AuthFeature (login) + navegación StackState
```

### Regla de dependencias

```
IPTVFeatures ─▶ Core, Networking, Persistence, PlayerKit, DesignSystem, ComposableArchitecture
Networking   ─▶ Core            (aporta liveValue de IPTVProviderProtocol y PlayableStreamProviding)
Persistence  ─▶ Core            (aporta liveValue de ChannelRepositoryProtocol)
PlayerKit    ─▶ Core
Core         ─▶ swift-dependencies   (solo la capa de inyección, no todo TCA)
```

Las Features dependen de **protocolos** definidos en `IPTVCore`, nunca de implementaciones concretas. Los `liveValue` se registran en las capas concretas mediante `extension …Key: DependencyKey`, así Core no conoce la red ni la persistencia.

## Estado por fases

- [x] **Fase 0 — Fundaciones**: workspace modular, DI con `@Dependency`, `AppReducer` con navegación `StackState`, CI, tests base. ✅
- [x] **Fase 1 — Autenticación Xtream Codes**: `AuthFeature` (validación, login, estados), `KeychainCredentialStore`, restauración de sesión al arrancar. ✅
- [x] **Fase 2 — Categorías y canales**: endpoints `get_live_categories`/`get_live_streams` con DTOs tolerantes, repositorio cache-first (SwiftData, TTL 6h, fallback offline), `ChannelListFeature`/`ChannelsFeature` (búsqueda, pull-to-refresh), logos con `AsyncImage` + `URLCache`. ✅
- [x] **Fase 3 — Reproductor**: `AVPlayerEngine` (observación KVO de estados), `PlayerFeature` (loading/buffering/playing/error/reconnecting + reintentos con backoff), controles nativos (play/pausa, volumen, fullscreen), **PiP**, **NowPlaying** (Control Center) y audio en segundo plano. ✅
- [x] **Fase 4 — Settings y pulido**: `SettingsFeature` (info de cuenta, limpiar caché, cerrar sesión), accesibilidad (VoiceOver/Dynamic Type), estados vacíos/error consistentes (`StatusView`), revisión de memory leaks del reproductor. Snapshot tests: pendientes de ubicar en un target de test iOS (ver notas). ✅
- [~] **Fase 5 — App Store**: `PrivacyInfo.xcprivacy`, metadata/copy y notas de review ([docs/AppStore.md](docs/AppStore.md)), política de privacidad ([docs/PrivacyPolicy.md](docs/PrivacyPolicy.md)). Pendiente (manual): cuenta demo, icono, capturas, publicar política. 🚧
- [ ] Fase 2 — Categorías y canales (SwiftData cache-first)
- [ ] Fase 3 — Reproductor (AVPlayer, PiP, NowPlaying)
- [ ] Fase 4 — Settings y pulido
- [ ] Fase 5 — App Store

## Desarrollo

```bash
# Tests de los módulos (headless, sin simulador)
cd Packages && swift test

# Build de la app
xcodebuild build -project SuperTV.xcodeproj -scheme SuperTV \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

CI (GitHub Actions) corre ambos en cada PR: ver [.github/workflows/ci.yml](.github/workflows/ci.yml).
