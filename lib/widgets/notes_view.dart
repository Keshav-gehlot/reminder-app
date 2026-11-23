import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Renders the lesson markup (see lessons.dart) as formatted text and diagrams.
class NotesView extends StatelessWidget {
  const NotesView({super.key, required this.markup, this.fontSize = 16});
  final String markup;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final lines = markup.trim().split('\n');
    var i = 0;
    while (i < lines.length) {
      final raw = lines[i];
      final line = raw.trim();
      if (line.isEmpty) {
        i++;
        continue;
      }
      if (line.startsWith('```')) {
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++;
        children.add(_CodeBlock(code.join('\n')));
        continue;
      }
      children.add(_block(line));
      i++;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _block(String line) {
    final body = TextStyle(fontSize: fontSize, height: 1.55, color: AppColors.ink);
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(line.substring(2),
            style: TextStyle(fontSize: fontSize + 3, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: fontSize * 0.55, right: 10),
            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(line.substring(2), style: body)),
        ]),
      );
    }
    final step = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
    if (step != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 10, top: 1),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Text(step.group(1)!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          Expanded(child: Text(step.group(2)!, style: body)),
        ]),
      );
    }
    if (line.startsWith('> ')) return _Callout(line.substring(2), warning: false, size: fontSize);
    if (line.startsWith('! ')) return _Callout(line.substring(2), warning: true, size: fontSize);

    final diagram = RegExp(r'^\[(\w+)\]\s*(.*)$').firstMatch(line);
    if (diagram != null) {
      final arg = diagram.group(2)!;
      Widget? d;
      switch (diagram.group(1)) {
        case 'flow':
          d = _FlowDiagram(arg.split('->').map((e) => e.trim()).toList());
          break;
        case 'array':
          d = _ArrayDiagram.parse(arg);
          break;
        case 'bytes':
          d = _BytesDiagram.parse(arg);
          break;
        case 'tree':
          d = _TreeDiagram(arg.split(',').map((e) => e.trim()).toList());
          break;
        case 'graph':
          d = _GraphDiagram(arg);
          break;
        case 'stack':
          d = _StackDiagram(arg.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList());
          break;
        case 'list':
          d = _ListDiagram(arg.split(',').map((e) => e.trim()).toList());
          break;
        case 'table':
          d = _TableDiagram(arg);
          break;
        case 'perm':
          d = _PermDiagram(arg.trim());
          break;
      }
      if (d != null) return _Figure(child: d);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(line, style: body));
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class _Callout extends StatelessWidget {
  const _Callout(this.text, {required this.warning, required this.size});
  final String text;
  final bool warning;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: size - 1, height: 1.5, color: AppColors.ink))),
      ]),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);
  final String code;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.codeBg, borderRadius: BorderRadius.circular(14)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: Color(0xFFE6E8F2))),
        ),
      );
}

class _FlowDiagram extends StatelessWidget {
  const _FlowDiagram(this.steps);
  final List<String> steps;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final first = i == 0, last = i == steps.length - 1;
      items.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: first ? AppColors.primary : (last ? AppColors.successSoft : AppColors.primarySoft),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(steps[i],
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: first ? Colors.white : AppColors.ink)),
      ));
      if (!last) {
        items.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: Icon(Icons.arrow_downward_rounded, size: 20, color: AppColors.muted),
        ));
      }
    }
    return Column(children: items);
  }
}

class _ArrayDiagram extends StatelessWidget {
  const _ArrayDiagram(this.values, this.pointers, this.hlFrom, this.hlTo);
  final List<String> values;
  final Map<int, String> pointers;
  final int hlFrom, hlTo;

  static _ArrayDiagram parse(String arg) {
    final parts = arg.split('|').map((e) => e.trim()).toList();
    final values = parts[0].split(',').map((e) => e.trim()).toList();
    final pointers = <int, String>{};
    if (parts.length > 1 && parts[1].isNotEmpty) {
      for (final p in parts[1].split(',')) {
        final kv = p.split(':');
        final idx = int.tryParse(kv[0].trim());
        if (idx != null && kv.length > 1) {
          pointers[idx] = pointers.containsKey(idx) ? '${pointers[idx]}/${kv[1].trim()}' : kv[1].trim();
        }
      }
    }
    var from = -1, to = -1;
    if (parts.length > 2) {
      final r = parts[2].split('-');
      from = int.tryParse(r[0].trim()) ?? -1;
      to = r.length > 1 ? int.tryParse(r[1].trim()) ?? from : from;
    }
    return _ArrayDiagram(values, pointers, from, to);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(children: [
              Text('$i', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 3),
              Container(
                width: 48,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i >= hlFrom && i <= hlTo ? AppColors.primarySoft : Colors.white,
                  border: Border.all(
                      color: i >= hlFrom && i <= hlTo ? AppColors.primary : AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(values[i],
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: pointers.containsKey(i)
                    ? Column(children: [
                        const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.accent),
                        Text(pointers[i]!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      ])
                    : null,
              ),
            ]),
          ),
      ]),
    );
  }
}

class _BytesDiagram extends StatelessWidget {
  const _BytesDiagram(this.bytes, this.caption);
  final List<String> bytes;
  final String caption;
  static _BytesDiagram parse(String arg) {
    final parts = arg.split('|');
    return _BytesDiagram(parts[0].trim().split(RegExp(r'\s+')), parts.length > 1 ? parts[1].trim() : '');
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 4, runSpacing: 4, children: [
          for (final b in bytes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: AppColors.codeBg, borderRadius: BorderRadius.circular(6)),
              child: Text(b,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF9EE6B8))),
            ),
        ]),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ]);
}

class _StackDiagram extends StatelessWidget {
  const _StackDiagram(this.items);
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final rev = items.reversed.toList();
    return Center(
      child: Column(children: [
        for (var i = 0; i < rev.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 120,
              height: 40,
              margin: const EdgeInsets.only(bottom: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(rev[i],
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: i == 0 ? Colors.white : AppColors.ink)),
            ),
            SizedBox(
              width: 52,
              child: i == 0
                  ? const Text('  ← top', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent))
                  : null,
            ),
          ]),
        Container(width: 140, height: 3, color: AppColors.muted),
      ]),
    );
  }
}

class _ListDiagram extends StatelessWidget {
  const _ListDiagram(this.items);
  final List<String> items;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final v in items) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                Container(
                  width: 22,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(9)),
                  ),
                  child: const Icon(Icons.circle, size: 7, color: AppColors.primary),
                ),
              ]),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.muted),
          ],
          const Text('null', style: TextStyle(fontFamily: 'monospace', color: AppColors.muted)),
        ]),
      );
}

class _TableDiagram extends StatelessWidget {
  const _TableDiagram(this.spec);
  final String spec;
  @override
  Widget build(BuildContext context) {
    final rows = spec.split(';').map((r) => r.split('|').map((c) => c.trim()).toList()).toList();
    final cols = rows.map((r) => r.length).reduce(math.max);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(horizontalInside: BorderSide(color: AppColors.line)),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: r == 0
                  ? BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8))
                  : null,
              children: [
                for (var c = 0; c < cols; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Text(c < rows[r].length ? rows[r][c] : '',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: r == 0 ? FontWeight.w800 : FontWeight.w500,
                            color: AppColors.ink)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PermDiagram extends StatelessWidget {
  const _PermDiagram(this.perm);
  final String perm;
  @override
  Widget build(BuildContext context) {
    if (perm.length < 10) return Text(perm);
    final groups = [
      ('type', perm.substring(0, 1), AppColors.muted),
      ('owner', perm.substring(1, 4), AppColors.primary),
      ('group', perm.substring(4, 7), AppColors.accent),
      ('others', perm.substring(7, 10), AppColors.success),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: g.$3.withValues(alpha: 0.12),
                  border: Border.all(color: g.$3, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(g.$2,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w800, color: g.$3)),
              ),
              const SizedBox(height: 4),
              Text(g.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ]),
          ),
      ],
    );
  }
}

class _TreeDiagram extends StatelessWidget {
  const _TreeDiagram(this.nodes);
  final List<String> nodes;
  @override
  Widget build(BuildContext context) {
    var depth = 0;
    while ((1 << (depth + 1)) - 1 < nodes.length) {
      depth++;
    }
    return SizedBox(
      height: (depth + 1) * 64.0,
      child: CustomPaint(painter: _TreePainter(nodes, depth), size: Size.infinite),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.nodes, this.depth);
  final List<String> nodes;
  final int depth;

  Offset _pos(int i, Size size) {
    final level = (math.log(i + 1) / math.ln2).floor();
    final first = (1 << level) - 1;
    final count = 1 << level;
    final x = size.width * ((i - first) + 0.5) / count;
    final y = 24 + level * 62.0;
    return Offset(x, y);
  }

  bool _present(int i) => i < nodes.length && nodes[i] != 'null' && nodes[i].isNotEmpty;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = AppColors.line
      ..strokeWidth = 2;
    for (var i = 0; i < nodes.length; i++) {
      if (!_present(i)) continue;
      for (final c in [2 * i + 1, 2 * i + 2]) {
        if (_present(c)) canvas.drawLine(_pos(i, size), _pos(c, size), edge);
      }
    }
    for (var i = 0; i < nodes.length; i++) {
      if (!_present(i)) continue;
      final p = _pos(i, size);
      final tp = TextPainter(
        text: TextSpan(
            text: nodes[i],
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: i == 0 ? Colors.white : AppColors.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = math.max(38.0, tp.width + 18);
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: w, height: 36), const Radius.circular(18));
      canvas.drawRRect(rect, Paint()..color = i == 0 ? AppColors.primary : AppColors.primarySoft);
      canvas.drawRRect(
          rect,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter old) => old.nodes != nodes;
}

class _GraphDiagram extends StatelessWidget {
  const _GraphDiagram(this.spec);
  final String spec;
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 210, child: CustomPaint(painter: _GraphPainter(spec), size: Size.infinite));
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.spec);
  final String spec;

  @override
  void paint(Canvas canvas, Size size) {
    final edges = spec
        .split(',')
        .map((e) => e.trim().split('-').map((v) => v.trim()).toList())
        .where((e) => e.length == 2)
        .toList();
    final vertices = <String>[];
    for (final e in edges) {
      for (final v in e) {
        if (!vertices.contains(v)) vertices.add(v);
      }
    }
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 26;
    final pos = <String, Offset>{};
    for (var i = 0; i < vertices.length; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / vertices.length;
      pos[vertices[i]] = center + Offset(math.cos(a) * r, math.sin(a) * r);
    }
    final edge = Paint()
      ..color = AppColors.line
      ..strokeWidth = 2;
    for (final e in edges) {
      canvas.drawLine(pos[e[0]]!, pos[e[1]]!, edge);
    }
    for (var i = 0; i < vertices.length; i++) {
      final p = pos[vertices[i]]!;
      canvas.drawCircle(p, 20, Paint()..color = i == 0 ? AppColors.primary : AppColors.primarySoft);
      canvas.drawCircle(
          p,
          20,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      final tp = TextPainter(
        text: TextSpan(
            text: vertices[i],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: i == 0 ? Colors.white : AppColors.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.spec != spec;
}
