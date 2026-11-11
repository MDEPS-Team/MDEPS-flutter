import 'package:flutter/widgets.dart';
import 'package:mdeps_flutter/core/l10n/app_strings.dart';
import 'package:mdeps_flutter/core/l10n/app_strings_extra.dart';

/// Lightweight string lookup backed by the generated [appStringsEn] /
/// [appStringsEs] maps. Placeholders use `{0}`, `{1}`… positions.
abstract final class AppStrings {
  static const supportedLocales = [Locale('en'), Locale('es')];

  static String lookup(
    String languageCode,
    String key, [
    List<Object?> args = const [],
  ]) {
    final es = languageCode == 'es';
    final table = es ? appStringsEs : appStringsEn;
    final extra = es ? appStringsExtraEs : appStringsExtraEn;
    var value = table[key] ?? extra[key] ?? appStringsEn[key] ?? appStringsExtraEn[key] ?? key;
    for (var i = 0; i < args.length; i++) {
      value = value.replaceAll('{$i}', '${args[i]}');
    }
    return value;
  }

  static List<String> array(String languageCode, String key) {
    final table = languageCode == 'es' ? appStringsEs : appStringsEn;
    final out = <String>[];
    for (var i = 0;; i++) {
      final value = table['$key[$i]'] ?? appStringsEn['$key[$i]'];
      if (value == null) {
        return out;
      }
      out.add(value);
    }
  }
}

extension L10nContext on BuildContext {
  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Translates [key] for the active locale, replacing `{n}` with [args].
  String tr(String key, [List<Object?> args = const []]) =>
      AppStrings.lookup(languageCode, key, args);

  /// Plural lookup (`key#one` / `key#other`); [count] is always arg `{0}`
  /// unless explicit [args] are given.
  String trPlural(String key, int count, [List<Object?>? args]) {
    final suffix = count == 1 ? 'one' : 'other';
    return AppStrings.lookup(languageCode, '$key#$suffix', args ?? [count]);
  }

  List<String> trArray(String key) => AppStrings.array(languageCode, key);
}
