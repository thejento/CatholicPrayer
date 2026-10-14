import '../domain/mysteries.dart';
import 'localized_text.dart';

/// One mystery to meditate upon during a decade.
class Mystery {
  const Mystery({
    required this.set,
    required this.number,
    required this.title,
    required this.scripture,
    required this.fruit,
  });

  final MysterySet set;

  /// Position within its set, from 1 to [mysteriesPerSet].
  final int number;
  final LocalizedText title;
  final LocalizedText scripture;
  final LocalizedText fruit;
}
