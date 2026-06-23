"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const cli_runner_1 = require("./cli_runner");
const webview_1 = require("./webview");
let statusBar;
let currentDecorations;
let lastResult = null;
async function activate(context) {
    const greenDot = vscode.window.createTextEditorDecorationType({
        gutterIconPath: context.asAbsolutePath('media/dot-green.svg'),
        gutterIconSize: 'contain',
    });
    const yellowDot = vscode.window.createTextEditorDecorationType({
        gutterIconPath: context.asAbsolutePath('media/dot-yellow.svg'),
        gutterIconSize: 'contain',
    });
    const redDot = vscode.window.createTextEditorDecorationType({
        gutterIconPath: context.asAbsolutePath('media/dot-red.svg'),
        gutterIconSize: 'contain',
    });
    currentDecorations = { green: greenDot, yellow: yellowDot, red: redDot };
    statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBar.text = '$(pulse) bonsai';
    statusBar.tooltip = 'Click to analyze workspace';
    statusBar.command = 'bonsai.analyzeWorkspace';
    statusBar.show();
    const analyzeCurrentFile = async (editor) => {
        if (editor.document.languageId !== 'dart') {
            return;
        }
        if (!(0, cli_runner_1.isBonsaiInstalled)()) {
            statusBar.text = '$(error) bonsai: not installed';
            statusBar.tooltip = 'Run: dart pub global activate bonsai';
            return;
        }
        const result = await (0, cli_runner_1.runBonsai)(editor.document.fileName);
        if (!result) {
            return;
        }
        lastResult = result;
        clearDecorations(editor);
        const buildLineNumber = findBuildLine(editor.document);
        const decoration = { range: new vscode.Range(buildLineNumber, 0, buildLineNumber, 0) };
        if (result.band === 'GREEN') {
            editor.setDecorations(greenDot, [decoration]);
        }
        else if (result.band === 'YELLOW') {
            editor.setDecorations(yellowDot, [decoration]);
        }
        else {
            editor.setDecorations(redDot, [decoration]);
        }
        statusBar.text = `$(pulse) bonsai: ${result.score}/100`;
        statusBar.tooltip = 'Click to analyze workspace';
        statusBar.backgroundColor = result.band === 'RED'
            ? new vscode.ThemeColor('statusBarItem.errorBackground')
            : undefined;
    };
    context.subscriptions.push(vscode.workspace.onDidSaveTextDocument(async (document) => {
        if (document.languageId !== 'dart') {
            return;
        }
        const editor = vscode.window.visibleTextEditors.find((visibleEditor) => visibleEditor.document === document);
        if (editor) {
            await analyzeCurrentFile(editor);
        }
    }));
    context.subscriptions.push(vscode.languages.registerHoverProvider('dart', {
        async provideHover(document, position) {
            const line = document.lineAt(position.line).text;
            if (!line.includes('Widget build(')) {
                return null;
            }
            const result = lastResult && lastResult.file === document.fileName
                ? lastResult
                : await (0, cli_runner_1.runBonsai)(document.fileName);
            if (!result) {
                return null;
            }
            lastResult = result;
            const markdown = new vscode.MarkdownString([
                '## bonsai health score',
                '',
                `**Score:** ${result.score}/100 [${result.band}]`,
                '',
                '| Metric | Value |',
                '|--------|-------|',
                `| Blast Score | ${result.blastScore} widgets |`,
                `| Composability | ${(result.composability * 100).toFixed(0)}% |`,
                `| Context Depth | ${result.contextDepth} |`,
                '',
                '**Suggestions:**',
                ...(result.suggestions.length > 0
                    ? result.suggestions.map((suggestion) => `- ${suggestion}`)
                    : ['- None']),
            ].join('\n'));
            markdown.isTrusted = false;
            return new vscode.Hover(markdown);
        },
    }));
    context.subscriptions.push(vscode.commands.registerCommand('bonsai.analyzeWorkspace', async () => {
        const root = vscode.workspace.workspaceFolders?.[0];
        if (!root) {
            return;
        }
        const workspaceResult = await runWorkspaceAnalysis(root.uri.fsPath);
        (0, webview_1.showWorkspacePanel)(context, workspaceResult);
    }));
    if (vscode.window.activeTextEditor && vscode.window.activeTextEditor.document.languageId === 'dart') {
        void analyzeCurrentFile(vscode.window.activeTextEditor);
    }
    context.subscriptions.push(greenDot, yellowDot, redDot, statusBar);
}
function deactivate() {
    if (currentDecorations) {
        currentDecorations.green.dispose();
        currentDecorations.yellow.dispose();
        currentDecorations.red.dispose();
        currentDecorations = undefined;
    }
    if (statusBar) {
        statusBar.dispose();
        statusBar = undefined;
    }
}
function clearDecorations(editor) {
    if (!currentDecorations) {
        return;
    }
    editor.setDecorations(currentDecorations.green, []);
    editor.setDecorations(currentDecorations.yellow, []);
    editor.setDecorations(currentDecorations.red, []);
}
function findBuildLine(document) {
    for (let lineNumber = 0; lineNumber < document.lineCount; lineNumber++) {
        if (document.lineAt(lineNumber).text.includes('Widget build(')) {
            return lineNumber;
        }
    }
    return 0;
}
async function runWorkspaceAnalysis(workspacePath) {
    const { spawn } = await Promise.resolve().then(() => __importStar(require('child_process')));
    return new Promise((resolve) => {
        let command;
        try {
            command = spawn('bonsai', ['analyze', '--format', 'json', 'lib/'], {
                cwd: workspacePath,
                stdio: ['ignore', 'pipe', 'pipe'],
            });
        }
        catch (_) {
            resolve([]);
            return;
        }
        const timeout = setTimeout(() => {
            command.kill();
            resolve([]);
        }, 8000);
        let stdout = '';
        command.stdout?.on('data', (chunk) => {
            stdout += chunk.toString();
        });
        command.on('error', () => {
            clearTimeout(timeout);
            resolve([]);
        });
        command.on('close', (code) => {
            clearTimeout(timeout);
            if (code === 2) {
                resolve([]);
                return;
            }
            try {
                const parsed = JSON.parse(stdout);
                resolve(Array.isArray(parsed) ? parsed : []);
            }
            catch (_) {
                resolve([]);
            }
        });
    });
}
//# sourceMappingURL=extension.js.map