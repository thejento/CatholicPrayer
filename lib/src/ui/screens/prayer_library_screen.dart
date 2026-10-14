import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/content_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../step_text.dart';
import 'prayer_detail_screen.dart';

class PrayerLibraryScreen extends StatelessWidget {
  const PrayerLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prayers = context.read<ContentRepository>().prayers;
    final lang = contentLanguage(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prayerLibrary)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            itemCount: prayers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => ListTile(
              autofocus: i == 0,
              title: Text(prayers[i].titleFor(lang)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PrayerDetailScreen(prayer: prayers[i])),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
