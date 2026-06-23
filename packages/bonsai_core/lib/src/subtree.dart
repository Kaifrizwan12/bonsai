library subtree;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

int countWidgetsInSubtree(AstNode root) {
  final _CountingVisitor visitor = _CountingVisitor();
  root.accept(visitor);
  return visitor.count;
}

class _CountingVisitor extends RecursiveAstVisitor<void> {
  int count = 0;

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
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final String name = node.constructorName.type.name2.lexeme;
    if (name.isNotEmpty && name[0] == name[0].toUpperCase()) {
      count++;
    }
    _visitChildren(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String name = node.methodName.name;
    if (name.isNotEmpty && name[0] == name[0].toUpperCase()) {
      count++;
    }
    _visitChildren(node);
  }
}
