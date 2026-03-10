# Expediente Técnico: SaryMusic (Serverless Flutter Architecture)

Este documento define la arquitectura técnica, las dependencias y la estructura base para desarrollar la aplicación móvil "SaryMusic" en Flutter. El objetivo es reemplazar completamente el backend externo de Spring Boot embebiendo la lógica de extracción, reproducción y almacenamiento directamente en el cliente móvil.

## 1. Stack Tecnológico & Dependencias Core

El proyecto utilizará las APIs nativas de Dart para lograr una experiencia de reproducción veloz y sin trabas.

### 1.1 Extracción y Búsqueda (Sustituto de `yt-dlp`)
*   **[youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart):** El núcleo de la aplicación. Realiza búsquedas de canciones en YouTube, extrae metadatos (thumbnail, nombre, artista) y obtiene el `StreamManifest` para conseguir la URL directa del audio (M4A) y reproducirlo al instante.

### 1.2 Base de Datos Local (Sustituto de PostgreSQL)
*   **[isar](https://pub.dev/packages/isar):** Base de datos embebida NoSQL súper rápida construida nativamente para Flutter.
    *   Gestionará las entidades de `Track`, `Playlist` y la relación Many-to-Many entre ambos.
    *   Guardará las rutas absolutas donde se almacenaron las canciones en la memoria interna del teléfono.

### 1.3 Reproductor de Audio
*   **[just_audio](https://pub.dev/packages/just_audio):** El motor principal de reproducción.
    *   Gestiona listas de reproducción `ConcatenatingAudioSource`.
    *   Descarga buffers bajo demanda cuando se usa streaming efímero.
*   **[just_audio_background](https://pub.dev/packages/just_audio_background):** Integración nativa para mostrar los controles musicales en la pantalla de bloqueo y la barra de notificaciones del celular.

### 1.4 Gestor de Descarga Real-time
*   **[background_downloader](https://pub.dev/packages/background_downloader) ó [dio](https://pub.dev/packages/dio):** Para gestionar la descarga de las canciones (archivos estáticos M4A) hacia la memoria interna del dispositivo. `Dio` maneja el progreso y `path_provider` decide dónde guardar.

---

## 2. Definición del Modelo de Datos (Isar DB)

La base de datos móvil (`Isar`) tendrá dos colecciones principales.

### Colección: `Track` (Biblioteca)
```dart
@collection
class Track {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String youtubeId;

  late String title;
  late String artist;
  late String thumbnailUrl;
  late int durationSeconds;

  // Si es null, la canción se reproduce por streaming. 
  // Si tiene datos, significa que fue descargada y se lee desde disco.
  String? localFilePath; 
  
  // Relaciones
  @Backlink(to: 'tracks')
  final playlists = IsarLinks<Playlist>();
}
```

### Colección: `Playlist`
```dart
@collection
class Playlist {
  Id id = Isar.autoIncrement;
  
  late String name;
  late String description;
  final DateTime creationDate = DateTime.now();
  
  // Canciones contenidas
  final tracks = IsarLinks<Track>();
}
```

---

## 3. Arquitectura de Carpetas y Lógica (Clean Architecture)

El proyecto se estructurará separando la UI de los motores locales:

```text
lib/
├── main.dart
├── core/
│   ├── theme/             # Material 3 + Dark mode preferences
│   └── routes/            # go_router configuration
├── data/
│   ├── database/          # isar_service.dart (Init, Create, Read, Delete)
│   ├── models/            # Track, Playlist (.g.dart generated files)
│   └── repositories/      # track_repository.dart
├── services/
│   ├── youtube_service.dart # Búsqueda y Extracción de Stream URL usando youtube_explode
│   ├── audio_player_service.dart # just_audio wrapper (Play, Pause, Queue control)
│   └── download_service.dart # Stream URL to local /Music/ folder logic
└── ui/
    ├── screens/
    │   ├── search/        # Discover page, Youtube integration UI
    │   ├── library/       # Local DB Tracks
    │   ├── playlists/     # Local DB Playlists
    │   └── player/        # Full screen visual player
    └── widgets/
        ├── mini_player.dart   # Floating player en toda la app
        └── track_tile.dart    # Lista de canciones estandar
```

## 4. Flujos Clave de la App

### 4.1. Búsqueda y Streaming Efímero (Play de Inmediato)
1. El usuario busca "Post Malone".
2. `youtube_service` llama a `yt.search(...)` y puebla la UI.
3. El usuario da clic a "Circles".
4. `youtube_service` saca el `StreamManifest` y obtiene el `.url` de mayor calidad M4A.
5. Se pasa el URL a `audio_player_service.play(url)` en memoria. El usuario está escuchando sin consumir disco duro.

### 4.2. Agregar a Biblioteca (Descarga)
1. El usuario presiona el icono "Descargar / Guardar".
2. `youtube_service` obtiene el URL de alta calidad.
3. `download_service` usa `Dio` para bajar el `.m4a` a `path_provider.getApplicationDocumentsDirectory()`.
4. Éxito: Se crea el registro en `Isar`, seteando el `localFilePath`.
5. Desde ese momento, cuando el usuario le da "Play" en la pantalla "Biblioteca", `audio_player_service` reproduce localmente sin internet.

## 5. Próximos Pasos Recomendados para Iniciar
1. Crear el proyecto en Flutter SDK `3.22+` y configurar Riverpod (para el estado).
2. Crear la configuración base con los generadores de `Isar` (`build_runner`).
3. Construir un script simple en `main.dart` que logre extraer y reproducir un ID (Prueba de concepto de `youtube_explode_dart` + `just_audio`).
