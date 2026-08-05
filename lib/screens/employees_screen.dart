import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Xodimlar moduli — jamoa a'zolari, oylik fond, YaIT va ro'yxat.
/// Dizayn: finn-app-full.html `#v-xodim`.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<Map<String, dynamic>> _f = Api.employees();
  Future<void> _refresh() async => setState(() => _f = Api.employees());

  /// Monogram ranglar aylanasi (dizayndagi tartib: blu · pur · tea · amb · grn).
  static const _palette = [C.blue, C.violet, C.teal, C.amber, C.green];

  Color _mColor(BuildContext c, int i) {
    switch (_palette[i % _palette.length]) {
      case C.blue:
        return C.blue;
      case C.violet:
        return C.onPur(c);
      case C.teal:
        return C.onTea(c);
      case C.amber:
        return C.onAmb(c);
      default:
        return C.onGrn(c);
    }
  }

  /// Ismning bosh harflari (maks. 2 ta), bo'sh bo'lsa '—'.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  /// Yirik summani "18.6 mln" ko'rinishida, aks holda oddiy formatda.
  String _mln(num v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} mln';
    return money(v);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: 'Xodimlar',
            icon: Icons.groups_rounded,
            subtitle: 'Jamoa a\'zolari',
            action: _IconBtn(icon: Icons.add_rounded, onTap: () {}),
          ),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final raw = (d['employees'] as List?) ?? const [];
                final employees = raw
                    .whereType<Map>()
                    .map((e) => e.cast<String, dynamic>())
                    .toList();

                if (employees.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.groups_rounded,
                        text: 'Xodim yo\'q',
                        color: C.blue,
                      ),
                    ],
                  );
                }

                final fond = employees.fold<double>(
                    0, (a, e) => a + ((e['salary'] as num?)?.toDouble() ?? 0));
                final yait = fond * 0.12; // YaIT ~12%

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // ── Oylik fond | YaIT bo'yicha ──
                    StaggerIn(
                      index: 0,
                      child: Row(children: [
                        Expanded(child: _SumCard(label: 'Oylik fond', value: _mln(fond), meta: 'so\'m/oy')),
                        const SizedBox(width: 10),
                        Expanded(child: _SumCard(label: 'YaIT bo\'yicha', value: _mln(yait), meta: 'so\'m/oy')),
                      ]),
                    ),

                    // ── Ro'yxat ──
                    const _Eyebrow(label: 'Ro\'yxat', trailing: 'Filtr'),

                    ...List.generate(employees.length, (i) {
                      final e = employees[i];
                      final name = (e['name'] ?? '').toString();
                      final position = (e['position'] ?? '').toString();
                      final salary = (e['salary'] as num?)?.toDouble() ?? 0;
                      return StaggerIn(
                        index: i + 1,
                        child: _EmployeeRow(
                          name: name,
                          position: position,
                          salary: salary,
                          initials: _initials(name),
                          accent: _mColor(context, i),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ]),
      );
}

/// Sarlavhadagi kichik ikonli tugma (dizayndagi `.iconbtn`).
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border(context)),
          ),
          child: Icon(icon, size: 18, color: C.muted(context, .7)),
        ),
      );
}

/// Yig'indi kartasi (Oylik fond / YaIT) — dizayndagi `.card` + `.lab/.val/.meta`.
class _SumCard extends StatelessWidget {
  final String label, value, meta;
  const _SumCard({required this.label, required this.value, required this.meta});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: C.text(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(meta, style: TextStyle(fontSize: 12, color: C.muted(context, .45))),
        ]),
      );
}

/// Bo'lim sarlavhasi (dizayndagi `.eyebrow`) — matn · chiziq · ixtiyoriy havola.
class _Eyebrow extends StatelessWidget {
  final String label;
  final String? trailing;
  const _Eyebrow({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: C.muted(context, .5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(
              trailing!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.blue),
            ),
          ],
        ]),
      );
}

/// Xodim qatori (dizayndagi `.row`) — monogram · ism/lavozim · oylik.
class _EmployeeRow extends StatelessWidget {
  final String name, position, initials;
  final double salary;
  final Color accent;
  const _EmployeeRow({
    required this.name,
    required this.position,
    required this.salary,
    required this.initials,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Row(children: [
          // Monogram
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.tint(context, accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initials,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                name.isEmpty ? '—' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: C.text(context)),
              ),
              if (position.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  position,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45)),
                ),
              ],
            ]),
          ),
          if (salary > 0) ...[
            const SizedBox(width: 10),
            Text(
              money(salary),
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: C.text(context)),
            ),
          ],
        ]),
      );
}
