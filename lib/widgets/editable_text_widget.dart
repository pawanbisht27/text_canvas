import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/text_item.dart';

class EditableTextWidget extends StatefulWidget {
  final TextItem item;
  final bool selected;
  final Function(TextItem) onUpdate;
  final VoidCallback onTapSelect;
  final VoidCallback onStartEdit;

  const EditableTextWidget({
    super.key,
    required this.item,
    required this.selected,
    required this.onUpdate,
    required this.onTapSelect,
    required this.onStartEdit,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant EditableTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _controller.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    widget.onStartEdit();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  void _stopEditing() {
    setState(() => _isEditing = false);
    widget.onUpdate(widget.item..text = _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapSelect,
      onDoubleTap: _startEditing,
      child: Container(
        decoration: widget.selected
            ? BoxDecoration(border: Border.all(color: Colors.blueAccent))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: _isEditing
            ? ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: IntrinsicWidth(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: GoogleFonts.getFont(
                widget.item.fontFamily,
                fontSize: widget.item.fontSize,
                color: widget.item.color,
                fontWeight: widget.item.fontWeight,
              ),
              decoration: const InputDecoration(border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero),
              maxLines: null,
              onSubmitted: (_) => _stopEditing(),
              onEditingComplete: _stopEditing,
              onChanged: (val) => widget.onUpdate(widget.item..text = val),
            ),
          ),
        )
            : Text(
          widget.item.text,
          style: GoogleFonts.getFont(
            widget.item.fontFamily,
            fontSize: widget.item.fontSize,
            color: widget.item.color,
            fontWeight: widget.item.fontWeight,
          ),
        ),
      ),
    );
  }
}