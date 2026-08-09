import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../widgets/add_forms.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Xodimlar moduli — jamoa a'zolari, oylik fond, YaIT va ro'yxat.
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText). PUSH ekran.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  Map<String, dynamic>? _snap;
  late Future<Map<String, dynamic>> _f = _load();

  Future<Map<String, dynamic>> _load() async {
    final d = await Api.employees();
    if (mounted) setState(() => _snap = d);
    return d;
  }

  Future<void> _refresh() async => setState(() {
        _snap = null;
        _f = _load();
      });

  /// Ismning bosh harflari (maks. 2 ta), bo'sh bo'lsa '—'.
  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  /// Yirik summani "18.6 mln" ko'rinishida, aks holda oddiy formatda.
  String _mln(num v) {
    if (v.abs() >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)} ${tr('emp.mln')}';
    }
    return money(v);
  }

  /// Monogram uchun (tint fon · matn rangi) juftligi — dizayndagi tartib.
  (Color, Color) _mono(FinnTokens t, int i) {
    switch (i % 5) {
      case 0:
        return (t.tBlu, t.blue);
      case 1:
        return (t.tPur, t.onPur);
      case 2:
        return (t.tTea, t.onTea);
      case 3:
        return (t.tAmb, t.onAmb);
      default:
        return (t.tGrn, t.onGrn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = (_snap?['employees'] as List?) ?? const [];
    final subtitle = _snap == null
        ? tr('emp.subtitle')
        : '${list.length} ${tr('emp.countWord')}';
    return FinnScreen(
      title: tr('emp.title'),
      subtitle: subtitle,
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
      actions: [
        _iconBtn(t, Icons.add_rounded, onTap: () async {
          if (await showAddEmployee(context)) _refresh();
        }),
      ],
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data ?? {};
            if (d['ok'] != true) return _err(t);
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final raw = (d['employees'] as List?) ?? const [];
    final employees = raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    if (employees.isEmpty) return _empty(t);

    final fond = employees.fold<double>(
        0, (a, e) => a + ((e['salary'] as num?)?.toDouble() ?? 0));
    final yait = fond * 0.12; // YaIT ~12%

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StaggerIn(
          index: 0,
          child: Row(children: [
            Expanded(
                child: _SumCard(
                    label: tr('emp.fund'),
                    value: _mln(fond),
                    meta: tr('emp.somMonth'))),
            const SizedBox(width: 10),
            Expanded(
                child: _SumCard(
                    label: tr('emp.yait'),
                    value: _mln(yait),
                    meta: tr('emp.somMonth'))),
          ]),
        ),
        StaggerIn(
            index: 1,
            child: _eyebrow(t, tr('emp.list'), trailing: tr('emp.filter'))),
        for (var i = 0; i < employees.length; i++)
          Builder(builder: (_) {
            final e = employees[i];
            final name = (e['name'] ?? '').toString();
            final position = trPosition((e['position'] ?? '').toString());
            final salary = (e['salary'] as num?)?.toDouble() ?? 0;
            final mono = _mono(t, i);
            return StaggerIn(
              index: i + 2,
              child: _EmployeeRow(
                name: name,
                position: position,
                salary: salary,
                initials: _initials(name),
                tint: mono.$1,
                accent: mono.$2,
              ),
            );
          }),
      ],
    );
  }

  Widget _empty(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Column(children: [
            Icon(Icons.groups_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('emp.empty'), style: FinnText.body(t.ink3)),
          ]),
        ),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('emp.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('emp.retry'))),
          ]),
        ),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  Widget _eyebrow(FinnTokens t, String label, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(trailing, style: FinnText.pill(t.blue).copyWith(fontSize: 12)),
          ],
        ]),
      );
}

/// Yig'indi kartasi (Oylik fond / YaIT).
class _SumCard extends StatelessWidget {
  final String label, value, meta;
  const _SumCard({required this.label, required this.value, required this.meta});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: FinnText.label(t.ink3)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: FinnText.bigValue(t.ink)
                  .copyWith(fontSize: 20, letterSpacing: -0.9)),
        ),
        const SizedBox(height: 8),
        Text(meta, style: FinnText.rowSub(t.ink3).copyWith(fontSize: 12)),
      ]),
    );
  }
}

/// Xodim qatori — monogram · ism/lavozim · oylik.
class _EmployeeRow extends StatelessWidget {
  final String name, position, initials;
  final double salary;
  final Color tint, accent;
  const _EmployeeRow({
    required this.name,
    required this.position,
    required this.salary,
    required this.initials,
    required this.tint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: FinnTokens.gapList),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(initials,
              style: FinnText.rowValue(accent).copyWith(fontSize: 12.5)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              name.isEmpty ? '—' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FinnText.rowTitle(t.ink),
            ),
            if (position.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                position,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowSub(t.ink3),
              ),
            ],
          ]),
        ),
        if (salary > 0) ...[
          const SizedBox(width: 10),
          Text(money(salary), style: FinnText.rowValue(t.ink)),
        ],
      ]),
    );
  }
}
