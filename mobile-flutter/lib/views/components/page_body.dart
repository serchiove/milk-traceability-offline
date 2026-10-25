import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const PageBody({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: padding ?? AppSpacing.pagePadding,
        children: children,
      ),
    ),
  );
}
