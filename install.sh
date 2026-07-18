#!/usr/bin/env bash
#
# install.sh — VS Code estilo CS50 (cs50.dev) para CachyOS / Arch Linux
#
# Script AUTOCONTENIDO: basta copiar este archivo a cada máquina.
# Instala VS Code (build de Microsoft, desde AUR), las extensiones que usa
# el Codespace de CS50 y su configuración minimalista: theme GitHub Dark
# Default con fondo negro puro, sin barra de estado, sin barra de
# actividad, sin minimap, terminal abajo. Fuente de la configuración:
# https://github.com/cs50/codespace (devcontainer.json).
#
# Uso:
#   ./install.sh              instalación estándar
#   ./install.sh --extra      además: Docker, Live Share y Java
#   ./install.sh --tools      además: gcc, clang, gdb, python, sqlite, etc.
#   ./install.sh --extra --tools
#
# Requiere: CachyOS/Arch con paru o yay (CachyOS trae paru de fábrica).
# NO ejecutar como root.

set -euo pipefail

USER_DIR="$HOME/.config/Code/User"

WITH_EXTRA=0
WITH_TOOLS=0
for arg in "$@"; do
    case "$arg" in
        --extra) WITH_EXTRA=1 ;;
        --tools) WITH_TOOLS=1 ;;
        -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Opción desconocida: $arg (usar --help)"; exit 1 ;;
    esac
done

msg()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m ✗ %s\033[0m\n' "$*"; exit 1; }

[ "$(id -u)" -eq 0 ] && fail "No ejecutar como root: el helper de AUR necesita un usuario normal."

# ── 1. VS Code (build de Microsoft; necesaria para cpptools y el marketplace) ──
if command -v code >/dev/null 2>&1; then
    # Code - OSS (paquete 'code' de los repos) no puede instalar cpptools ni
    # los language packs: usa Open VSX en vez del marketplace de Microsoft.
    if pacman -Q code >/dev/null 2>&1 && ! pacman -Q visual-studio-code-bin >/dev/null 2>&1; then
        fail "Tenés instalado 'code' (Code - OSS). Desinstalalo (sudo pacman -R code) y volvé a correr el script para instalar visual-studio-code-bin."
    fi
    ok "VS Code ya instalado: $(code --version | head -1)"
else
    AUR_HELPER=""
    for h in paru yay; do
        command -v "$h" >/dev/null 2>&1 && { AUR_HELPER="$h"; break; }
    done
    [ -n "$AUR_HELPER" ] || fail "No hay paru ni yay. Instalá uno primero (CachyOS: sudo pacman -S paru)."
    msg "Instalando visual-studio-code-bin desde AUR con $AUR_HELPER…"
    "$AUR_HELPER" -S --needed --noconfirm visual-studio-code-bin
    ok "VS Code instalado."
fi

# ── 2. Extensiones ──
# Núcleo: las mismas que usa el Codespace de CS50 y que existen en el
# marketplace. Las extensiones propias de CS50 (ddb50, style50, design50,
# explain50) son .vsix privados del contenedor y no se pueden instalar.
CORE_EXTENSIONS=(
    github.github-vscode-theme          # theme GitHub Dark/Light Default
    ms-python.python
    ms-python.autopep8                  # formateador Python de CS50
    ms-vscode.cpptools                  # C/C++ con clang-format estilo CS50
    ms-vscode.hexeditor
    mathematic.vscode-pdf
    inferrinizzard.prettier-sql-vscode
    ms-ceintl.vscode-language-pack-es   # interfaz en español
)

EXTRA_EXTENSIONS=(
    ms-azuretools.vscode-docker
    ms-vsliveshare.vsliveshare          # colaboración en vivo entre alumnos
    redhat.java
    vscjava.vscode-java-debug
)

install_extensions() {
    local ext
    for ext in "$@"; do
        msg "Extensión: $ext"
        code --install-extension "$ext" --force >/dev/null \
            && ok "$ext" \
            || echo "   (falló $ext — continuar y reintentar luego con: code --install-extension $ext)"
    done
}

install_extensions "${CORE_EXTENSIONS[@]}"
[ "$WITH_EXTRA" -eq 1 ] && install_extensions "${EXTRA_EXTENSIONS[@]}"

# ── 3. Configuración (settings.json) ──
mkdir -p "$USER_DIR"
if [ -f "$USER_DIR/settings.json" ]; then
    BACKUP="$USER_DIR/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$USER_DIR/settings.json" "$BACKUP"
    msg "settings.json existente respaldado en: $BACKUP"
fi

# Réplica del devcontainer.json de cs50/codespace, sin las claves exclusivas
# de Codespaces (puertos remotos, gitdoc, extension-uninstaller, runtime de
# Java del contenedor) y con tres ajustes para escritorio: tema oscuro fijo,
# barra de actividad oculta y barra de menú en modo toggle (Alt la muestra).
cat > "$USER_DIR/settings.json" << 'CS50_SETTINGS'
{
    "accessibility.signals.terminalBell": {
        "sound": "on"
    },
    "breadcrumbs.enabled": false,

    "C_Cpp.autocomplete": "disabled",
    "C_Cpp.clang_format_fallbackStyle": "{ AllowShortFunctionsOnASingleLine: Empty, BraceWrapping: { AfterCaseLabel: true, AfterControlStatement: true, AfterFunction: true, AfterStruct: true, BeforeElse: true, BeforeWhile: true }, BreakBeforeBraces: Custom, ColumnLimit: 100, IndentCaseLabels: true, IndentWidth: 4, SpaceAfterCStyleCast: true, TabWidth: 4 }",
    "C_Cpp.codeFolding": "disabled",
    "C_Cpp.debugShortcut": false,
    "C_Cpp.dimInactiveRegions": false,
    "C_Cpp.doxygen.generateOnType": false,
    "C_Cpp.enhancedColorization": "enabled",
    "C_Cpp.errorSquiggles": "disabled",
    "C_Cpp.formatting": "clangFormat",

    "chat.disableAIFeatures": true,
    "diffEditor.diffAlgorithm": "advanced",
    "diffEditor.ignoreTrimWhitespace": false,

    "editor.autoClosingQuotes": "never",
    "editor.colorDecorators": false,
    "editor.emptySelectionClipboard": false,
    "editor.folding": false,
    "editor.foldingHighlight": false,
    "editor.formatOnSave": false,
    "editor.guides.indentation": false,
    "editor.hover.enabled": "off",
    "editor.lightbulb.enabled": "off",
    "editor.matchBrackets": "never",
    "editor.minimap.enabled": false,
    "editor.mouseWheelZoom": true,
    "editor.occurrencesHighlight": "off",
    "editor.parameterHints.enabled": false,
    "editor.quickSuggestions": {
        "other": "off",
        "comments": "off",
        "strings": "off"
    },
    "editor.renderWhitespace": "selection",
    "editor.selectionHighlight": false,
    "editor.semanticTokenColorCustomizations": {
        "[GitHub Dark Default]": {
            "rules": {
                "type": "#FF7E76"
            }
        },
        "[GitHub Light Default]": {
            "rules": {
                "type": "#D2343F"
            }
        }
    },
    "editor.stickyScroll.enabled": false,
    "editor.suggestOnTriggerCharacters": false,

    "explorer.autoOpenDroppedFile": false,
    "explorer.compactFolders": false,
    "extensions.ignoreRecommendations": true,

    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.exclude": {
        "**/.*": true
    },
    "files.insertFinalNewline": true,
    "files.trimTrailingWhitespace": true,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/*/**": true
    },

    "git.autofetch": true,
    "git.decorations.enabled": false,

    "html.autoCreateQuotes": false,
    "html.format.indentInnerHtml": true,
    "html.suggest.html5": false,

    "js/ts.format.insertSpaceAfterFunctionKeywordForAnonymousFunctions": false,
    "js/ts.suggest.enabled": false,
    "js/ts.validate.enabled": false,

    "Prettier-SQL.keywordCase": "upper",
    "problems.decorations.enabled": false,
    "problems.visibility": false,

    "python.terminal.executeInFileDir": true,
    "python.terminal.shellIntegration.enabled": false,
    "[python]": {
        "editor.defaultFormatter": "ms-python.autopep8"
    },

    "scm.countBadge": "off",
    // Sin diálogo/banner de "Restricted Mode" al abrir carpetas (aula)
    "security.workspace.trust.enabled": false,

    "terminal.integrated.commandsToSkipShell": [
        "workbench.action.toggleSidebarVisibility"
    ],
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.enableVisualBell": true,
    "terminal.integrated.gpuAcceleration": "off",
    "terminal.integrated.persistentSessionReviveProcess": "never",
    "terminal.integrated.sendKeybindingsToShell": true,
    "terminal.integrated.shellIntegration.enabled": true,
    "terminal.integrated.shellIntegration.decorationsEnabled": "never",
    "terminal.integrated.showExitAlert": false,
    "terminal.integrated.tabs.description": "${task}${separator}${local}",
    "terminal.integrated.tabs.showActiveTerminal": "never",

    "window.autoDetectColorScheme": false,
    "window.commandCenter": false,
    "window.menuBarVisibility": "toggle",
    "workbench.preferredDarkColorTheme": "GitHub Dark Default",
    "workbench.preferredLightColorTheme": "GitHub Light Default",
    "workbench.colorTheme": "GitHub Dark Default",
    "workbench.colorCustomizations": {
        "editor.lineHighlightBorder": "#0000",
        "editorError.foreground": "#0000",
        "editorWarning.foreground": "#0000",
        "editorGutter.addedBackground": "#0000",
        "editorGutter.deletedBackground": "#0000",
        "editorGutter.modifiedBackground": "#0000",
        "[GitHub Dark Default]": {
            "activityBar.background": "#000",
            "editor.background": "#000",
            "editor.lineHighlightBackground": "#0000",
            "editor.lineHighlightBorder": "#0000",
            "editorWhitespace.foreground": "#59A5FC",
            "panel.background": "#000",
            "sideBar.background": "#000",
            "terminal.foreground": "#fff",
            "terminal.background": "#000"
        },
        "[GitHub Light Default]": {
            "activityBar.background": "#fff",
            "editor.background": "#fff",
            "editor.lineHighlightBackground": "#fff0",
            "editor.lineHighlightBorder": "#fff0",
            "editorWhitespace.foreground": "#1167D7",
            "panel.background": "#fff",
            "sideBar.background": "#fff",
            "terminal.foreground": "#000",
            "terminal.background": "#fff"
        }
    },

    "workbench.activityBar.location": "hidden",
    "workbench.editor.closeOnFileDelete": true,
    "workbench.editor.empty.hint": "hidden",
    "workbench.editor.enablePreview": false,
    "workbench.editor.labelFormat": "medium",
    "workbench.editorAssociations": {
        "*.wav": "vscode.audioPreview"
    },
    "workbench.iconTheme": "vs-minimal",
    "workbench.layoutControl.enabled": false,
    "workbench.secondarySideBar.defaultVisibility": "hidden",
    "workbench.startupEditor": "none",
    "workbench.statusBar.visible": false,
    "workbench.tips.enabled": false,
    "workbench.welcomePage.walkthroughs.openOnInstall": false
}
CS50_SETTINGS
ok "Configuración CS50 aplicada en $USER_DIR/settings.json"

# ── 4. Mini-extensión: terminal abajo al iniciar ──
# VS Code no tiene setting para abrir el panel de terminal al arrancar
# (workbench.startupEditor "terminal" la abre en el área del editor, que no
# es lo que hace cs50.dev). Esta extensión local la abre en el panel.
EXT_DIR="$HOME/.vscode/extensions/cs50-taller.terminal-abajo-1.0.0"
mkdir -p "$EXT_DIR"

cat > "$EXT_DIR/package.json" << 'EXT_PKG'
{
    "name": "terminal-abajo",
    "displayName": "Terminal abajo (estilo CS50)",
    "description": "Abre la terminal integrada en el panel inferior al iniciar, como en cs50.dev",
    "publisher": "cs50-taller",
    "version": "1.0.0",
    "engines": { "vscode": "^1.75.0" },
    "main": "./extension.js",
    "activationEvents": ["onStartupFinished"]
}
EXT_PKG

cat > "$EXT_DIR/extension.js" << 'EXT_JS'
const vscode = require('vscode');

function activate() {
    // Mostrar la terminal del panel sin robarle el foco al editor;
    // si ya existe una (sesión restaurada), solo asegurarse de que se vea.
    const terminal = vscode.window.terminals[0] ?? vscode.window.createTerminal();
    terminal.show(true);
}

function deactivate() {}

module.exports = { activate, deactivate };
EXT_JS
ok "Extensión local 'terminal-abajo' instalada en $EXT_DIR"

# ── 5. Ocultar vistas: OUTLINE/TIMELINE y pestañas extra del panel ──
# La visibilidad de estas vistas no es un setting: VS Code la guarda en la
# base SQLite de estado del perfil (~/.config/Code/User/globalStorage/
# state.vscdb). Se siembran las claves para dejar el explorador solo con
# los archivos y el panel inferior solo con TERMINAL. Los alumnos pueden
# reactivar cualquier vista con clic derecho sobre el panel o la barra
# lateral.
STATE_DB="$HOME/.config/Code/User/globalStorage/state.vscdb"
if pgrep -x code >/dev/null 2>&1; then
    echo "   (VS Code está abierto: se omite ocultar OUTLINE/TIMELINE y pestañas del panel."
    echo "    Cerralo y volvé a correr el script para aplicar ese paso.)"
elif ! command -v sqlite3 >/dev/null 2>&1; then
    echo "   (falta sqlite3: sudo pacman -S sqlite — y volvé a correr el script)"
else
    mkdir -p "$(dirname "$STATE_DB")"
    sqlite3 "$STATE_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB);
INSERT OR REPLACE INTO ItemTable (key, value) VALUES
('workbench.explorer.views.state.hidden',
 '[{"id":"outline","isHidden":true},{"id":"timeline","isHidden":true},{"id":"workbench.explorer.openEditorsView","isHidden":true},{"id":"npm","isHidden":true}]'),
('workbench.panel.pinnedPanels',
 '[{"id":"workbench.panel.markers","pinned":false,"visible":false,"order":0},{"id":"workbench.panel.output","pinned":false,"visible":false,"order":1},{"id":"workbench.panel.repl","pinned":false,"visible":false,"order":2},{"id":"terminal","pinned":true,"visible":true,"order":3},{"id":"workbench.panel.testResults","pinned":false,"visible":false,"order":4},{"id":"~remote.forwardedPortsContainer","pinned":false,"visible":false,"order":5}]');
SQL
    ok "Vistas ocultadas: OUTLINE, TIMELINE y pestañas PROBLEMS/OUTPUT/DEBUG/PORTS"
fi

# ── 6. Herramientas de desarrollo (opcional) ──
if [ "$WITH_TOOLS" -eq 1 ]; then
    msg "Instalando herramientas de desarrollo (pide sudo)…"
    sudo pacman -S --needed --noconfirm \
        gcc clang gdb make valgrind python python-pip python-pipx sqlite git
    ok "Herramientas instaladas."
fi

# ── 7. Herramientas oficiales de CS50 (check50/style50/submit50) ──
# Autocorrección, estilo y entrega de los ejercicios oficiales de CS50.
# Van por pipx (sin sudo); pipx llega con --tools o con: sudo pacman -S python-pipx
if command -v pipx >/dev/null 2>&1; then
    # check50 3.4 se rompe con Python 3.14 → venvs con Python 3.13 propio
    for t in check50 style50 submit50; do
        command -v "$t" >/dev/null 2>&1 || { msg "Instalando $t con pipx (Python 3.13)…"; \
            pipx install --python 3.13 --fetch-python=missing "$t" >/dev/null; }
    done
    ok "check50, style50 y submit50 listos."
else
    echo "   (pipx no está: corré con --tools para tener también check50/style50/submit50)"
fi

echo
ok "Listo. Abrí VS Code con: code"
echo "   Layout CS50: explorador a la izquierda (Ctrl+B lo muestra/oculta),"
echo "   terminal abajo (Ctrl+\`), barra de menú oculta (Alt la muestra)."
