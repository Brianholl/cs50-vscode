# cs50-vscode — VS Code estilo CS50 para CachyOS

Réplica local del entorno de [cs50.dev](https://cs50.dev) (el Codespace del
curso CS50 de Harvard): VS Code minimalista, tema oscuro con fondo negro
puro, solo el explorador de archivos, la pestaña del editor y la terminal
abajo.

La configuración sale del repo oficial
[cs50/codespace](https://github.com/cs50/codespace) (`devcontainer.json`).

## Instalación (CachyOS / Arch)

**Todo está en `install.sh` — es autocontenido.** Para el taller basta
copiar ese único archivo (USB, correo, git) a cada máquina y correrlo como
el usuario del alumno (no root):

```bash
./install.sh                  # VS Code + extensiones núcleo + settings
./install.sh --extra          # + Docker, Live Share, Java
./install.sh --tools          # + gcc, clang, gdb, valgrind, python, sqlite
./install.sh --extra --tools  # todo
```

El script:

1. Instala `visual-studio-code-bin` desde AUR (con paru o yay) si falta.
   Tiene que ser la build de Microsoft — el paquete `code` (Code - OSS) de
   los repos no puede instalar `cpptools` ni los language packs.
2. Instala las extensiones (listas `CORE_EXTENSIONS` / `EXTRA_EXTENSIONS`
   dentro del script).
3. Respalda el `settings.json` existente (si hay) y escribe la
   configuración CS50 en `~/.config/Code/User/settings.json`.

## Qué usa CS50 realmente

- **Theme:** `GitHub Dark Default` / `GitHub Light Default` (extensión
  `github.github-vscode-theme`), con fondo forzado a **negro/blanco puro**
  mediante `workbench.colorCustomizations`.
- **Iconos:** `vs-minimal` (viene incluido en VS Code).
- **El look minimalista no es el theme, son settings:** barra de estado
  oculta, sin minimap, sin breadcrumbs, sin command center, sin folding,
  sin squiggles de error, sin hovers ni sugerencias automáticas, autosave.
- **Extensiones:** Python + autopep8, C/C++ (cpptools con clang-format
  estilo CS50), editor hexadecimal, visor de PDF, Prettier SQL, packs de
  idioma, Docker, Live Share, Java.

## Ajustes respecto del original (para escritorio)

- **Tema oscuro fijo** (`window.autoDetectColorScheme: false`): cs50.dev
  sigue al tema del sistema, pero en el taller conviene que todas las
  máquinas se vean igual (y como en las clases). Revertir con `true`.
- **Barra de actividad oculta** (`workbench.activityBar.location`): el
  explorador se muestra/oculta con `Ctrl+B`.
- **Barra de menú en modo toggle** (`window.menuBarVisibility`): en el
  navegador no existe; en escritorio queda oculta y `Alt` la muestra.
- **Sin ventana de chat** (`workbench.secondarySideBar.defaultVisibility:
  "hidden"` + `chat.disableAIFeatures`): desde VS Code ~1.10x la barra
  lateral secundaria con el chat aparece por defecto al abrir carpetas.
- **Sin "Restricted Mode"** (`security.workspace.trust.enabled: false`):
  evita el banner/diálogo de confianza al abrir cualquier carpeta en clase.
- **Terminal abajo al iniciar**: VS Code no tiene setting para abrir el
  panel de terminal al arrancar (`workbench.startupEditor: "terminal"`
  existe pero la abre en el área del editor y genera terminales
  duplicadas). El script instala una mini-extensión local
  (`~/.vscode/extensions/cs50-taller.terminal-abajo-1.0.0/`, ~10 líneas de
  JS embebidas en el script) que al iniciar muestra la terminal del panel
  sin robarle el foco al editor — el mismo enfoque que usa CS50 con sus
  extensiones propias.
- **Explorador solo con archivos y panel solo con TERMINAL**: la
  visibilidad de OUTLINE/TIMELINE y de las pestañas PROBLEMS / OUTPUT /
  DEBUG CONSOLE / PORTS no es un setting — VS Code la guarda en la base
  SQLite de estado del perfil (`globalStorage/state.vscdb`). El script
  siembra esas claves con `sqlite3` (paso que se omite con aviso si VS
  Code está abierto durante la instalación). Cualquier vista se reactiva
  con clic derecho sobre la barra del panel o del explorador.

## Qué NO se puede replicar

Las extensiones propias de CS50 son `.vsix` privados del contenedor y no
están en el marketplace: `ddb50` (el pato debugger con IA), `style50`,
`design50`, `explain50`, `phpLiteAdmin` (los botones design50/style50 que
se ven en las clases vienen de ahí). Tampoco los comandos del contenedor,
aunque esos se pueden instalar con `pip install check50 submit50 style50`
si el taller sigue el curso CS50.

También se omitió lo que solo tiene sentido en Codespaces: reenvío de
puertos remotos, `gitdoc` (auto-commit), el desinstalador de Copilot y el
runtime de Java del contenedor.

## Ajustes posteriores

- Todos los idiomas menos español fueron omitidos; para otro idioma:
  `code --install-extension ms-ceintl.vscode-language-pack-<xx>`.
- Si el look resulta *demasiado* espartano para el taller, los candidatos
  a revertir en el `settings.json` embebido son: `problems.visibility`,
  `C_Cpp.errorSquiggles`, `editor.hover.enabled` y
  `editor.quickSuggestions` (CS50 los apaga para que los alumnos lean los
  errores del compilador en la terminal, no del editor).
