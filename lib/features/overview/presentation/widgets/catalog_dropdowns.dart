import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String formatBaht(double? value) {
  if (value == null) return '-';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

/// Searchable drop-down fed by a catalog provider. Calls [onSelected] and
/// clears itself so the next item can be picked straight away.
class CatalogDropdown<T> extends StatefulWidget {
  final String hint;
  final String emptyMessage;
  final AsyncValue<List<T>> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onSelected;

  const CatalogDropdown({
    super.key,
    required this.hint,
    required this.emptyMessage,
    required this.items,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  State<CatalogDropdown<T>> createState() => _CatalogDropdownState<T>();
}

class _CatalogDropdownState<T> extends State<CatalogDropdown<T>> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.items.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Text(
        'โหลดรายการจากคลินิกไม่สำเร็จ (ยังพิมพ์เพิ่มเองได้): $error',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            widget.emptyMessage,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<T>(
            controller: _controller,
            width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
            menuHeight: 320,
            enableFilter: true,
            requestFocusOnTap: true,
            leadingIcon: const Icon(Icons.search),
            hintText: widget.hint,
            dropdownMenuEntries: [
              for (final item in list)
                DropdownMenuEntry<T>(value: item, label: widget.labelOf(item)),
            ],
            onSelected: (value) {
              if (value == null) return;
              widget.onSelected(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _controller.clear();
              });
            },
          ),
        );
      },
    );
  }
}

Future<String?> showManualEntryDialog(
  BuildContext context, {
  required String title,
  required String label,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ManualEntryDialog(title: title, label: label),
  );
}

class _ManualEntryDialog extends StatefulWidget {
  final String title;
  final String label;

  const _ManualEntryDialog({required this.title, required this.label});

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('เพิ่ม')),
      ],
    );
  }
}
