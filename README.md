# bonsai

> Prune your widget trees before your users feel them.

A static analysis tool for Flutter developers.
Measures what your linter ignores. Gives every screen a score. Works in CI.

**Work in progress.** Star to follow along.

## Status

The core metric engine is implemented and tested. The CLI is implemented and working from the terminal. The VS Code extension is under active development and is not finished yet.

## What Is Ready

- `bonsai_core`: parses Dart files and computes the health metrics.
- `bonsai_cli`: runs the analyzer from the terminal and prints pretty or JSON output.
- Basic fixture coverage for the core scoring and parser flow.

## What Is Still In Progress

- `bonsai_vscode`: the VS Code extension shell, hover UI, gutter decorations, and workspace panel are being developed.
- Runtime verification in the Extension Development Host is still being worked through.
- Some extension behaviors are not fully tested yet.

## Notes

- The CLI currently shells out to the `bonsai` command.
- The VS Code extension is intended to call the CLI and display its output in-editor.
- Not everything is production-ready yet; several pieces are still being refined and tested.
