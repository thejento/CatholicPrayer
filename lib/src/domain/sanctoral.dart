import 'package:flutter/foundation.dart';

import 'liturgical_calendar.dart';

/// Rank of a celebration in the General Roman Calendar.
enum Rank { solemnity, feast, memorial, optionalMemorial }

/// A saint or mystery celebrated on a fixed date. Names live in
/// `assets/data/saints/<lang>.json`, keyed by [id].
@immutable
class Celebration {
  const Celebration(this.month, this.day, this.id, this.rank, {this.ofTheLord = false});

  final int month;
  final int day;
  final String id;
  final Rank rank;

  /// Feasts of the Lord replace the Sundays of Ordinary and Christmas Time.
  final bool ofTheLord;

  @override
  String toString() => 'Celebration($id, ${rank.name})';
}

const _s = Rank.solemnity, _f = Rank.feast, _m = Rank.memorial, _o = Rank.optionalMemorial;

/// The General Roman Calendar, fixed dates (Missale Romanum 2002 and later
/// additions). Days named by the temporal calendar (Christmas, Epiphany …)
/// are in [liturgicalDay] instead.
const List<Celebration> generalRomanCalendar = [
  Celebration(1, 2, 'basil_gregory', _m),
  Celebration(1, 3, 'holy_name_of_jesus', _o),
  Celebration(1, 7, 'raymond_of_penyafort', _o),
  Celebration(1, 13, 'hilary', _o),
  Celebration(1, 17, 'anthony_abbot', _m),
  Celebration(1, 20, 'fabian', _o),
  Celebration(1, 20, 'sebastian', _o),
  Celebration(1, 21, 'agnes', _m),
  Celebration(1, 22, 'vincent_deacon', _o),
  Celebration(1, 24, 'francis_de_sales', _m),
  Celebration(1, 25, 'conversion_of_paul', _f),
  Celebration(1, 26, 'timothy_titus', _m),
  Celebration(1, 27, 'angela_merici', _o),
  Celebration(1, 28, 'thomas_aquinas', _m),
  Celebration(1, 31, 'john_bosco', _m),
  Celebration(2, 2, 'presentation_of_the_lord', _f, ofTheLord: true),
  Celebration(2, 3, 'blaise', _o),
  Celebration(2, 3, 'ansgar', _o),
  Celebration(2, 5, 'agatha', _m),
  Celebration(2, 6, 'paul_miki', _m),
  Celebration(2, 8, 'jerome_emiliani', _o),
  Celebration(2, 8, 'josephine_bakhita', _o),
  Celebration(2, 10, 'scholastica', _m),
  Celebration(2, 11, 'our_lady_of_lourdes', _o),
  Celebration(2, 14, 'cyril_methodius', _m),
  Celebration(2, 17, 'seven_servite_founders', _o),
  Celebration(2, 21, 'peter_damian', _o),
  Celebration(2, 22, 'chair_of_peter', _f),
  Celebration(2, 23, 'polycarp', _m),
  Celebration(2, 27, 'gregory_of_narek', _o),
  Celebration(3, 4, 'casimir', _o),
  Celebration(3, 7, 'perpetua_felicity', _m),
  Celebration(3, 8, 'john_of_god', _o),
  Celebration(3, 9, 'frances_of_rome', _o),
  Celebration(3, 17, 'patrick', _o),
  Celebration(3, 18, 'cyril_of_jerusalem', _o),
  Celebration(3, 19, 'joseph', _s),
  Celebration(3, 23, 'turibius', _o),
  Celebration(3, 25, 'annunciation', _s, ofTheLord: true),
  Celebration(4, 2, 'francis_of_paola', _o),
  Celebration(4, 4, 'isidore', _o),
  Celebration(4, 5, 'vincent_ferrer', _o),
  Celebration(4, 7, 'john_baptist_de_la_salle', _m),
  Celebration(4, 11, 'stanislaus', _m),
  Celebration(4, 13, 'martin_i', _o),
  Celebration(4, 21, 'anselm', _o),
  Celebration(4, 23, 'george', _o),
  Celebration(4, 23, 'adalbert', _o),
  Celebration(4, 24, 'fidelis', _o),
  Celebration(4, 25, 'mark', _f),
  Celebration(4, 28, 'peter_chanel', _o),
  Celebration(4, 28, 'louis_de_montfort', _o),
  Celebration(4, 29, 'catherine_of_siena', _m),
  Celebration(4, 30, 'pius_v', _o),
  Celebration(5, 1, 'joseph_the_worker', _o),
  Celebration(5, 2, 'athanasius', _m),
  Celebration(5, 3, 'philip_james', _f),
  Celebration(5, 10, 'john_of_avila', _o),
  Celebration(5, 12, 'nereus_achilleus', _o),
  Celebration(5, 12, 'pancras', _o),
  Celebration(5, 13, 'our_lady_of_fatima', _o),
  Celebration(5, 14, 'matthias', _f),
  Celebration(5, 18, 'john_i', _o),
  Celebration(5, 20, 'bernardine', _o),
  Celebration(5, 21, 'christopher_magallanes', _o),
  Celebration(5, 22, 'rita', _o),
  Celebration(5, 25, 'bede', _o),
  Celebration(5, 25, 'gregory_vii', _o),
  Celebration(5, 25, 'mary_magdalene_de_pazzi', _o),
  Celebration(5, 26, 'philip_neri', _m),
  Celebration(5, 27, 'augustine_of_canterbury', _o),
  Celebration(5, 29, 'paul_vi', _o),
  Celebration(5, 31, 'visitation', _f),
  Celebration(6, 1, 'justin', _m),
  Celebration(6, 2, 'marcellinus_peter', _o),
  Celebration(6, 3, 'charles_lwanga', _m),
  Celebration(6, 5, 'boniface', _m),
  Celebration(6, 6, 'norbert', _o),
  Celebration(6, 9, 'ephrem', _o),
  Celebration(6, 11, 'barnabas', _m),
  Celebration(6, 13, 'anthony_of_padua', _m),
  Celebration(6, 19, 'romuald', _o),
  Celebration(6, 21, 'aloysius_gonzaga', _m),
  Celebration(6, 22, 'paulinus_of_nola', _o),
  Celebration(6, 22, 'john_fisher_thomas_more', _o),
  Celebration(6, 24, 'nativity_of_john_the_baptist', _s),
  Celebration(6, 27, 'cyril_of_alexandria', _o),
  Celebration(6, 28, 'irenaeus', _m),
  Celebration(6, 29, 'peter_paul', _s),
  Celebration(6, 30, 'first_martyrs_of_rome', _o),
  Celebration(7, 3, 'thomas_apostle', _f),
  Celebration(7, 4, 'elizabeth_of_portugal', _o),
  Celebration(7, 5, 'anthony_zaccaria', _o),
  Celebration(7, 6, 'maria_goretti', _o),
  Celebration(7, 9, 'augustine_zhao_rong', _o),
  Celebration(7, 11, 'benedict', _m),
  Celebration(7, 13, 'henry', _o),
  Celebration(7, 14, 'camillus_de_lellis', _o),
  Celebration(7, 15, 'bonaventure', _m),
  Celebration(7, 16, 'our_lady_of_mount_carmel', _o),
  Celebration(7, 20, 'apollinaris', _o),
  Celebration(7, 21, 'lawrence_of_brindisi', _o),
  Celebration(7, 22, 'mary_magdalene', _f),
  Celebration(7, 23, 'bridget', _o),
  Celebration(7, 24, 'sharbel', _o),
  Celebration(7, 25, 'james_apostle', _f),
  Celebration(7, 26, 'joachim_anne', _m),
  Celebration(7, 29, 'martha_mary_lazarus', _m),
  Celebration(7, 30, 'peter_chrysologus', _o),
  Celebration(7, 31, 'ignatius_of_loyola', _m),
  Celebration(8, 1, 'alphonsus_liguori', _m),
  Celebration(8, 2, 'eusebius_of_vercelli', _o),
  Celebration(8, 2, 'peter_julian_eymard', _o),
  Celebration(8, 4, 'john_vianney', _m),
  Celebration(8, 5, 'dedication_of_st_mary_major', _o),
  Celebration(8, 6, 'transfiguration', _f, ofTheLord: true),
  Celebration(8, 7, 'sixtus_ii', _o),
  Celebration(8, 7, 'cajetan', _o),
  Celebration(8, 8, 'dominic', _m),
  Celebration(8, 9, 'teresa_benedicta', _o),
  Celebration(8, 10, 'lawrence', _f),
  Celebration(8, 11, 'clare', _m),
  Celebration(8, 12, 'jane_frances_de_chantal', _o),
  Celebration(8, 13, 'pontian_hippolytus', _o),
  Celebration(8, 14, 'maximilian_kolbe', _m),
  Celebration(8, 15, 'assumption', _s),
  Celebration(8, 16, 'stephen_of_hungary', _o),
  Celebration(8, 19, 'john_eudes', _o),
  Celebration(8, 20, 'bernard', _m),
  Celebration(8, 21, 'pius_x', _m),
  Celebration(8, 22, 'queenship_of_mary', _m),
  Celebration(8, 23, 'rose_of_lima', _o),
  Celebration(8, 24, 'bartholomew', _f),
  Celebration(8, 25, 'louis_of_france', _o),
  Celebration(8, 25, 'joseph_calasanz', _o),
  Celebration(8, 27, 'monica', _m),
  Celebration(8, 28, 'augustine', _m),
  Celebration(8, 29, 'passion_of_john_the_baptist', _m),
  Celebration(9, 3, 'gregory_the_great', _m),
  Celebration(9, 8, 'nativity_of_mary', _f),
  Celebration(9, 9, 'peter_claver', _o),
  Celebration(9, 12, 'holy_name_of_mary', _o),
  Celebration(9, 13, 'john_chrysostom', _m),
  Celebration(9, 14, 'exaltation_of_the_cross', _f, ofTheLord: true),
  Celebration(9, 15, 'our_lady_of_sorrows', _m),
  Celebration(9, 16, 'cornelius_cyprian', _m),
  Celebration(9, 17, 'robert_bellarmine', _o),
  Celebration(9, 17, 'hildegard', _o),
  Celebration(9, 19, 'januarius', _o),
  Celebration(9, 20, 'korean_martyrs', _m),
  Celebration(9, 21, 'matthew', _f),
  Celebration(9, 23, 'pio_of_pietrelcina', _m),
  Celebration(9, 26, 'cosmas_damian', _o),
  Celebration(9, 27, 'vincent_de_paul', _m),
  Celebration(9, 28, 'wenceslaus', _o),
  Celebration(9, 28, 'lawrence_ruiz', _o),
  Celebration(9, 29, 'archangels', _f),
  Celebration(9, 30, 'jerome', _m),
  Celebration(10, 1, 'therese_of_lisieux', _m),
  Celebration(10, 2, 'guardian_angels', _m),
  Celebration(10, 4, 'francis_of_assisi', _m),
  Celebration(10, 5, 'faustina', _o),
  Celebration(10, 6, 'bruno', _o),
  Celebration(10, 7, 'our_lady_of_the_rosary', _m),
  Celebration(10, 9, 'denis', _o),
  Celebration(10, 9, 'john_leonardi', _o),
  Celebration(10, 11, 'john_xxiii', _o),
  Celebration(10, 14, 'callistus_i', _o),
  Celebration(10, 15, 'teresa_of_avila', _m),
  Celebration(10, 16, 'hedwig', _o),
  Celebration(10, 16, 'margaret_mary_alacoque', _o),
  Celebration(10, 17, 'ignatius_of_antioch', _m),
  Celebration(10, 18, 'luke', _f),
  Celebration(10, 19, 'north_american_martyrs', _o),
  Celebration(10, 19, 'paul_of_the_cross', _o),
  Celebration(10, 22, 'john_paul_ii', _o),
  Celebration(10, 23, 'john_of_capistrano', _o),
  Celebration(10, 24, 'anthony_mary_claret', _o),
  Celebration(10, 28, 'simon_jude', _f),
  Celebration(11, 1, 'all_saints', _s),
  Celebration(11, 2, 'all_souls', _s),
  Celebration(11, 3, 'martin_de_porres', _o),
  Celebration(11, 4, 'charles_borromeo', _m),
  Celebration(11, 9, 'dedication_of_the_lateran', _f, ofTheLord: true),
  Celebration(11, 10, 'leo_the_great', _m),
  Celebration(11, 11, 'martin_of_tours', _m),
  Celebration(11, 12, 'josaphat', _m),
  Celebration(11, 15, 'albert_the_great', _o),
  Celebration(11, 16, 'margaret_of_scotland', _o),
  Celebration(11, 16, 'gertrude', _o),
  Celebration(11, 17, 'elizabeth_of_hungary', _m),
  Celebration(11, 18, 'dedication_of_peter_paul_basilicas', _o),
  Celebration(11, 21, 'presentation_of_mary', _m),
  Celebration(11, 22, 'cecilia', _m),
  Celebration(11, 23, 'clement_i', _o),
  Celebration(11, 23, 'columban', _o),
  Celebration(11, 24, 'vietnamese_martyrs', _m),
  Celebration(11, 25, 'catherine_of_alexandria', _o),
  Celebration(11, 30, 'andrew', _f),
  Celebration(12, 3, 'francis_xavier', _m),
  Celebration(12, 4, 'john_damascene', _o),
  Celebration(12, 6, 'nicholas', _o),
  Celebration(12, 7, 'ambrose', _m),
  Celebration(12, 8, 'immaculate_conception', _s),
  Celebration(12, 9, 'juan_diego', _o),
  Celebration(12, 10, 'our_lady_of_loreto', _o),
  Celebration(12, 11, 'damasus_i', _o),
  Celebration(12, 12, 'our_lady_of_guadalupe', _o),
  Celebration(12, 13, 'lucy', _m),
  Celebration(12, 14, 'john_of_the_cross', _m),
  Celebration(12, 21, 'peter_canisius', _o),
  Celebration(12, 23, 'john_of_kanty', _o),
  Celebration(12, 26, 'stephen', _f),
  Celebration(12, 27, 'john_apostle', _f),
  Celebration(12, 28, 'holy_innocents', _f),
  Celebration(12, 29, 'thomas_becket', _o),
  Celebration(12, 31, 'sylvester_i', _o),
];

/// The calendar proper to Canada, approved on 27 January 2016 (Prot. N. 32/16).
/// An entry with the id of a general one replaces it (another date or rank).
/// Civil days with their own Mass (Canada Day, Thanksgiving …) are left out.
const List<Celebration> canadaCalendar = [
  Celebration(1, 7, 'andre_bessette', _m),
  Celebration(1, 8, 'raymond_of_penyafort', _o),
  Celebration(1, 12, 'marguerite_bourgeoys', _m),
  Celebration(4, 17, 'kateri_tekakwitha', _m),
  Celebration(4, 18, 'marie_anne_blondin', _o),
  Celebration(4, 26, 'our_lady_of_good_counsel', _o),
  Celebration(4, 30, 'marie_de_l_incarnation', _m),
  Celebration(5, 1, 'pius_v', _o),
  Celebration(5, 4, 'marie_leonie_paradis', _o),
  Celebration(5, 6, 'francois_de_laval', _m),
  Celebration(5, 8, 'catherine_de_saint_augustin', _o),
  Celebration(5, 21, 'eugene_de_mazenod', _o),
  Celebration(5, 24, 'louis_zephirin_moreau', _o),
  Celebration(6, 27, 'budka_velychkovsky', _o),
  Celebration(7, 26, 'joachim_anne', _f),
  Celebration(8, 5, 'frederic_janssoone', _o),
  Celebration(9, 2, 'andre_grasset', _o),
  Celebration(9, 4, 'dina_belanger', _o),
  Celebration(9, 24, 'emilie_tavernier_gamelin', _o),
  Celebration(9, 25, 'cosmas_damian', _o),
  Celebration(9, 26, 'north_american_martyrs', _f),
  Celebration(10, 6, 'marie_rose_durocher', _o),
  Celebration(10, 16, 'marguerite_d_youville', _m),
  Celebration(10, 20, 'hedwig', _o),
  Celebration(10, 20, 'margaret_mary_alacoque', _o),
  Celebration(12, 12, 'our_lady_of_guadalupe', _f),
];

/// The Proper Calendar for the Dioceses of the United States (USCCB, 2015),
/// read the same way as [canadaCalendar]. Independence Day and Thanksgiving
/// are left out.
const List<Celebration> unitedStatesCalendar = [
  Celebration(1, 4, 'elizabeth_ann_seton', _m),
  Celebration(1, 5, 'john_neumann', _m),
  Celebration(1, 6, 'andre_bessette', _o),
  Celebration(1, 22, 'day_of_prayer_for_the_unborn', _m),
  Celebration(1, 23, 'vincent_deacon', _o),
  Celebration(1, 23, 'marianne_cope', _o),
  Celebration(3, 3, 'katharine_drexel', _o),
  Celebration(5, 10, 'damien_de_veuster', _o),
  Celebration(5, 15, 'isidore_the_farmer', _o),
  Celebration(7, 1, 'junipero_serra', _o),
  Celebration(7, 5, 'elizabeth_of_portugal', _o),
  Celebration(7, 14, 'kateri_tekakwitha', _m),
  Celebration(7, 18, 'camillus_de_lellis', _o),
  Celebration(9, 9, 'peter_claver', _m),
  Celebration(10, 5, 'francis_xavier_seelos', _o),
  Celebration(10, 6, 'marie_rose_durocher', _o),
  Celebration(10, 19, 'north_american_martyrs', _m),
  Celebration(10, 20, 'paul_of_the_cross', _o),
  Celebration(11, 13, 'frances_xavier_cabrini', _m),
  Celebration(11, 18, 'rose_philippine_duchesne', _o),
  Celebration(11, 23, 'miguel_pro', _o),
  Celebration(12, 12, 'our_lady_of_guadalupe', _f),
];

final _calendars = <CalendarRegion, List<Celebration>>{};

/// The fixed-date celebrations of [region]: the general ones, with the
/// national entries replacing those of the same id and adding the others.
List<Celebration> calendarFor(CalendarRegion region) => _calendars[region] ??= () {
  final national = switch (region) {
    CalendarRegion.general => const <Celebration>[],
    CalendarRegion.canada => canadaCalendar,
    CalendarRegion.unitedStates => unitedStatesCalendar,
  };
  final replaced = {for (final c in national) c.id};
  return List<Celebration>.unmodifiable([
    for (final c in generalRomanCalendar)
      if (!replaced.contains(c.id)) c,
    ...national,
  ]);
}();

DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);
DateTime _plus(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days);

/// Celebrations on [date]: the highest first, then any optional memorials.
/// Empty when the day itself is the celebration (Sundays of Advent, Lent and
/// Easter, Holy Week, the Easter octave, Christmas, Pentecost …).
List<Celebration> celebrationsOn(DateTime date, [CalendarRegion region = CalendarRegion.general]) {
  final d = _utc(date);
  final day = liturgicalDay(d, region);
  final easter = easterSunday(d.year);
  final pentecost = _plus(easter, 49);
  final sunday = d.weekday == DateTime.sunday;
  final holyWeekOrOctave = !d.isBefore(_plus(easter, -7)) && !d.isAfter(_plus(easter, 7));

  if (day.special != null || holyWeekOrOctave) return const [];

  // Moveable celebrations tied to Pentecost.
  if (d == _plus(pentecost, 1)) return const [Celebration(0, 0, 'mary_mother_of_the_church', _m)];
  // Thursday after Trinity Sunday, or the Sunday after it where transferred.
  if (d == _plus(pentecost, region.sundayTransfers ? 14 : 11)) {
    return const [Celebration(0, 0, 'corpus_christi', _s, ofTheLord: true)];
  }
  if (d == _plus(pentecost, 19)) {
    return const [Celebration(0, 0, 'sacred_heart', _s, ofTheLord: true)];
  }
  if (d == _plus(pentecost, 20)) return const [Celebration(0, 0, 'immaculate_heart_of_mary', _m)];

  final found = [
    for (final c in calendarFor(region))
      if (_utc(_observed(c, d.year)) == d) c,
  ];
  if (sunday) {
    // Sundays of Advent, Lent and Easter yield to nothing; the others to
    // solemnities and feasts of the Lord.
    final strong =
        day.season == Season.advent || day.season == Season.lent || day.season == Season.easter;
    return [
      for (final c in found)
        if (!strong && (c.rank == Rank.solemnity || c.ofTheLord)) c,
    ];
  }
  found.sort((a, b) => a.rank.index.compareTo(b.rank.index));
  // A solemnity or feast replaces any memorial of the same day.
  if (found.isNotEmpty && found.first.rank.index <= Rank.feast.index) return [found.first];
  return found;
}

/// The date a celebration is kept in [year], after the transfers of the
/// General Norms (§60): solemnities never fall on a Sunday of Lent or Advent,
/// in Holy Week or in the Easter octave.
DateTime _observed(Celebration c, int year) {
  final date = DateTime.utc(year, c.month, c.day);
  final easter = easterSunday(year);
  final palmSunday = _plus(easter, -7);
  final inHolyWeekOrOctave = !date.isBefore(palmSunday) && !date.isAfter(_plus(easter, 7));
  final sunday = date.weekday == DateTime.sunday;
  switch (c.id) {
    case 'joseph':
      if (inHolyWeekOrOctave) return _plus(palmSunday, -1);
      return sunday ? _plus(date, 1) : date;
    case 'annunciation':
      if (inHolyWeekOrOctave) return _plus(easter, 8);
      return sunday ? _plus(date, 1) : date;
    case 'immaculate_conception':
      return sunday ? _plus(date, 1) : date;
    case 'day_of_prayer_for_the_unborn':
      return sunday ? _plus(date, 1) : date;
    case 'nativity_of_john_the_baptist':
      // Moved to the eve when the Sacred Heart falls on 24 June.
      return _plus(easter, 49 + 19) == date ? _plus(date, -1) : date;
  }
  return date;
}
