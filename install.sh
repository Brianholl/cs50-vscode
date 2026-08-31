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
#   ./install.sh              instalación estándar (incluye Java y Python)
#   ./install.sh --extra      además: Docker y Live Share
#   ./install.sh --tools      además: gcc, clang, gdb, python, java (JDK), sqlite, etc.
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
# marketplace, más Java y Python como lenguajes de primera clase (a la par
# de C). Las extensiones propias de CS50 (ddb50, style50, design50,
# explain50) son .vsix privados del contenedor y no se pueden instalar.
CORE_EXTENSIONS=(
    github.github-vscode-theme          # theme GitHub Dark/Light Default
    ms-python.python
    ms-python.autopep8                  # formateador Python de CS50
    ms-vscode.cpptools                  # C/C++ con clang-format estilo CS50
    redhat.java                         # Java: Language Support for Java(TM) by Red Hat
    vscjava.vscode-java-debug           # Java: debugger
    ms-vscode.hexeditor
    mathematic.vscode-pdf
    inferrinizzard.prettier-sql-vscode
    ms-ceintl.vscode-language-pack-es   # interfaz en español
    bitlang.cobol                       # COBOL: resaltado + snippets
)

EXTRA_EXTENSIONS=(
    ms-azuretools.vscode-docker
    ms-vsliveshare.vsliveshare          # colaboración en vivo entre alumnos
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
# Java del contenedor) y con cuatro ajustes para escritorio: tema oscuro
# fijo, barra de actividad oculta, barra de menú en modo toggle (Alt la
# muestra) y python.defaultInterpreterPath fijo — sin esto, F5 sobre un
# .py suelto (sin venv/proyecto) se queda pidiendo elegir un entorno vía
# la extensión ms-python.vscode-python-envs (dependencia de ms-python.python
# desde 2024) y nunca llega a correr nada.
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

    "python.defaultInterpreterPath": "/usr/bin/python3",
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
# OJO: NO alcanza con copiar la carpeta a ~/.vscode/extensions/. VS Code usa
# extensions.json de ese directorio como registro, y una extensión copiada a
# mano DESPUÉS de que ese archivo existe (lo crea la sección 2 al instalar las
# del marketplace) queda invisible: no carga y la terminal no aparece. Hay que
# empaquetarla como .vsix e instalarla con --install-extension, como cualquier
# otra. Verificado en perfil limpio: copiada a mano no carga, como .vsix sí.
EXT_DIR="$(mktemp -d)/terminal-abajo"
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

if command -v python3 >/dev/null 2>&1; then
    VSIX="$EXT_DIR/../terminal-abajo.vsix"
    python3 - "$EXT_DIR" "$VSIX" << 'MK_VSIX'
import os, sys, zipfile

src, out = sys.argv[1], sys.argv[2]
manifest = '''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="terminal-abajo" Version="1.0.0" Publisher="cs50-taller"/>
    <DisplayName>Terminal abajo (estilo CS50)</DisplayName>
    <Description>Abre la terminal integrada en el panel inferior al iniciar</Description>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
'''
ctypes = '''<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json"/>
  <Default Extension="js" ContentType="application/javascript"/>
  <Default Extension="vsixmanifest" ContentType="text/xml"/>
</Types>
'''
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("extension.vsixmanifest", manifest)
    z.writestr("[Content_Types].xml", ctypes)
    for f in ("package.json", "extension.js"):
        z.write(os.path.join(src, f), "extension/" + f)
MK_VSIX
    if code --install-extension "$VSIX" --force >/dev/null 2>&1; then
        ok "Extensión 'terminal-abajo' instalada (terminal abajo al iniciar)"
    else
        echo "   (falló instalar terminal-abajo; la terminal se abre igual con Ctrl+\`)"
    fi
    rm -rf "$(dirname "$EXT_DIR")"
else
    echo "   (falta python3: no se pudo empaquetar terminal-abajo. La terminal"
    echo "    se abre a mano con Ctrl+\` — instalá python y volvé a correr el script.)"
fi

# ── 4bis. Extensión de Oracle (metalenguaje de medidas) ──
# Resaltado, diagnósticos y completado para `.oracle` y `.caso`. Habla el
# protocolo LSP a mano contra ~/Dev/oracle/tools/lsp.py: el MISMO servidor que
# usa emacs50, así que ningún diagnóstico se reimplementa acá.
#
# Sin dependencias de npm a propósito: el .vsix se arma con python+zipfile igual
# que `terminal-abajo`, para que el taller siga siendo un solo archivo copiable
# por USB. Traer `vscode-languageclient` obligaría a npm y a vsce en cada máquina.
#
# Si ~/Dev/oracle no está clonado, la extensión avisa una vez y no molesta más.
if command -v python3 >/dev/null 2>&1; then
    ORACLE_DIR="$(mktemp -d)/oracle-lenguaje"
    mkdir -p "$ORACLE_DIR"

cat > "$ORACLE_DIR/package.json" << 'ORACLE_PKG'
{
    "name": "oracle-lenguaje",
    "displayName": "Oracle (metalenguaje de medidas)",
    "description": "Resaltado, diagnósticos y completado para .oracle y .caso",
    "publisher": "cs50-taller",
    "version": "1.0.1",
    "engines": {
        "vscode": "^1.75.0"
    },
    "main": "./extension.js",
    "activationEvents": [
        "onLanguage:oracle"
    ],
    "contributes": {
        "languages": [
            {
                "id": "oracle",
                "aliases": [
                    "Oracle"
                ],
                "extensions": [
                    ".oracle",
                    ".caso"
                ],
                "configuration": "./lenguaje.json"
            }
        ],
        "grammars": [
            {
                "language": "oracle",
                "scopeName": "source.oracle",
                "path": "./oracle.tmLanguage.json"
            }
        ]
    }
}
ORACLE_PKG

cat > "$ORACLE_DIR/lenguaje.json" << 'ORACLE_LANG'
{
    "comments": { "lineComment": "#" },
    "brackets": [["(", ")"], ["[", "]"]],
    "autoClosingPairs": [["(", ")"], ["\"", "\""]],
    "indentationRules": {
        "increaseIndentPattern": ":\\s*$",
        "decreaseIndentPattern": "^\\s*$"
    }
}
ORACLE_LANG

cat > "$ORACLE_DIR/oracle.tmLanguage.json" << 'ORACLE_GRAM'
{
    "$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
    "name": "Oracle",
    "scopeName": "source.oracle",
    "fileTypes": ["oracle", "caso"],
    "patterns": [
        { "match": "#.*$", "name": "comment.line.number-sign.oracle" },

        { "comment": "Encabezado: `ninguno dominio.nombre:` — la forma y el id de la medida",
          "match": "^(medida|ninguno|ninguno-par|ninguno-requiere|peor|defmacro|caso|relacion)\\s+([\\w.-]+)",
          "captures": {
            "1": { "name": "storage.type.oracle" },
            "2": { "name": "entity.name.function.oracle" } } },

        { "comment": "Los cinco operadores del álgebra, más las cláusulas obligatorias",
          "match": "^\\s*(de|donde|unir|agrupar|resumen|umbral|requiere|alcance|clave|agregado|evidencia|leccion|sintoma|origen|titulo)\\b",
          "name": "keyword.control.oracle" },

        { "comment": "`porque` y `segun` viajan dentro de la línea del umbral",
          "match": "\\b(porque|segun)\\b", "name": "keyword.control.oracle" },

        { "comment": "Conjuntos cerrados: si escribís uno que no existe, no se pinta",
          "match": "\\b(medicion|contrato|convencion|tanteo|observada|construida|generada|sin_declarar|falso_verde|falso_rojo|verde_correcto|deuda_de_dise\u00f1o|medida_correcta_conclusion_errada|mutacion|persona|accidente|herramienta_ajena|observacion|sin_unidad|adimensional)\\b",
          "name": "constant.language.oracle" },

        { "match": "\\b(contar|suma|max|min|promedio)\\b", "name": "support.function.oracle" },

        { "comment": "Acceso a campo: el alias apagado, el campo encendido",
          "match": "\\b([a-z_][\\w]*)\\.([a-z_][\\w]*)\\b",
          "captures": { "1": { "name": "variable.parameter.oracle" },
                        "2": { "name": "variable.other.property.oracle" } } },

        { "match": "\\$[\\w]+", "name": "variable.language.oracle" },
        { "begin": "\"", "end": "\"", "name": "string.quoted.double.oracle",
          "patterns": [{ "match": "`[^`]*`", "name": "markup.inline.raw.oracle" }] },
        { "match": "\\b\\d+(\\.\\d+)?\\b", "name": "constant.numeric.oracle" },
        { "match": "(<=|>=|==|!=|<|>)", "name": "keyword.operator.comparison.oracle" },
        { "match": "\\b(y|o|no|true|false|null)\\b", "name": "keyword.other.oracle" }
    ]
}
ORACLE_GRAM

cat > "$ORACLE_DIR/extension.js" << 'ORACLE_JS'
// Cliente mínimo del servidor LSP de Oracle, sin dependencias de npm.
//
// El protocolo se habla a mano —cabeceras `Content-Length` y JSON— en vez de usar
// `vscode-languageclient`. El motivo no es purismo: el instalador arma el .vsix con
// Python y zipfile, sin `npm` ni `vsce`, para que el taller siga siendo un solo
// archivo copiable por USB. Traer una dependencia rompería eso.
//
// Y el servidor es el MISMO que usa Emacs: acá no se reimplementa ningún
// diagnóstico. Duplicar la traducción de errores sería el defecto que este
// proyecto persigue.
const vscode = require('vscode');
const { spawn } = require('child_process');
const path = require('path');

let servidor = null, pendientes = new Map(), siguienteId = 1, buffer = Buffer.alloc(0);
let diagnosticos = null;

function rutaDelServidor() {
    return path.join(process.env.HOME || '', 'Dev', 'oracle', 'tools', 'lsp.py');
}

function enviar(mensaje) {
    if (!servidor) return;
    const cuerpo = Buffer.from(JSON.stringify({ jsonrpc: '2.0', ...mensaje }), 'utf8');
    servidor.stdin.write(`Content-Length: ${cuerpo.length}\r\n\r\n`);
    servidor.stdin.write(cuerpo);
}

function pedir(method, params) {
    const id = siguienteId++;
    return new Promise((resolve) => {
        pendientes.set(id, resolve);
        enviar({ id, method, params });
        setTimeout(() => { if (pendientes.delete(id)) resolve(null); }, 5000);
    });
}

// Un mensaje puede llegar partido en varios `data`, y varios mensajes pueden llegar
// juntos en uno solo. Sin este bucle el cliente anda en las pruebas y falla con un
// archivo grande, que es la peor forma de fallar.
function alRecibir(trozo) {
    buffer = Buffer.concat([buffer, trozo]);
    for (;;) {
        const corte = buffer.indexOf('\r\n\r\n');
        if (corte < 0) return;
        const cabeceras = buffer.subarray(0, corte).toString('utf8');
        const largo = /Content-Length: (\d+)/i.exec(cabeceras);
        if (!largo) return;
        const desde = corte + 4, hasta = desde + Number(largo[1]);
        if (buffer.length < hasta) return;
        let mensaje = null;
        try { mensaje = JSON.parse(buffer.subarray(desde, hasta).toString('utf8')); } catch (e) { /* se descarta */ }
        buffer = buffer.subarray(hasta);
        if (!mensaje) continue;
        if (mensaje.id !== undefined && pendientes.has(mensaje.id)) {
            pendientes.get(mensaje.id)(mensaje.result);
            pendientes.delete(mensaje.id);
        } else if (mensaje.method === 'textDocument/publishDiagnostics') {
            publicar(mensaje.params);
        }
    }
}

function publicar(params) {
    if (!diagnosticos) return;
    const uri = vscode.Uri.parse(params.uri);
    diagnosticos.set(uri, (params.diagnostics || []).map((d) => {
        const r = d.range;
        const diag = new vscode.Diagnostic(
            new vscode.Range(r.start.line, r.start.character, r.end.line, r.end.character),
            d.message,
            d.severity === 1 ? vscode.DiagnosticSeverity.Error : vscode.DiagnosticSeverity.Warning);
        diag.source = 'oracle';
        return diag;
    }));
}

function abrir(doc) {
    if (doc.languageId !== 'oracle') return;
    enviar({ method: 'textDocument/didOpen', params: { textDocument: {
        uri: doc.uri.toString(), languageId: 'oracle', version: doc.version, text: doc.getText() } } });
}

function activate(contexto) {
    diagnosticos = vscode.languages.createDiagnosticCollection('oracle');
    contexto.subscriptions.push(diagnosticos);

    servidor = spawn('python3', [rutaDelServidor()], { stdio: ['pipe', 'pipe', 'pipe'] });
    servidor.on('error', () => {
        vscode.window.showWarningMessage(
            'Oracle: no se pudo iniciar ' + rutaDelServidor() + '. ¿Está clonado ~/Dev/oracle?');
        servidor = null;
    });
    servidor.stdout.on('data', alRecibir);

    enviar({ id: siguienteId++, method: 'initialize', params: {
        processId: process.pid,
        rootUri: vscode.workspace.workspaceFolders?.[0]?.uri.toString() ?? null,
        capabilities: {} } });
    enviar({ method: 'initialized', params: {} });

    contexto.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(abrir),
        vscode.workspace.onDidSaveTextDocument(abrir),
        vscode.workspace.onDidChangeTextDocument((e) => abrir(e.document)));
    vscode.workspace.textDocuments.forEach(abrir);

    contexto.subscriptions.push(vscode.languages.registerCompletionItemProvider('oracle', {
        async provideCompletionItems(doc, pos) {
            abrir(doc);
            const r = await pedir('textDocument/completion', {
                textDocument: { uri: doc.uri.toString() },
                position: { line: pos.line, character: pos.character } });
            const items = Array.isArray(r) ? r : (r && r.items) || [];
            return items.map((i) => {
                const it = new vscode.CompletionItem(i.label, vscode.CompletionItemKind.Field);
                // `detail` es donde viaja la UNIDAD del campo: `flotante · cm`. Es lo que ningún
                // otro editor muestra, y la razón de que este completado valga la pena.
                if (i.detail) it.detail = i.detail;
                if (i.documentation) it.documentation = i.documentation;
                return it;
            });
        }
    }, '.', ' '));
}

function deactivate() { if (servidor) servidor.kill(); }

module.exports = { activate, deactivate };
ORACLE_JS

    ORACLE_VSIX="$ORACLE_DIR/../oracle-lenguaje.vsix"
    python3 - "$ORACLE_DIR" "$ORACLE_VSIX" << 'MK_ORACLE_VSIX'
import os, sys, zipfile

src, out = sys.argv[1], sys.argv[2]
manifest = '''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="oracle-lenguaje" Version="1.0.1" Publisher="cs50-taller"/>
    <DisplayName>Oracle (metalenguaje de medidas)</DisplayName>
    <Description>Resaltado, diagnosticos y completado para .oracle y .caso</Description>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
'''
ctypes = '''<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="json" ContentType="application/json"/>
  <Default Extension="js" ContentType="application/javascript"/>
  <Default Extension="vsixmanifest" ContentType="text/xml"/>
</Types>
'''
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("extension.vsixmanifest", manifest)
    z.writestr("[Content_Types].xml", ctypes)
    for f in sorted(os.listdir(src)):
        if os.path.isfile(os.path.join(src, f)):
            z.write(os.path.join(src, f), "extension/" + f)
MK_ORACLE_VSIX
    if code --install-extension "$ORACLE_VSIX" --force >/dev/null 2>&1; then
        ok "Extensión 'oracle-lenguaje' instalada (.oracle y .caso)"
        echo "   (si VS Code está abierto: Ctrl+Shift+P → Developer: Reload Window)"
        [ -f "$HOME/Dev/oracle/tools/lsp.py" ] \
            || echo "   (nota: ~/Dev/oracle no está clonado; el resaltado anda, los diagnósticos no)"
    else
        echo "   (falló instalar oracle-lenguaje)"
    fi
    rm -rf "$(dirname "$ORACLE_DIR")"
fi

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
        gcc clang gdb make valgrind python python-pip python-pipx jdk-openjdk sqlite git
    ok "Herramientas instaladas."

    # GnuCOBOL (cobc) — compilador COBOL. No está en los repos oficiales,
    # solo en AUR; compila a C y linkea con gcc (recién instalado arriba).
    # Va acá, con el resto de los compiladores del taller.
    if command -v cobc >/dev/null 2>&1 || pacman -Q gnucobol >/dev/null 2>&1; then
        ok "GnuCOBOL ya instalado: $(cobc --version 2>/dev/null | head -1)"
    else
        AUR_HELPER=""
        for h in paru yay; do
            command -v "$h" >/dev/null 2>&1 && { AUR_HELPER="$h"; break; }
        done
        if [ -n "$AUR_HELPER" ]; then
            msg "Instalando gnucobol desde AUR con $AUR_HELPER…"
            "$AUR_HELPER" -S --needed --noconfirm gnucobol \
                && ok "GnuCOBOL instalado (compilá con: cobc -x hola.cob && ./hola)" \
                || echo "   (falló gnucobol; reintentá con: $AUR_HELPER -S gnucobol)"
        else
            echo "   (sin paru/yay: no se pudo instalar gnucobol. Instalalo con: paru -S gnucobol)"
        fi
    fi
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

# ── 8. Carpeta de trabajo + lanzador que la abre ──
# CRÍTICO: VS Code sin carpeta abierta NO muestra el explorador, y como acá
# la activity bar está oculta (look CS50) el alumno se queda sin ningún botón
# visible para abrirlo: pantalla vacía. cs50.dev no tiene el problema porque
# el codespace siempre arranca con una carpeta. Se replica eso: una carpeta
# del alumno + un lanzador de menú que la abre siempre.
WORK_DIR="$HOME/cs50"
mkdir -p "$WORK_DIR"
if [ ! -e "$WORK_DIR/hola.c" ]; then
    cat > "$WORK_DIR/hola.c" << 'HOLA_C'
#include <stdio.h>

int main(void)
{
    printf("hola, mundo\n");
}
HOLA_C
fi
if [ ! -e "$WORK_DIR/hola.java" ]; then
    cat > "$WORK_DIR/hola.java" << 'HOLA_JAVA'
public class hola {
    public static void main(String[] args) {
        System.out.println("hola, mundo");
    }
}
HOLA_JAVA
fi
if [ ! -e "$WORK_DIR/hola.cob" ]; then
    # Formato fijo clásico (el default de cobc): las divisiones en columna 8
    # (área A), las sentencias en columna 12 (área B). Es el COBOL que se ve
    # en producción; se compila con: cobc -x hola.cob
    cat > "$WORK_DIR/hola.cob" << 'HOLA_COB'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. hola.
       PROCEDURE DIVISION.
           DISPLAY "hola, mundo".
           STOP RUN.
HOLA_COB
fi

APP_DIR="$HOME/.local/share/applications"
mkdir -p "$APP_DIR"
cat > "$APP_DIR/cs50-code.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=VS Code (CS50)
Comment=Editor del taller, abre la carpeta de trabajo $WORK_DIR
Exec=code --new-window $WORK_DIR
Icon=vscode
Categories=Development;IDE;
StartupNotify=true
DESKTOP
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
ok "Carpeta de trabajo $WORK_DIR + lanzador 'VS Code (CS50)' en el menú"

echo
ok "Listo. Abrí el editor desde el menú: 'VS Code (CS50)'"
echo "   (o desde una terminal, SIEMPRE con una carpeta: code ~/cs50)"
echo "   Ojo: 'code' a secas abre sin carpeta y no se ve el explorador."
echo "   Layout CS50: explorador a la izquierda (Ctrl+B lo muestra/oculta),"
echo "   terminal abajo (Ctrl+\`), barra de menú oculta (Alt la muestra)."
