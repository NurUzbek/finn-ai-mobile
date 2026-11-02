import 'dart:io';

import 'package:finn_ai/services/integrity.dart';
import 'package:flutter_test/flutter_test.dart';

/// APK imzo blokini o'qish — haqiqiy APK'lar bilan (FINN_APK_OURS / FINN_APK_FOREIGN).
void main() {
  final ours = Platform.environment['FINN_APK_OURS'];
  final foreign = Platform.environment['FINN_APK_FOREIGN'];

  test('bizning APK — kutilgan kalit', () async {
    final h = await Integrity.certHashes(ours!);
    expect(h, contains('j7mLhbvRfbzqX6c2akR9l1g3l6lPT8sbCsdPT9TY4xk='));
  }, skip: ours == null);

  test('qayta imzolangan APK — begona kalit', () async {
    final h = await Integrity.certHashes(foreign!);
    expect(h, isNotEmpty);
    expect(h, isNot(contains('j7mLhbvRfbzqX6c2akR9l1g3l6lPT8sbCsdPT9TY4xk=')));
    expect(h, isNot(contains('bZCeu8rBIOqfWyQyQnHCPB/GMtEU+PZuUPaJ23+Qwdo=')));
    // ignore: avoid_print
    print('begona: $h');
  }, skip: foreign == null);
}
