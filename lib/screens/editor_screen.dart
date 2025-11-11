import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextItem {
  String text;
  Offset position;
  double fontSize;
  Color color;
  String fontFamily;
  FontWeight fontWeight;

  TextItem({
    required this.text,
    required this.position,
    required this.fontSize,
    required this.color,
    required this.fontFamily,
    required this.fontWeight,
  });

  TextItem copy() => TextItem(
    text: text,
    position: position,
    fontSize: fontSize,
    color: color,
    fontFamily: fontFamily,
    fontWeight: fontWeight,
  );
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<TextItem> _texts = [];
  int? _selectedIndex;
  Offset? _dragStartLocal;
  final int _historyLimit = 200;

  final List<List<TextItem>> _undoStack = [];
  final List<List<TextItem>> _redoStack = [];

  final List<String> _fonts = [
    'Poppins',
    'Roboto',
    'Lato',
    'Dancing Script',
    'Indie Flower'
  ];

  void _pushUndo({bool clearRedo = true}) {
    _undoStack.add(_texts.map((e) => e.copy()).toList());
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    if (clearRedo) _redoStack.clear();
  }

  void _addText() {
    final size = MediaQuery.of(context).size;
    _pushUndo();
    final offsetY = _texts.isEmpty
        ? size.height * 0.35
        : (_texts.last.position.dy + 48).clamp(80.0, size.height - 220.0);
    setState(() {
      _texts.add(TextItem(
        text: 'New Text',
        position: Offset(size.width * 0.28, offsetY),
        fontSize: 26,
        color: Colors.black,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ));
      _selectedIndex = _texts.length - 1;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _pushUndo(clearRedo: false);
    setState(() {
      final next = _redoStack.removeLast();
      _texts
        ..clear()
        ..addAll(next.map((e) => e.copy()));
      _selectedIndex = null;
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_texts.map((e) => e.copy()).toList());
    setState(() {
      final prev = _undoStack.removeLast();
      _texts
        ..clear()
        ..addAll(prev.map((e) => e.copy()));
      _selectedIndex = null;
    });
  }

  void _updateSelected(TextItem updated, {bool addHistory = true}) {
    if (_selectedIndex == null) return;
    if (addHistory) _pushUndo();
    setState(() {
      _texts[_selectedIndex!] = updated;
    });
  }

  Future<void> _editTextDialog(int index) async {
    final item = _texts[index];
    final controller = TextEditingController(text: item.text);
    double fontSize = item.fontSize;
    Color color = item.color;
    String fontFamily = item.fontFamily;
    FontWeight fontWeight = item.fontWeight;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Edit Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Size:'),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setModalState(() {
                          fontSize = (fontSize - 2).clamp(8.0, 200.0);
                        }),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(fontSize.toInt().toString()),
                      IconButton(
                        onPressed: () => setModalState(() {
                          fontSize = (fontSize + 2).clamp(8.0, 200.0);
                        }),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Font:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: fontFamily,
                        items: _fonts.map((f) => DropdownMenuItem(value: f,
                            child: Text(f))).toList(),
                        onChanged: (v) => setModalState(() => fontFamily = v ?? fontFamily),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Style:'),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setModalState(() =>
                        fontWeight = fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold),
                        icon: Icon(fontWeight == FontWeight.bold ? Icons.format_bold : Icons.format_bold_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(alignment: Alignment.centerLeft, child: Text('Color:')),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...[
                        Colors.black,
                        Colors.white,
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        const Color(0xFF6A11CB),
                        const Color(0xFF2575FC),
                      ].map((c) {
                        final selected = c.value == color.value;
                        return GestureDetector(
                          onTap: () => setModalState(() => color = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: selected ? Colors.black : Colors.grey.shade300,
                                  width: selected ? 2 : 1),
                            ),
                            child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        );
                      })
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  _pushUndo();
                  setState(() {
                    _texts[index] = TextItem(
                      text: controller.text.trim().isEmpty ? 'New Text' : controller.text.trim(),
                      position: item.position,
                      fontSize: fontSize,
                      color: color,
                      fontFamily: fontFamily,
                      fontWeight: fontWeight,
                    );
                    _selectedIndex = index;
                  });
                  Navigator.pop(ctx, true);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );

    (result == true);
  }

  @override
  void initState() {
    super.initState();
    _pushUndo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade700,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18),
                    blurRadius: 8, offset: const Offset(0, 3))],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Text('Text Canvas',
                      style: GoogleFonts.poppins(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Canvas
          Positioned.fill(
            top: 72 + 12,
            left: 14,
            right: 14,
            bottom: 92,
            child: Container(
              key: _canvasKey,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                    blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GuideLinesPainter()))),
                    ..._texts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        left: item.position.dx,
                        top: item.position.dy,
                        child: _DraggableTextWidget(
                          key: ValueKey('text_$i'),
                          item: item,
                          selected: _selectedIndex == i,
                          onTap: () {
                            setState(() => _selectedIndex = i);
                            _editTextDialog(i);
                          },
                          onStartDrag: (localInside) {
                            _dragStartLocal = localInside;
                            _selectedIndex = i;
                          },
                          onDragUpdateGlobal: (global) {
                            final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            final local = box.globalToLocal(global);
                            final newPos = Offset(
                              (local.dx - (_dragStartLocal?.dx ?? 0)).clamp(8.0, constraints.maxWidth - 12.0),
                              (local.dy - (_dragStartLocal?.dy ?? 0)).clamp(8.0, constraints.maxHeight - 12.0),
                            );
                            setState(() => _texts[i].position = newPos);
                          },
                          onDragEndGlobal: (global) {
                            final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            final local = box.globalToLocal(global);
                            Offset candidate = Offset(local.dx - (_dragStartLocal?.dx ?? 0),
                                local.dy - (_dragStartLocal?.dy ?? 0));
                            candidate = Offset(candidate.dx.clamp(8.0, constraints.maxWidth - 12.0),
                                candidate.dy.clamp(8.0, constraints.maxHeight - 12.0));
                            final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                            if ((candidate - center).distance <= 20) candidate = center;
                            setState(() {
                              _texts[i].position = candidate;
                              _pushUndo();
                              _dragStartLocal = null;
                            });
                          },
                          onUpdateItem: (updated) {
                            _updateSelected(updated);
                          },
                        ),
                      );
                    }).toList(),
                    if (_selectedIndex != null)
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: _buildBottomToolbar(_texts[_selectedIndex!]),
                      ),
                  ],
                );
              }),
            ),
          ),

          // Bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _redo,
                  icon: const Icon(Icons.redo, color: Colors.white),
                  label: const Text('Redo', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.28),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addText,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Text +', style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo, color: Colors.white),
                  label: const Text('Undo', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.28),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBottomToolbar(TextItem selected) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white.withOpacity(0.12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selected.fontFamily,
                  items: _fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.getFont(f)))).toList(),
                  onChanged: (v) {
                    if (v != null) _updateSelected(TextItem(
                      text: selected.text,
                      position: selected.position,
                      fontSize: selected.fontSize,
                      color: selected.color,
                      fontFamily: v,
                      fontWeight: selected.fontWeight,
                    ));
                  },
                ),
                const SizedBox(width: 12),
                _SizeControl(
                  size: selected.fontSize.toInt(),
                  onIncrease: () => _updateSelected(TextItem(
                    text: selected.text,
                    position: selected.position,
                    fontSize: (selected.fontSize + 2).clamp(8.0, 200.0),
                    color: selected.color,
                    fontFamily: selected.fontFamily,
                    fontWeight: selected.fontWeight,
                  )),
                  onDecrease: () => _updateSelected(TextItem(
                    text: selected.text,
                    position: selected.position,
                    fontSize: (selected.fontSize - 2).clamp(8.0, 200.0),
                    color: selected.color,
                    fontFamily: selected.fontFamily,
                    fontWeight: selected.fontWeight,
                  )),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    final isBold = selected.fontWeight == FontWeight.bold;
                    _updateSelected(TextItem(
                      text: selected.text,
                      position: selected.position,
                      fontSize: selected.fontSize,
                      color: selected.color,
                      fontFamily: selected.fontFamily,
                      fontWeight: isBold ? FontWeight.normal : FontWeight.bold,
                    ));
                  },
                  icon: const Icon(Icons.format_bold),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () async {
                    final color = await showDialog<Color?>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Pick color"),
                        content: Wrap(
                          spacing: 8,
                          children: [
                            Colors.black,
                            Colors.white,
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            const Color(0xFF6A11CB),
                            const Color(0xFF2575FC),
                          ].map((c) => GestureDetector(
                            onTap: () => Navigator.pop(context, c),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300)),
                            ),
                          )).toList(),
                        ),
                      ),
                    );
                    if (color != null) {
                      _updateSelected(TextItem(
                        text: selected.text,
                        position: selected.position,
                        fontSize: selected.fontSize,
                        color: color,
                        fontFamily: selected.fontFamily,
                        fontWeight: selected.fontWeight,
                      ));
                    }
                  },
                  icon: const Icon(Icons.color_lens),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _SizeControl extends StatefulWidget {
  final int size;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _SizeControl({required this.size, required this.onIncrease,
    required this.onDecrease, super.key});

  @override
  State<_SizeControl> createState() => _SizeControlState();
}

class _SizeControlState extends State<_SizeControl> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6)),
                child: IconButton(onPressed: widget.onIncrease,
                    icon: const Icon(Icons.add)),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6)),
                child: IconButton(onPressed: widget.onDecrease,
                    icon: const Icon(Icons.remove)),
              ),
              const SizedBox(height: 6),
            ],
          ),
        TextButton(onPressed: () => setState(() => _open = !_open), child: Text('Size (${widget.size})')),
      ],
    );
  }
}

class _DraggableTextWidget extends StatefulWidget {
  final TextItem item;
  final bool selected;
  final VoidCallback onTap;
  final void Function(Offset localTouchOffset) onStartDrag;
  final void Function(Offset globalPosition) onDragUpdateGlobal;
  final void Function(Offset globalPosition) onDragEndGlobal;
  final void Function(TextItem updated) onUpdateItem;

  const _DraggableTextWidget({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onStartDrag,
    required this.onDragUpdateGlobal,
    required this.onDragEndGlobal,
    required this.onUpdateItem,
  });

  @override
  State<_DraggableTextWidget> createState() => _DraggableTextWidgetState();
}

class _DraggableTextWidgetState extends State<_DraggableTextWidget> {
  bool _isDragging = false;
  Offset? _lastGlobal;

  @override
  Widget build(BuildContext context) {
    final t = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onPanStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        widget.onStartDrag(local);
        _lastGlobal = details.globalPosition;
        setState(() => _isDragging = true);
      },
      onPanUpdate: (details) {
        _lastGlobal = details.globalPosition;
        widget.onDragUpdateGlobal(details.globalPosition);
      },
      onPanEnd: (details) {
        final fallback = _lastGlobal ?? Offset.zero;
        widget.onDragEndGlobal(fallback);
        setState(() => _isDragging = false);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isDragging ? 1.04 : 1.0,
        child: Container(
          padding: widget.selected ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4) : EdgeInsets.zero,
          decoration: widget.selected
              ? BoxDecoration(color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 8)])
              : null,
          child: Text(
            t.text,
            style: GoogleFonts.getFont(t.fontFamily,fontSize: t.fontSize,
                color: t.color, fontWeight: t.fontWeight),
          ),
        ),
      ),
    );
  }
}

class _GuideLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withOpacity(0.08)..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}