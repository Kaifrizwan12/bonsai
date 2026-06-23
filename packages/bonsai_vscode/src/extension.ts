import * as vscode from 'vscode';

import { isBonsaiInstalled, runBonsai } from './cli_runner';
import type { BonsaiResult } from './cli_runner';
import { showWorkspacePanel } from './webview';

let statusBar: vscode.StatusBarItem | undefined;
let currentDecorations: {
  green: vscode.TextEditorDecorationType;
  yellow: vscode.TextEditorDecorationType;
  red: vscode.TextEditorDecorationType;
} | undefined;
let lastResult: BonsaiResult | null = null;

export async function activate(context: vscode.ExtensionContext): Promise<void> {
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

  const analyzeCurrentFile = async (editor: vscode.TextEditor): Promise<void> => {
    if (editor.document.languageId !== 'dart') {
      return;
    }

    if (!isBonsaiInstalled()) {
      statusBar!.text = '$(error) bonsai: not installed';
      statusBar!.tooltip = 'Run: dart pub global activate bonsai';
      return;
    }

    const result = await runBonsai(editor.document.fileName);
    if (!result) {
      return;
    }

    lastResult = result;
    clearDecorations(editor);

    const buildLineNumber = findBuildLine(editor.document);
    const decoration = { range: new vscode.Range(buildLineNumber, 0, buildLineNumber, 0) };

    if (result.band === 'GREEN') {
      editor.setDecorations(greenDot, [decoration]);
    } else if (result.band === 'YELLOW') {
      editor.setDecorations(yellowDot, [decoration]);
    } else {
      editor.setDecorations(redDot, [decoration]);
    }

    statusBar!.text = `$(pulse) bonsai: ${result.score}/100`;
    statusBar!.tooltip = 'Click to analyze workspace';
    statusBar!.backgroundColor = result.band === 'RED'
      ? new vscode.ThemeColor('statusBarItem.errorBackground')
      : undefined;
  };

  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(async (document) => {
      if (document.languageId !== 'dart') {
        return;
      }

      const editor = vscode.window.visibleTextEditors.find((visibleEditor) => visibleEditor.document === document);
      if (editor) {
        await analyzeCurrentFile(editor);
      }
    }),
  );

  context.subscriptions.push(
    vscode.languages.registerHoverProvider('dart', {
      async provideHover(document, position) {
        const line = document.lineAt(position.line).text;
        if (!line.includes('Widget build(')) {
          return null;
        }

        const result = lastResult && lastResult.file === document.fileName
          ? lastResult
          : await runBonsai(document.fileName);

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
    }),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('bonsai.analyzeWorkspace', async () => {
      const root = vscode.workspace.workspaceFolders?.[0];
      if (!root) {
        return;
      }

      const workspaceResult = await runWorkspaceAnalysis(root.uri.fsPath);
      showWorkspacePanel(context, workspaceResult);
    }),
  );

  if (vscode.window.activeTextEditor && vscode.window.activeTextEditor.document.languageId === 'dart') {
    void analyzeCurrentFile(vscode.window.activeTextEditor);
  }

  context.subscriptions.push(greenDot, yellowDot, redDot, statusBar);
}

export function deactivate(): void {
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

function clearDecorations(editor: vscode.TextEditor): void {
  if (!currentDecorations) {
    return;
  }

  editor.setDecorations(currentDecorations.green, []);
  editor.setDecorations(currentDecorations.yellow, []);
  editor.setDecorations(currentDecorations.red, []);
}

function findBuildLine(document: vscode.TextDocument): number {
  for (let lineNumber = 0; lineNumber < document.lineCount; lineNumber++) {
    if (document.lineAt(lineNumber).text.includes('Widget build(')) {
      return lineNumber;
    }
  }
  return 0;
}

async function runWorkspaceAnalysis(workspacePath: string): Promise<BonsaiResult[]> {
  const { spawn } = await import('child_process');
  return new Promise<BonsaiResult[]>((resolve) => {
    let command: ReturnType<typeof spawn>;
    try {
      command = spawn('bonsai', ['analyze', '--format', 'json', 'lib/'], {
        cwd: workspacePath,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (_) {
      resolve([]);
      return;
    }

    const timeout = setTimeout(() => {
      command.kill();
      resolve([]);
    }, 8000);

    let stdout = '';
    command.stdout?.on('data', (chunk: Buffer) => {
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
        resolve(Array.isArray(parsed) ? (parsed as BonsaiResult[]) : []);
      } catch (_) {
        resolve([]);
      }
    });
  });
}
