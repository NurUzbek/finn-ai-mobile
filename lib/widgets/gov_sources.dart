import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/i18n.dart';
import '../theme/finn_tokens.dart';

/// Davlat ma'lumotlari manbalari + "davlat organi emas" ogohlantirishi.
///
/// Google Play Misleading Claims siyosati: davlat ma'lumotini ko'rsatadigan
/// ilova (1) rasmiy manbaga ishlaydigan havola beradi va (2) davlat nomidan
/// ish ko'rmasligini aniq aytadi. Login, profil va davlat ma'lumoti chiqadigan
/// ekranlarda ishlatiladi.
class GovSources {
  GovSources._();

  /// (tarjima kaliti, manzil) — do'kon tavsifidagi ro'yxat bilan bir xil.
  static const list = [
    ('src.soliq', 'https://soliq.uz'),
    ('src.mygov', 'https://my.gov.uz'),
    ('src.oneid', 'https://id.egov.uz'),
    ('src.mib', 'https://mib.uz'),
    ('src.cbu', 'https://cbu.uz'),
    ('src.lex', 'https://lex.uz'),
  ];

  static Future<void> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// To'liq ro'yxat — pastdan chiqadigan oyna.
  static Future<void> sheet(BuildContext context) {
    final t = context.tokens;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FinnTokens.rLg))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: t.line2, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(tr('src.title'), style: FinnText.cardTitle(t.ink)),
            const SizedBox(height: 12),
            const GovDisclaimer(),
            const SizedBox(height: 12),
            Text(tr('src.sheetIntro'), style: FinnText.rowSub(t.ink3)),
            const SizedBox(height: 8),
            for (final (key, url) in list)
              InkWell(
                onTap: () => open(url),
                borderRadius: BorderRadius.circular(FinnTokens.rSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(Icons.account_balance_outlined, size: 18, color: t.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr(key), style: FinnText.rowTitle(t.ink)),
                      Text(url.replaceFirst('https://', ''), style: FinnText.rowSub(t.blue)),
                    ])),
                    Icon(Icons.open_in_new_rounded, size: 16, color: t.ink4),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Ko'zga tashlanadigan ogohlantirish kartasi.
class GovDisclaimer extends StatelessWidget {
  const GovDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.tAmb, borderRadius: BorderRadius.circular(FinnTokens.rMd)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 18, color: t.onAmb),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('src.disclaimerTitle'), style: FinnText.rowTitle(t.onAmb)),
          const SizedBox(height: 4),
          Text(tr('src.disclaimer'), style: FinnText.rowSub(t.onAmb)),
        ])),
      ]),
    );
  }
}

/// Ixcham pastki yozuv — davlat ma'lumoti chiqadigan ekranlar oxirida.
/// Bosilganda to'liq manbalar ro'yxati ochiladi.
class GovSourcesFooter extends StatelessWidget {
  const GovSourcesFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () => GovSources.sheet(context),
      borderRadius: BorderRadius.circular(FinnTokens.rSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_outline_rounded, size: 14, color: t.ink4),
          const SizedBox(width: 6),
          Flexible(child: Text(tr('src.footer'),
              textAlign: TextAlign.center, style: FinnText.rowSub(t.ink4))),
          const SizedBox(width: 4),
          Text(tr('src.more'), style: FinnText.rowSub(t.blue)),
        ]),
      ),
    );
  }
}
