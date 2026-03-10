# Expediente Técnico: Diseño e Interfaz UI/UX (SaryMusic Flutter)

La aplicación adoptará la filosofía de diseño **"Cybernetic Pro"**, centrada en el minimalismo oscuro, alto contraste, acentos lumínicos (glow/neón) y micro-interacciones fluidas. Este documento establece los lineamientos visuales para garantizar una experiencia inmersiva y futurista.

## 2. Pautas de Diseño e Interfaz (UI/UX)
La aplicación adoptará la filosofía de diseño **"Cybernetic Pro"**, centrada en el minimalismo oscuro, alto contraste y acentos lumínicos (glow/neón).

### 🎨 Paleta de Colores
*   **Fondo Principal (Background):** `Negro Cibernético` (`#0D0D0D` a `#121212`) - Reduce fatiga visual y ahorra batería en pantallas OLED/AMOLED.
*   **Superficies / Tarjetas (Surface):** `Gris Oscuro Translúcido` (`#1C1C1C`) con sutiles efectos de *Glassmorphism* (opacidad y desenfoque de fondo).
*   **Acento Principal (Primary/Action):** `Rojo Neón / Láser` (`#FF2A2A` o `#E50914`). Se usará en botones primarios, barras de progreso de la canción, íconos activos y animaciones de carga.
*   **Tipografía y Textos (Text):** `Blanco Puro` (`#FFFFFF`) para Títulos principales y `Gris Platino` (`#B3B3B3`) para subtítulos, artistas y letras atenuadas.

### 🔤 Tipografía Recomendada
*   **Fuente Principal:** `Orbitron` o `Rajdhani` (Para títulos, nombres de la app y logos. Aporta el aspecto tecnológico/cibernético).
*   **Fuente Secundaria (Lectura):** `Inter` o `Roboto Mono` (Para listas de canciones, duraciones y textos largos garantizando legibilidad perfecta en interfaces condensadas).

### ✨ Elementos Táctiles "Cybernetic Pro"
Se abandona el Material Design plano tradicional en favor de "Neumorfismo Iluminado".
*   **Botones Principales:** En lugar de pastillas estándar, se usarán botones con bordes ligeramente biselados (ej. `borderRadius` leve) con una pequeña sombra paralela roja (`BoxShadow` color rojo neon) al ser presionados (Efecto "Holograma encendido").
*   **Cards de Canciones (Track Tiles):** Fondo estático. Al mantener presionado o deslizar (Swipe to Action) se revela un brillo metálico o rojo detrás del tile.
*   **Navegación Inferior (Bottom Nav):** Diseño tipo cápsula flotante con fecto "Glassmorphism". El ícono activo tiene un borde brillante rojo y un leve resplandor.

### 🎛️ El Reproductor (Player Full Screen View)
El corazón de la app, diseñado para impresionar visualmente al usuario.
*   **Cover Art (Carátula):** Ocupa la mitad superior de la pantalla. Durante la reproducción, el arte "respira" pulsando levemente en sincro.
*   **Player View (Visualizador Dinámico):** Implementación de un visualizador de frecuencias de audio o una barra de onda asimétrica con gradiente que va de rojo intenso a rojo oscuro acompañando los segundos de la canción en lugar de un `Slider` aburrido.
*   **Controles Centrales:** Play/Pause de gran tamaño con resplandor neón profundo al reproducir. Botones Next/Prev  minimalistas y geométricos.

### 🕹️ Micro-Interacciones y "Feedback"
*   **Haptic Feedback (Vibración Táctil):** El teléfono debe ejecutar vibraciones mínimas (`HapticFeedback.lightImpact()`) al darle "Me gusta" o pausar para que la app interactúe físicamente con la mano del usuario.
*   **Transiciones Escala-Fade:** La navegación no usa deslizados genéricos de Android/iOS. Usaremos animaciones FadeUpwards para dar sensación de velocidad informática tipo Sci-Fi.

### 🗄️ Estados Vacíos (Empty States)
Cuando la biblioteca o búsquedas estén vacías, la UX debe mantenerse:
*   Mostrar arte vectorial futurista o íconos "Glitch" art.
*   Ej. Texto: *"Base de datos sin registros"*, o *"Señal no identificada"* en lugar de un genérico "No hay resultados".


---
## 6. Estructura de Navegación y Pantallas (App Flow)
Para una UX elegante y moderna, la app se dividirá mediante una navegación híbrida inmersiva clara e intuitiva, inspirada en las principales plataformas de streaming pero con identidad Cybernetic Pro.

### 🌐 Navegación Base (El Sistema Solar de la App)
*   **Bottom Navigation Bar (Menú Inferior):**
    Una barra flotante translúcida (efecto vidrio oscuro/Glassmorphism) separada del borde inferior de la pantalla. Contendrá 4 íconos minimalistas:
    1.  `🏠 Inicio` (Home)
    2.  `🔍 Buscar` (Search)
    3.  `📚 Biblioteca` (Library)
    4.  `⚙️ Más` (Settings)
*   **Top App Bar (Barra Superior Universal):**
    *   **Lado izquierdo:** El título de la pantalla actual en fuente `Orbitron` blanca brillante.
    *   **Lado derecho:** **[Avatar del Usuario]**. Al hacer clic en este avatar redondo, se desplegará el perfil para gestionar sus detalles y configuración.

### 🏠 Pantalla de Inicio (Home)
Diseñada para invitar a la escucha inmediata mediante carruseles horizontales.
*   *Sección 1:* "Escuchado Recientemente" (Tarjetas de canciones largas).
*   *Sección 2:* "Recomendado para ti" (Cuadrados grandes con covers) generados a partir de su biblioteca.

### 🔍 Pantalla de Búsqueda (Search)
*   La barra de búsqueda será prominente y redondeada.
*   **Streaming vs Descarga:** Cada canción en los resultados de búsqueda mostrará dos iconos rápidos:
    1.  `▶️ Play`: Lanza la lógica de "Streaming On-Demand". La app reproduce la música **en vivo** sin consumir disco.
    2.  `⬇️ Descargar`: Una animación de progreso de carga guardará la canción localmente en el dispositivo.

### 📚 Pantalla de Biblioteca (Library)
El centro de control offline, dividido por tabs (`TabBar`).
*   **Tab "Canciones" (Offline):** Listado de todo lo descargado. Al darle Play, sonará instantáneamente sin depender de internet. Se diferenciarán visualmente de las canciones online.
*   **Tab "Playlists" (Listas de Reproducción):**
    *   **Botón Prominente +:** Un botón de Acción Rojo Neón que diga `Crear Nueva Playlist`. 
    *   Las Playlists creadas se mostrarán como grandes tarjetas en parrilla (Grid).

### 🎵 El Reproductor Híbrido (Core UX)
*   **El Mini-Player Flotante:** No importa si estás en Inicio, Buscar o Biblioteca, si hay música sonando **siempre** habrá una barra horizontal flotando por encima de tu menú inferior. Contiene botones de Play/Pausa rápidos.
*   **Pantalla Completa (Player Screen):** Al tocar el Mini-Player, este se expande a pantalla completa. Muestra el cover art inmenso respirando al ritmo, controles gigantes con resplandor, y reemplazará la barra de duración recta por una onda de frecuencias/barras asimétricas de progreso.
