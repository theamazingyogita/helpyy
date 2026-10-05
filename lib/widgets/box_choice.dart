import 'package:flutter/material.dart';

/// A row of square options where one is picked, like "Now / 5s / 10s".
class BoxChoice<T> extends StatelessWidget {
  const BoxChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      spacing: 8,
      children: [
        for (final option in options)
          Expanded(
            child: Semantics(
              selected: option == selected,
              button: true,
              child: InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == selected ? colorScheme.onSurface : null,
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Text(
                    labelOf(option),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: option == selected
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
