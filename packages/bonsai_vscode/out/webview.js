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
exports.showWorkspacePanel = showWorkspacePanel;
const vscode = __importStar(require("vscode"));
function showWorkspacePanel(context, results) {
    const panel = vscode.window.createWebviewPanel('bonsaiWorkspaceAnalysis', 'bonsai: Workspace Analysis', vscode.ViewColumn.One, {
        enableScripts: false,
        retainContextWhenHidden: true,
    });
    panel.webview.html = buildHtml(results);
}
function buildHtml(results) {
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
function escapeHtml(value) {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}
//# sourceMappingURL=webview.js.map