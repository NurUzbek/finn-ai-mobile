import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/plan.dart';

/// Tarifda mavjud bo'lmagan bo'lim — qulflangan holat.
/// Foydalanuvchiga nima berilishini ko'rsatadi va tarifni kengaytirishga taklif qiladi.
class LockedFeature extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> perks;
  const LockedFeature({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.perks = const [],
  });

  Future<void> _upgrade() async {
    final uri = Uri.parse(PlanState.i.upgradeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
        child: Column(children: [
          // Qulf ikonkasi — bo'lim ikonkasi ustida
          SizedBox(
            width: 104, height: 104,
            child: Stack(children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: C.cardDark,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                ),
                child: Icon(icon, size: 40, color: Colors.white.withValues(alpha: .22)),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.amber, Color(0xFFEA8C0B)]),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: C.bgDark, width: 3),
                  ),
                  child: const Icon(Icons.lock, size: 16, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.55, color: Colors.white.withValues(alpha: .5))),

          if (perks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              child: Column(children: [
                for (final p in perks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: C.green.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.check, size: 13, color: C.green),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                    ]),
                  ),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // Joriy tarif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.workspace_premium_outlined, size: 15, color: Colors.white.withValues(alpha: .45)),
              const SizedBox(width: 7),
              Text('Joriy tarif: ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .45))),
              Text(PlanState.i.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity, height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: C.blue.withValues(alpha: .35), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: TextButton.icon(
                onPressed: _upgrade,
                icon: const Icon(Icons.rocket_launch_outlined, size: 18, color: Colors.white),
                label: const Text('Tarifni kengaytirish',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Tarif finn.uz saytida yangilanadi',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .3))),
        ]),
      ),
    );
  }
}

/// Tarif holati chizig'i — sinov davri yoki tugash sanasini ko'rsatadi.
class PlanBanner extends StatelessWidget {
  const PlanBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PlanState.i;
    if (!p.loaded) return const SizedBox.shrink();

    final free = p.slug == 'free';
    final soon = (p.daysLeft ?? 99) <= 3;
    final c = free ? C.amber : (soon ? C.red : C.cyan);

    final text = free
        ? 'Bepul rejim — imkoniyatlar cheklangan'
        : p.isTrial
            ? 'Sinov davri: ${p.daysLeft} kun qoldi'
            : '${p.name} · ${p.daysLeft} kun qoldi';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.withValues(alpha: .28)),
      ),
      child: Row(children: [
        Icon(free ? Icons.lock_open_outlined : Icons.workspace_premium, size: 16, color: c),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
        if (free || soon)
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(p.upgradeUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Text('Kengaytirish →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c)),
          ),
      ]),
    );
  }
}
