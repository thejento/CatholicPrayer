import 'package:flutter/material.dart';

import '../../models/prayer.dart';
import '../step_text.dart';
import 'prayer_about_screen.dart';

class PrayerDetailScreen extends StatelessWidget {
  const PrayerDetailScreen({super.key, required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final lang = contentLanguage(context);
    return Scaffold(
      appBar: AppBar(title: Text(prayer.titleFor(lang))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AboutPrayerButton(prayer: prayer),
                const SizedBox(height: 8),
                SelectableText(
                  prayer.textFor(lang),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
