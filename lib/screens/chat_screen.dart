import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api.dart';

/// AI konsultant — lokal (on-premise) Ollama + O'zbekiston qonunchiligi (RAG).
/// Ma'lumot serverdan chiqmaydi. CPU inferens sekin bo'lgani uchun aniq "yozmoqda"
/// indikatori ko'rsatiladi va so'rov 120s gacha kutiladi.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMsg {
  final String role; // 'user' | 'assistant'
  String content;
  List<Map<String, dynamic>> sources;
  bool local; // mahalliy xabar (salomlashuv) — API'ga yuborilmaydi
  bool error; // xato holati — qayta urinish tugmasi ko'rinadi
  _ChatMsg(this.role, this.content, {this.sources = const [], this.local = false, this.error = false});
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _msgs = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _msgs.add(_ChatMsg('assistant',
        'Assalomu alaykum! Men FINN AI konsultantiman. Soliq, penya, hisobot va risk bo\'yicha savol bering.',
        local: true));
  }

  @override
  void dispose() {
    _input.dispose();
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

    // Suhbat tarixi (mahalliy/xato xabarlarsiz), oxirgi ~20 ta
    final history = _msgs
        .where((m) => !m.local && !m.error)
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
            r['message']?.toString() ?? 'Javob olishda xatolik yuz berdi. Qayta urinib ko\'ring.',
            error: true));
      }
    });
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        child: Column(children: [
          _header(context),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _msgs.length) return const _TypingBubble();
                return _bubble(context, _msgs[i]);
              },
            ),
          ),
          _inputBar(context),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
        decoration: BoxDecoration(
          color: C.card(context),
          border: Border(bottom: BorderSide(color: C.border(context, .06))),
        ),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: C.text(context)),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.blue, C.cyan]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI konsultant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: C.text(context))),
              Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('On-premise · maxfiy',
                    style: TextStyle(fontSize: 11, color: C.muted(context, .5))),
              ]),
            ]),
          ),
        ]),
      );

  Widget _bubble(BuildContext context, _ChatMsg m) {
    final isUser = m.role == 'user';
    final bubbleColor = m.error ? C.red.withValues(alpha: .1) : C.card(context);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          alignment: align,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              gradient: isUser ? const LinearGradient(colors: [C.blue, C.cyan]) : null,
              color: isUser ? null : bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 5),
                bottomRight: Radius.circular(isUser ? 5 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: m.error ? C.red.withValues(alpha: .3) : C.border(context, .07)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (m.error)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 15, color: C.red),
                  const SizedBox(width: 6),
                  Flexible(child: Text(m.content,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: C.red))),
                ])
              else
                Text(m.content,
                    style: TextStyle(
                      fontSize: 13.5, height: 1.5,
                      color: isUser ? Colors.white : C.text(context),
                    )),
            ]),
          ),
        ),
        // Manbalar (RAG iqtiboslari)
        if (m.sources.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 1),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in m.sources) _sourceChip(context, s),
            ]),
          ),
        // Qayta urinish
        if (m.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: TextButton.icon(
              onPressed: _sending ? null : () => _send(_lastUserText()),
              icon: const Icon(Icons.refresh, size: 16, color: C.cyan),
              label: const Text('Qayta urinish', style: TextStyle(color: C.cyan, fontWeight: FontWeight.w700, fontSize: 12.5)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
            ),
          ),
      ],
    );
  }

  String _lastUserText() =>
      _msgs.lastWhere((m) => m.role == 'user', orElse: () => _ChatMsg('user', '')).content;

  Widget _sourceChip(BuildContext context, Map<String, dynamic> s) {
    final label = 'Manba: ${s['source'] ?? ''}${s['ref'] != null ? ' ${s['ref']}' : ''}'.trim();
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
          color: C.cyan.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: C.cyan.withValues(alpha: .25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.menu_book_outlined, size: 12, color: C.cyan),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.cyan)),
          if (url.isNotEmpty) ...[
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 10, color: C.cyan),
          ],
        ]),
      ),
    );
  }

  Widget _inputBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        decoration: BoxDecoration(
          color: C.card(context),
          border: Border(top: BorderSide(color: C.border(context, .06))),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_sending,
              minLines: 1, maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: C.text(context)),
              decoration: InputDecoration(
                hintText: _sending ? 'Javob kutilyapti…' : 'Savolingizni yozing…',
                hintStyle: TextStyle(color: C.muted(context, .4), fontSize: 14),
                filled: true,
                fillColor: C.fill(context, .05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : () => _send(),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _sending ? [C.muted(context, .25), C.muted(context, .2)] : const [C.blue, C.cyan]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      );
}

/// AI "yozmoqda" indikatori — 3 sakrab turadigan nuqta.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: C.card(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(5), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: C.border(context, .07)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(0), SizedBox(width: 5), _Dot(1), SizedBox(width: 5), _Dot(2),
          ]),
        ),
      );
}

class _Dot extends StatefulWidget {
  final int index;
  const _Dot(this.index);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ac,
        builder: (context, _) {
          // Har bir nuqta fazasi surilgan sinus — sakrash effekti
          final t = (_ac.value + widget.index * 0.22) % 1.0;
          final up = (t < 0.5 ? t : 1 - t) * 2; // 0→1→0
          return Transform.translate(
            offset: Offset(0, -up * 4),
            child: Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: C.cyan.withValues(alpha: 0.4 + up * 0.6),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
}
