import * as vscode from 'vscode';

import type { BonsaiResult } from './cli_runner';

export function showWorkspacePanel(context: vscode.ExtensionContext, results: BonsaiResult[]): void {
  const panel = vscode.window.createWebviewPanel(
    'bonsaiWorkspaceAnalysis',
    'bonsai: Workspace Analysis',
    vscode.ViewColumn.One,
    {
      enableScripts: false,
      retainContextWhenHidden: true,
    },
  );

  panel.webview.html = buildHtml(results);
}

function buildHtml(results: BonsaiResult[]): string {
  const rows = results
    .map((result) => {
      const colorClass = result.band.toLowerCase();
      return `<tr class="${colorClass}"><td>${escapeHtml(result.file)}</td><td>${result.score}/100</td><td>${result.band}</td><td>${result.blastScore}</td><td>${(result.composability * 100).toFixed(0)}%</td><td>${result.contextDepth}</td></tr>`;
    })
    .join('');

  const passed = results.filter((result) => result.score >= 50).length;
  const failed = results.length - passed;

  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: sans-serif; padding: 16px; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
  th { background: #f3f3f3; }
  tr.green { background: #e9f7ef; }
  tr.yellow { background: #fff8e1; }
  tr.red { background: #fdecea; }
  .summary { margin-bottom: 12px; font-weight: 600; }
</style>
</head>
<body>
  <div class="summary">${results.length} files analysed. ${passed} passed. ${failed} failed.</div>
  <table>
    <thead>
      <tr><th>Filename</th><th>Score</th><th>Band</th><th>Blast Score</th><th>Composability</th><th>Context Depth</th></tr>
    </thead>
    <tbody>${rows}</tbody>
  </table>
</body>
</html>`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
