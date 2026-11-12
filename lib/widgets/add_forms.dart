import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/finn_tokens.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import 'gov_sources.dart';

/// "+" tugmalari uchun qo'shish formalari (modal bottom sheet).
/// Har biri Api'ga POST qiladi; muvaffaqiyatda `true` qaytaradi (ro'yxat yangilanadi).

Future<bool> showAddFinancial(BuildContext context) =>
    _open(context, (t, setBusy) => _FinancialForm(t: t, setBusy: setBusy));

Future<bool> showAddEmployee(BuildContext context) =>
    _open(context, (t, setBusy) => _EmployeeForm(t: t, setBusy: setBusy));

Future<bool> showAddOrganization(BuildContext context) =>
    _open(context, (t, setBusy) => _OrganizationForm(t: t, setBusy: setBusy));

Future<bool> _open(BuildContext context,
    Widget Function(FinnTokens t, void Function(bool) setBusy) build) async {
  final t = context.tokens;
  final res = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(FinnTokens.rXl)),
          border: Border.all(color: t.line),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: t.ink4, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            build(t, (_) {}),
          ]),
        ),
      ),
    ),
  );
  return res ?? false;
}

// ── Umumiy maydon widgetlari ──
Widget _field(FinnTokens t, String label, TextEditingController c,
    {TextInputType? kbd, int max = 1, List<TextInputFormatter>? fmt}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: FinnText.eyebrow(t.ink3)),
    const SizedBox(height: 6),
    TextField(
      controller: c,
      keyboardType: kbd,
      maxLines: max,
      inputFormatters: fmt,
      style: FinnText.rowTitle(t.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: t.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FinnTokens.rMd), borderSide: BorderSide(color: t.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FinnTokens.rMd), borderSide: BorderSide(color: t.blue, width: 1.4)),
      ),
    ),
  ]);
}

Widget _chips(FinnTokens t, List<(String value, String label)> items, String sel,
    ValueChanged<String> onSel) {
  return Wrap(spacing: 8, runSpacing: 8, children: [
    for (final it in items)
      GestureDetector(
        onTap: () => onSel(it.$1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel == it.$1 ? t.blue : t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rLg),
            border: Border.all(color: sel == it.$1 ? t.blue : t.line),
          ),
          child: Text(it.$2, style: FinnText.pill(sel == it.$1 ? Colors.white : t.ink2)),
        ),
      ),
  ]);
}

Widget _header(FinnTokens t, String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: FinnText.cardTitle(t.ink))),
    );

Widget _saveBtn(FinnTokens t, bool busy, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: t.blue,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinnTokens.rMd)),
          ),
          onPressed: busy ? null : onTap,
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(tr('common.save'), style: FinnText.rowTitle(Colors.white)),
        ),
      ),
    );

void _toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
  ..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(m)));

// ── Moliyaviy operatsiya ──
class _FinancialForm extends StatefulWidget {
  const _FinancialForm({required this.t, required this.setBusy});
  final FinnTokens t;
  final void Function(bool) setBusy;
  @override
  State<_FinancialForm> createState() => _FinancialFormState();
}

class _FinancialFormState extends State<_FinancialForm> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'income';
  String _cat = 'boshqa';
  bool _busy = false;

  static const _cats = ['soliq', 'maosh', 'transport', 'ijara', 'tovar', 'xizmat', 'kommunal', 'boshqa'];

  Future<void> _save() async {
    final amt = num.tryParse(_amount.text.trim().replaceAll(' ', ''));
    if (amt == null || amt <= 0) {
      _toast(context, tr('add.required'));
      return;
    }
    setState(() => _busy = true);
    final res = await Api.addFinancial(
        type: _type, amount: amt, category: _cat, description: _desc.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['ok'] == true) {
      _toast(context, tr('add.saved'));
      Navigator.pop(context, true);
    } else {
      _toast(context, res['message']?.toString() ?? tr('add.error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(t, tr('add.finTitle')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _chips(t, [('income', tr('fin.income')), ('expense', tr('fin.expense'))], _type, (v) => setState(() => _type = v)),
          const SizedBox(height: 16),
          _field(t, tr('add.amount'), _amount,
              kbd: TextInputType.number, fmt: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 16),
          Text(tr('add.category'), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(height: 8),
          _chips(t, [for (final c in _cats) (c, trTxnCat(c))], _cat, (v) => setState(() => _cat = v)),
          const SizedBox(height: 16),
          _field(t, tr('add.note'), _desc, max: 2),
        ]),
      ),
      _saveBtn(t, _busy, _save),
    ]);
  }
}

// ── Xodim ──
class _EmployeeForm extends StatefulWidget {
  const _EmployeeForm({required this.t, required this.setBusy});
  final FinnTokens t;
  final void Function(bool) setBusy;
  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _name = TextEditingController();
  String _pos = 'Menejer';
  bool _busy = false;

  static const _positions = ['Direktor', 'Bosh buxgalter', 'Buxgalter', 'Menejer', 'Mutaxassis', 'Operator', 'Kassir'];

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast(context, tr('add.required'));
      return;
    }
    setState(() => _busy = true);
    final res = await Api.addEmployee(fullName: name, position: _pos);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['ok'] == true) {
      _toast(context, tr('add.saved'));
      Navigator.pop(context, true);
    } else {
      _toast(context, res['message']?.toString() ?? tr('add.error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(t, tr('add.empTitle')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(t, tr('add.fullName'), _name, kbd: TextInputType.name),
          const SizedBox(height: 16),
          Text(tr('add.position'), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(height: 8),
          _chips(t, [for (final p in _positions) (p, trPosition(p))], _pos, (v) => setState(() => _pos = v)),
        ]),
      ),
      _saveBtn(t, _busy, _save),
    ]);
  }
}

// ── Tashkilot ──
class _OrganizationForm extends StatefulWidget {
  const _OrganizationForm({required this.t, required this.setBusy});
  final FinnTokens t;
  final void Function(bool) setBusy;
  @override
  State<_OrganizationForm> createState() => _OrganizationFormState();
}

class _OrganizationFormState extends State<_OrganizationForm> {
  final _name = TextEditingController();
  final _stir = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast(context, tr('add.required'));
      return;
    }
    setState(() => _busy = true);
    final res = await Api.addOrganization(name: name, stir: _stir.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['ok'] == true) {
      _toast(context, tr('add.saved'));
      Navigator.pop(context, true);
    } else {
      _toast(context, res['message']?.toString() ?? tr('add.error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(t, tr('add.orgTitle')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(t, tr('add.orgName'), _name),
          const SizedBox(height: 16),
          _field(t, tr('add.stir'), _stir,
              kbd: TextInputType.number,
              fmt: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]),
          const SizedBox(height: 12),
          // Google Play: STIR kiritiladigan joyda ham "davlat organi emas" + manbalar
          Text(tr('src.innNote'), style: FinnText.rowSub(t.ink3)),
          const GovSourcesFooter(),
        ]),
      ),
      _saveBtn(t, _busy, _save),
    ]);
  }
}
