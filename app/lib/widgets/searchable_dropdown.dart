import 'package:flutter/material.dart';

class SearchableDropdown<T extends Object> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final InputDecoration? decoration;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.value,
    this.decoration,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T extends Object>
    extends State<SearchableDropdown<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _hasSelection = widget.value != null;
    _controller = TextEditingController(
      text: widget.value != null ? widget.labelBuilder(widget.value as T) : '',
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _hasSelection = widget.value != null;
      final text =
          widget.value != null ? widget.labelBuilder(widget.value as T) : '';
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  void _clear() {
    _controller.clear();
    _hasSelection = false;
    widget.onChanged(null);
    _focusNode.unfocus();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<T>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where(
              (item) => widget.labelBuilder(item).toLowerCase().contains(query),
            );
          },
          displayStringForOption: widget.labelBuilder,
          onSelected: (item) {
            setState(() => _hasSelection = true);
            widget.onChanged(item);
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: (widget.decoration ?? const InputDecoration()).copyWith(
                suffixIcon: _hasSelection
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clear,
                      )
                    : const Icon(Icons.arrow_drop_down),
              ),
              onChanged: (text) {
                if (text.isEmpty) {
                  setState(() => _hasSelection = false);
                  widget.onChanged(null);
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            widget.labelBuilder(option),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Public Sans',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
