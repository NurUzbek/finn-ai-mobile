import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/finn_tokens.dart';
import '../services/api.dart';
import '../services/i18n.dart';

/// Finn AI suhbat — lokal (on-premise) Ollama + O'zbekiston qonunchiligi (RAG).
/// Ma'lumot serverdan chiqmaydi. CPU inferens sekin bo'lgani uchun aniq "yozmoqda"
/// indikatori ko'rsatiladi va so'rov 120s gacha kutiladi.
///
/// Bu MAXSUS ekran: pastda pinned kiritish paneli bor, shuning uchun FinnScreen
/// (skroll karkasi) o'rniga o'z Scaffold saqlanadi. Butun tuzilma HTML
/// prototipdagi `#v-ai` (welcome hero / pufaklar / typing / taklif chiplari /
/// composer) ga 1:1 mos.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMsg {
  final String role; // 'user' | 'assistant'
  String content;
  List<Map<String, dynamic>> sources;
  bool error; // xato holati — qayta urinish tugmasi ko'rinadi
  _ChatMsg(this.role, this.content, {this.sources = const [], this.error = false});
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [];
  bool _sending = false;

  // HTML prototipdagi taklif chiplari (data-q) — joriy tilda quriladi.
  List<String> get _suggestions => [
        tr('chat.sugg1'),
        tr('chat.sugg2'),
        tr('chat.sugg3'),
        tr('chat.sugg4'),
      ];

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      if (retryText == null) {
        _input.clear();
        _msgs.add(_ChatMsg('user', text));
      }
      // Avvalgi xato bubble'ni olib tashlaymiz (qayta urinishda)
      _msgs.removeWhere((m) => m.error);
      _sending = true;
    });
    _scrollDown();

    // Suhbat tarixi (xato xabarlarsiz), oxirgi ~20 ta
    final history = _msgs
        .where((m) => !m.error)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    final payload = history.length > 20 ? history.sublist(history.length - 20) : history;

    final r = await Api.aiChat(payload);

    if (!mounted) return;
    setState(() {
      _sending = false;
      if (r['ok'] == true && (r['reply'] ?? '').toString().isNotEmpty) {
        _msgs.add(_ChatMsg('assistant', r['reply'].toString(),
            sources: ((r['sources'] ?? []) as List).cast<Map<String, dynamic>>()));
      } else {
        _msgs.add(_ChatMsg('assistant',
            r['message']?.toString() ?? tr('chat.error'),
            error: true));
      }
    });
    _scrollDown();
  }

  void _sendSuggestion(String text) {
    if (_sending) return;
    _input.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = _msgs.isEmpty && !_sending;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          _header(t),
          Expanded(
            child: empty
                ? _welcome(t)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(FinnTokens.screenPad, 12, FinnTokens.screenPad, 8),
                    itemCount: _msgs.length + (_sending ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _msgs.length) return const _TypingBubble();
                      return _bubble(context, _msgs[i]);
                    },
                  ),
          ),
          _suggestions_(t),
          _composer(t),
        ]),
      ),
    );
  }

  // ─────────────────────── SARLAVHA ───────────────────────
  // FinnScreen uslubi: orqaga tugma + sarlavha (proto .hd + .ai-av).
  Widget _header(FinnTokens t) => Container(
        padding: const EdgeInsets.fromLTRB(FinnTokens.screenPad, 12, FinnTokens.screenPad, 12),
        decoration: BoxDecoration(
          color: t.card,
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(children: [
          _iconBtn(t, Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: FinnTokens.brand,
              borderRadius: BorderRadius.circular(FinnTokens.rMd),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(tr('chat.title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FinnText.screenTitle(t.ink).copyWith(fontSize: 19)),
              const SizedBox(height: 3),
              Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: t.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(tr('chat.status'), style: FinnText.rowSub(t.ink3)),
              ]),
            ]),
          ),
        ]),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) => GestureDetector(
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

  // ─────────────────────── WELCOME HERO ───────────────────────
  // proto .welc — markazda nafas oluvchi gradient belgi + sarlavha.
  Widget _welcome(FinnTokens t) => SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const _WelcomeIcon(),
            const SizedBox(height: 20),
            Text(tr('chat.welcomeTitle'),
                textAlign: TextAlign.center,
                style: FinnText.screenTitle(t.ink).copyWith(fontSize: 21)),
            const SizedBox(height: 9),
            Text(tr('chat.welcomeDesc'),
                textAlign: TextAlign.center, style: FinnText.body(t.ink2)),
          ]),
        ),
      );

  // ─────────────────────── XABAR PUFAGI ───────────────────────
  Widget _bubble(BuildContext context, _ChatMsg m) {
    final t = context.tokens;
    final isUser = m.role == 'user';
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          alignment: align,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
            decoration: BoxDecoration(
              gradient: isUser ? FinnTokens.brand : null,
              color: isUser ? null : (m.error ? t.tRed : t.card),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(FinnTokens.rLg),
                topRight: const Radius.circular(FinnTokens.rLg),
                bottomLeft: Radius.circular(isUser ? FinnTokens.rLg : 7),
                bottomRight: Radius.circular(isUser ? 7 : FinnTokens.rLg),
              ),
              border: isUser
                  ? null
                  : Border.all(color: m.error ? t.red.withValues(alpha: .35) : t.line),
              boxShadow: isUser ? null : t.sh,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (m.error)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline_rounded, size: 15, color: t.red),
                  const SizedBox(width: 6),
                  Flexible(child: Text(m.content, style: FinnText.body(t.red).copyWith(fontSize: 13.5))),
                ])
              else
                Text(m.content, style: FinnText.body(isUser ? Colors.white : t.ink)),
            ]),
          ),
        ),
        // Manbalar (RAG iqtiboslari)
        if (m.sources.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 1),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in m.sources) _sourceChip(t, s),
            ]),
          ),
        // Qayta urinish
        if (m.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: TextButton.icon(
              onPressed: _sending ? null : () => _send(_lastUserText()),
              icon: Icon(Icons.refresh_rounded, size: 16, color: t.cyan),
              label: Text(tr('chat.retry'),
                  style: FinnText.pill(t.cyan).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
            ),
          ),
      ],
    );
  }

  String _lastUserText() =>
      _msgs.lastWhere((m) => m.role == 'user', orElse: () => _ChatMsg('user', '')).content;

  Widget _sourceChip(FinnTokens t, Map<String, dynamic> s) {
    final label = '${tr('chat.source')} ${s['source'] ?? ''}${s['ref'] != null ? ' ${s['ref']}' : ''}'.trim();
    final url = (s['lex_url'] ?? '').toString();
    return GestureDetector(
      onTap: url.isEmpty
          ? null
          : () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: t.cyan.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(FinnTokens.rSm),
          border: Border.all(color: t.cyan.withValues(alpha: .25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.menu_book_rounded, size: 12, color: t.cyan),
          const SizedBox(width: 5),
          Text(label, style: FinnText.pill(t.cyan).copyWith(fontWeight: FontWeight.w600, fontSize: 10.5)),
          if (url.isNotEmpty) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 10, color: t.cyan),
          ],
        ]),
      ),
    );
  }

  // ─────────────────────── TAKLIF CHIPLARI ───────────────────────
  // proto .sugg — gorizontal skroll qatorida pill tugmalar.
  Widget _suggestions_(FinnTokens t) => SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(FinnTokens.screenPad, 6, FinnTokens.screenPad, 10),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final q = _suggestions[i];
            return GestureDetector(
              onTap: () => _sendSuggestion(q),
              child: Container(
                height: 38,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: t.line),
                  boxShadow: t.sh,
                ),
                child: Text(q, style: FinnText.chip(t.ink2).copyWith(fontSize: 13)),
              ),
            );
          },
        ),
      );

  // ─────────────────────── KIRITISH PANELI ───────────────────────
  // proto .composer — pill kiritish (.cmp-in) + doira yuborish tugmasi (.cmp-go).
  Widget _composer(FinnTokens t) => Container(
        padding: const EdgeInsets.fromLTRB(FinnTokens.screenPad, 8, FinnTokens.screenPad, 22),
        color: t.bg,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _inputFocus.hasFocus ? t.blue : t.line),
              ),
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: FinnText.body(t.ink).copyWith(fontSize: 14.5),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: _sending ? tr('chat.waiting') : tr('chat.hint'),
                  hintStyle: FinnText.body(t.ink3).copyWith(fontSize: 14.5),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: _sending ? null : () => _send(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: _sending ? null : FinnTokens.brand,
                color: _sending ? t.ink4 : null,
                borderRadius: BorderRadius.circular(25),
              ),
              child: _sending
                  ? Padding(
                      padding: const EdgeInsets.all(15),
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.card),
                    )
                  : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      );
}

/// Welcome hero belgisi — proto .welc-ic (brth animatsiyasi: scale 1↔.93).
class _WelcomeIcon extends StatefulWidget {
  const _WelcomeIcon();
  @override
  State<_WelcomeIcon> createState() => _WelcomeIconState();
}

class _WelcomeIconState extends State<_WelcomeIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ac, curve: FinnTokens.ease),
      ),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: FinnTokens.brand,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

/// AI "yozmoqda" indikatori — 3 sakrab turadigan nuqta (proto .typing).
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(FinnTokens.rLg),
            topRight: Radius.circular(FinnTokens.rLg),
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(FinnTokens.rLg),
          ),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(0), SizedBox(width: 5), _Dot(1), SizedBox(width: 5), _Dot(2),
        ]),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int index;
  const _Dot(this.index);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, _) {
        // Har bir nuqta fazasi surilgan — sakrash effekti (proto @keyframes dot)
        final tv = (_ac.value + widget.index * 0.14) % 1.0;
        final up = (tv < 0.5 ? tv : 1 - tv) * 2; // 0→1→0
        return Transform.translate(
          offset: Offset(0, -up * 4),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: t.ink4.withValues(alpha: 0.3 + up * 0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
