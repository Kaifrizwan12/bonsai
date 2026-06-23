library visitor;

import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'models.dart';
import 'composability.dart';
import 'scopes.dart';
import 'subtree.dart';

class BonsaiVisitor extends RecursiveAstVisitor<void> {
  final List<ScopeInfo> _scopes = [];
  int _currentDepth = 0;
  bool _inBuildMethod = false;
  int _leafCount = 0;
  int _extractedCount = 0;

  void _visitChildren(AstNode node) {
    node.visitChildren(this);
  }

  @override
  void visitArgumentList(ArgumentList node) => _visitChildren(node);

  @override
  void visitBlock(Block node) => _visitChildren(node);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) => _visitChildren(node);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      _visitChildren(node);

  @override
  void visitExpressionStatement(ExpressionStatement node) =>
      _visitChildren(node);

  @override
  void visitFunctionExpression(FunctionExpression node) => _visitChildren(node);

  @override
  void visitNamedExpression(NamedExpression node) => _visitChildren(node);

  @override
  void visitReturnStatement(ReturnStatement node) => _visitChildren(node);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build') {
      final bool previousInBuild = _inBuildMethod;
      final int previousDepth = _currentDepth;
      _inBuildMethod = true;
      _currentDepth = 0;
      _visitChildren(node);
      _inBuildMethod = previousInBuild;
      _currentDepth = previousDepth;
    } else {
      _visitChildren(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_inBuildMethod) {
      final String name = node.constructorName.type.name2.lexeme;
      if (kReactiveScopes.contains(name)) {
        final int count = countWidgetsInSubtree(node);
        _scopes.add(
          ScopeInfo(
            type: _scopeTypeFrom(name),
            line: node.offset,
            column: 0,
            widgetCount: count,
            nestingDepth: _currentDepth,
          ),
        );
        _currentDepth++;
        _visitChildren(node);
        _currentDepth--;
        return;
      }

      if (kLeafWidgets.contains(name)) {
        _leafCount++;
      } else if (!kReactiveScopes.contains(name) &&
          name.isNotEmpty &&
          name[0] == name[0].toUpperCase()) {
        _extractedCount++;
      }
    }

    _visitChildren(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String name = node.methodName.name;

    if (_inBuildMethod &&
        kReactiveScopes.contains(name) &&
        name.isNotEmpty &&
        name[0] == name[0].toUpperCase()) {
      final int count = countWidgetsInSubtree(node);
      _scopes.add(
        ScopeInfo(
          type: _scopeTypeFrom(name),
          line: node.offset,
          column: 0,
          widgetCount: count,
          nestingDepth: _currentDepth,
        ),
      );
      _currentDepth++;
      _visitChildren(node);
      _currentDepth--;
      return;
    }

    if (_inBuildMethod && kReactiveMethods.contains(name)) {
      if (node.argumentList.arguments.isNotEmpty) {
        final int count =
            countWidgetsInSubtree(node.argumentList.arguments.first);
        _scopes.add(
          ScopeInfo(
            type: ScopeType.setState,
            line: node.offset,
            column: 0,
            widgetCount: count,
            nestingDepth: _currentDepth,
          ),
        );
      }
    }

    if (_inBuildMethod) {
      if (kLeafWidgets.contains(name)) {
        _leafCount++;
      } else if (!kReactiveScopes.contains(name) &&
          name.isNotEmpty &&
          name[0] == name[0].toUpperCase()) {
        _extractedCount++;
      }
    }

    _visitChildren(node);
  }

  List<ScopeInfo> get scopes => List.unmodifiable(_scopes);

  int get leafWidgetCount => _leafCount;

  int get extractedWidgetCount => _extractedCount;

  double get composabilityRatio =>
      computeComposability(_leafCount, _extractedCount);

  int get maxBlastScore => _scopes.isEmpty
      ? 0
      : _scopes.map((ScopeInfo scope) => scope.widgetCount).reduce(max);

  ScopeType _scopeTypeFrom(String name) {
    switch (name) {
      case 'StreamBuilder':
        return ScopeType.streamBuilder;
      case 'Consumer':
      case 'Consumer2':
        return ScopeType.consumer;
      case 'BlocBuilder':
      case 'BlocConsumer':
        return ScopeType.blocBuilder;
      case 'ValueListenableBuilder':
        return ScopeType.valueListenable;
      case 'Selector':
        return ScopeType.selector;
      case 'FutureBuilder':
        return ScopeType.futureBuilder;
      case 'AnimatedBuilder':
        return ScopeType.animatedBuilder;
      default:
        return ScopeType.other;
    }
  }
}
