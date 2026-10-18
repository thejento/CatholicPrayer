import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/mysteries.dart';

/// A painting shown on a mystery announcement, with its credit (ADR-028).
@immutable
class Artwork {
  const Artwork({
    required this.file,
    required this.width,
    required this.height,
    required this.title,
    required this.artist,
    required this.date,
    required this.museum,
    required this.license,
    required this.page,
  });

  factory Artwork.fromJson(Map<String, dynamic> j) => Artwork(
    file: j['file'] as String,
    width: j['width'] as int,
    height: j['height'] as int,
    title: j['title'] as String,
    artist: j['artist'] as String,
    date: j['date'] as String,
    museum: j['museum'] as String,
    license: j['license'] as String,
    page: j['page'] as String,
  );

  final String file;
  final int width;
  final int height;
  final String title;
  final String artist;
  final String date;
  final String museum;
  final String license;
  final String page;

  double get aspectRatio => width / height;
}

/// The painting of each mystery, from `assets/data/art.json` (built by
/// `tool/art/build_art.py`).
class ArtCatalog {
  ArtCatalog.fromJson(Map<String, dynamic> json)
    : _art = {
        for (final MapEntry(:key, :value) in json.entries)
          key: Artwork.fromJson(value as Map<String, dynamic>),
      };

  const ArtCatalog.empty() : _art = const {};

  static const path = 'assets/data/art.json';

  static Future<ArtCatalog> load(AssetBundle bundle) async =>
      ArtCatalog.fromJson(jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>);

  final Map<String, Artwork> _art;

  /// The painting for [decade] (1-5) of [set], if any.
  Artwork? artwork(MysterySet set, int decade) => _art['${set.name}_$decade'];

  Iterable<Artwork> get all => _art.values;
}

/// Credits for the paintings on the licence page.
void registerArtLicenses(ArtCatalog catalog) {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Artwork'],
      [
        'The paintings shown with the mysteries are public-domain works, reproduced from '
            'images their museums release as CC0 or public domain:',
        for (final a in catalog.all)
          '${a.title}, ${a.artist} (${a.date}). ${a.museum}, ${a.license}. ${a.page}',
      ].join('\n\n'),
    );
  });
}
