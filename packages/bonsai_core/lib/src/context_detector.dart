library context_detector;

import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'models.dart';

class ContextCallDetector extends RecursiveAstVisitor<void> {
  final List<ContextCall> _calls = [];
  int _currentDepth = 0;
  bool _inBuildMethod = false;

  List<ContextCall> get calls => List.unmodifiable(_calls);

  int get maxDepth => _calls.isEmpty
      ? 0
      : _calls.map((ContextCall call) => call.nestingDepth).reduce(max);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build') {
      final bool previous = _inBuildMethod;
      final int previousDepth = _currentDepth;
      _inBuildMethod = true;
      _currentDepth = 0;
      node.visitChildren(this);
      _inBuildMethod = previous;
      _currentDepth = previousDepth;
    } else {
      node.visitChildren(this);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_inBuildMethod) {
      _currentDepth++;
      node.visitChildren(this);
      _currentDepth--;
      return;
    }

    node.visitChildren(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_inBuildMethod) {
      final String target = node.target?.toSource() ?? '';
      final String method = node.methodName.name;
      final bool isContextCall = target == 'context' &&
          (method == 'watch' || method == 'read' || method == 'select');
      final bool isProviderOf = target == 'Provider' && method == 'of';

      if (isContextCall) {
        _calls.add(
          ContextCall(
            callType: method,
            nestingDepth: _currentDepth,
            line: node.offset,
          ),
        );
      }

      if (isProviderOf) {
        _calls.add(
          ContextCall(
            callType: 'provider_of',
            nestingDepth: _currentDepth,
            line: node.offset,
          ),
        );
      }

      if (method.isNotEmpty && method[0] == method[0].toUpperCase()) {
        _currentDepth++;
        node.visitChildren(this);
        _currentDepth--;
        return;
      }
    }

    node.visitChildren(this);
  }
}
