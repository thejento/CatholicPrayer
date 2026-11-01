# Catholic Rosary Companion: Design

> Status: **living document**. Change it in the same PR as the code it describes.
> The reasons behind each choice are in [DECISIONS.md](DECISIONS.md). The work queue is in [BACKLOG.md](../BACKLOG.md).

## 1. Purpose

Help **people who are new to the Rosary** pray it from start to finish without
feeling lost. The app tells them what to do and why, one bead at a time:
*hold the crucifix → make the Sign of the Cross → …*.

It is not a reference work. The pace is calm and the screens stay simple, and the
app never asks the user to know anything in advance.

### Personas

| Persona | Context | Needs |
|---|---|---|
| **Newcomer adult** (primary) | Curious, maybe RCIA/OCIA, has never prayed the Rosary | Know *what to say*, *when*, *which bead*, and *why* |
| **Family on the couch** | Praying together in front of an Android TV | Large text readable from 3 m away, a remote control to advance, a kid-friendly theme |
| **Returning Catholic** | Knew it as a child | Today's mysteries, quick start, the guidance can be hidden |
| **Child** | With a parent | Bright theme, big tap targets, simple words |

### Non-goals (for now)

User accounts, cloud sync, analytics, ads, or any network dependency at runtime.
The app works **fully offline** and collects **no personal data**.

## 2. Platforms

| Target | Form factor | Input | Distribution |
|---|---|---|---|
| Android phone/tablet | 360–1280 dp wide | Touch | Google Play (AAB), GitHub Release (APK) |
| Android TV | 960×540 dp, 10-foot UI | D-pad / remote | Same AAB, with a Leanback launcher entry |
| Web | Any width | Mouse, keyboard, touch | GitHub Pages (PWA) |

All three share **one Flutter codebase**. The app adapts to each platform through
layout breakpoints and input handling. There are no per-platform forks.

## 3. User experience

### 3.1 Screen flow

```
                ┌──────────────┐
                │    Home      │  Today: <weekday> → suggested mysteries
                │ [Pray now]   │
                │ [Learn]      │  (Prayer library)
                │ [⚙ Settings] │
                └──┬───┬───┬───┘
        ┌──────────┘   │   └───────────┐
        ▼              ▼               ▼
 ┌─────────────┐ ┌─────────────┐ ┌──────────┐
 │ Mysteries   │ │ Prayer list │ │ Settings │ theme, language,
 │ picker      │ │  → detail   │ │          │ guidance on/off
 └──────┬──────┘ └─────────────┘ └──────────┘
        ▼
 ┌──────────────────────────────────────────┐
 │ Guided Rosary                            │
 │  ┌────────────┐  Step 12 / 80  ▓▓░░░░░   │
 │  │  rosary    │  First Joyful Mystery    │
 │  │  drawing,  │  ── Hail Mary (3 / 10) ──│
 │  │  current   │  "Hail Mary, full of…"   │
 │  │  bead glows│  ℹ Hold the next small   │
 │  └────────────┘    bead and pray…        │
 │     [◀ Back]          [Next ▶]           │
 └──────────────────────────────────────────┘
```

### 3.2 Newcomer guidance (the core feature)

Every step of the Rosary carries three layers of information:

1. **Where am I?** The current bead glows on the rosary drawing. A progress bar
   and a label such as "Third decade · Hail Mary 4 of 10" show the position.
2. **What do I say?** The full prayer text in the chosen language, in large type.
3. **What do I do?** A one-sentence *guidance* line, e.g. "Hold the crucifix and
   make the Sign of the Cross." Experienced users can hide it in Settings.

Mystery announcements show the mystery title, a Scripture reference and its
traditional *fruit* (e.g. "Humility"), so a newcomer has something to meditate on.

When the step changes, a **glow travels** from the bead just prayed to the next
one (about 0.5 s), so the eye follows the movement on the physical rosary.

### 3.2.1 Resume

Progress is saved on every step. If the person leaves mid-Rosary, Home shows a
**"Continue where you left off"** card with the set and step. Finishing the
Rosary or going back to step 1 clears it. A saved step that no longer exists is
clamped to the sequence.

### 3.3 Interaction model

| Action | Touch | Keyboard / Web | TV remote |
|---|---|---|---|
| Next step | Tap *Next* or the glowing bead | `→`, `Space`, `Enter` | D-pad right, Select |
| Previous step | Tap *Back* | `←` | D-pad left |
| Leave | App-bar back | `Esc` | Back |

*Next* has initial focus, so the remote's Select button advances. *Back* is never
disabled, so D-pad focus can't land on a dead control. Focus must always be
visible, which is a hard requirement for TV.

### 3.4 Responsive layout

| Width (logical px) | Layout |
|---|---|
| `< 600` (phone) | Column: small rosary strip on top, text below |
| `600–1199` (tablet/web) | Row: rosary left (40 %), text right |
| `≥ 1200`, or Android TV | Row with a larger type scale (×1.3, the 10-foot UI) |

Android TV is detected through the `crc/device` platform channel (`MainActivity.kt`:
UI mode *television* or the Leanback feature). The web and phones report `false`
(ADR-016).

### 3.5 Themes

* **Classic** is a deep liturgical maroon with muted gold and serif headings.
* **Kid-friendly** is sky blue with sunny orange, rounded shapes and heavier weights.

Both themes must meet WCAG AA contrast for body text.

### 3.6 Languages

English, Spanish and French at launch. Two kinds of text, kept separate:

* **UI strings** live in `lib/src/l10n/*.arb` and use Flutter gen-l10n.
* **Devotional content** (prayers, mysteries) lives in one file per language:
  `assets/data/prayers/<lang>.json` and `assets/data/mysteries/<lang>.json`.
  `ContentRepository` merges them. The fallback order is the requested language, then English,
  then any available language.

Content uses **traditional, public-domain** wordings (ADR-013). Examples are the English
"who art in heaven" forms and the French *vous* forms, not the copyrighted ICEL/AELF
translations. Tests check that every prayer the Rosary needs exists in every
supported language.

### 3.7 Voice (read aloud), see ADR-020

**Goal:** a calm, natural voice that prays along with the user. It must not sound
robotic, must work offline, and must sound the same on phone, TV and web.

**Key idea: pre-recorded, not synthesised on the device.** Every spoken text is
known in advance: the prayers, the mystery announcements and the guidance lines. They
are rendered **once, at build time**, by an open-source neural TTS model and shipped
as small compressed audio files. The app only *plays* audio.

| | Pre-rendered (chosen) | On-device TTS (`flutter_tts`) |
|---|---|---|
| Voice quality | Best available open model, same everywhere | Depends on device; often robotic on TV/web |
| Offline | Yes | Usually; web voices may need network |
| Device cost | Playback only | Engine + voice data per device |
| Size | ≈ 1.8 MB per language (≈ 5 min of speech, MP3 48 kbps) | 0 |
| Text changes | Re-render (automated) | Instant |

**Voices** (chosen by ear in listening tests, see ADR-020 and ADR-021):

| Language | Engine | Voice |
|---|---|---|
| English | Kokoro-82M | Bella (`af_bella`), speed 0.9 |
| Spanish | Kokoro-82M | Dora (`ef_dora`), speed 0.9 |
| French | Kyutai TTS 1.6B (en/fr) | native reader `cml-tts/fr/7400_2928_000100-0001_enhanced`, seed 42 |

The mapping lives in `tool/tts/voices.json`. Changing an entry re-renders that language.

**If a clip can't be played** (a missing file, or a browser blocking sound without a tap),
the voice turns itself off and says *"Couldn't play the voice. You can go on with Next."*,
so auto-advance never waits for a clip that won't end (r-10).

**What is spoken** (44 clips per language):

* every prayer (8 clips)
* each mystery announcement, composed as
  `"{Set}. {Ordinal} mystery: {Title}."`, e.g. *"Joyful Mysteries. First mystery: The
  Annunciation."* (20 clips)
* the guidance line of each of the 16 kinds of step, with a setting to turn it off

**Pipeline**

```
assets/data/**.json + app_*.arb
   │  flutter test tool/tts/export_texts_test.dart   (texts come from the app's own code)
   ▼
build/tts/texts.json ──► tool/tts/render.py ──► assets/audio/<lang>/<clip>.mp3
                         (only stale clips)     assets/audio/manifest.json
                                                (voice id; clip → sha256(text), duration)
```

* A content test fails CI when a clip is **missing or stale**, meaning its text hash no longer
  matches the current text. So the audio can never silently drift from the words on screen.
* `render-audio.yml` runs on any branch push that changes spoken text. It renders only
  the stale clips, installs only the engines needed (Kokoro takes minutes; Kyutai
  takes about an hour for French on CPU) and commits them to the branch. GitHub holds CI runs
  triggered by a bot push for approval, and branch protection only counts PR-event runs,
  so the job approves that held run through the API.
* Kokoro (EN/ES) can also be rendered locally in about 2 minutes.

**Playback** (`just_audio`, MIT, Android + web)

* A speaker toggle in the Rosary app bar starts and stops the voice. The choice is persisted.
  On a TV remote or keyboard, the **play/pause** key does the same.
* While the voice is on, a bar under the prayer offers **speed** (− / + in steps of
  0.75×, 0.85×, 1.0×, 1.15×, 1.25×) and an **auto-advance** chip. The speed changes playback
  only, with pitch preserved by ExoPlayer and the browser, so no re-render is needed.
* Settings → Voice: read aloud, read the guidance aloud, auto-advance, and the pause
  before the next prayer (1–5 s). *About and credits* opens the licence page, which carries
  the required voice attributions.
* A language without recordings shows no speaker button, and Settings explains why.
* **Next** or a D-pad move stops the current clip and plays the new step's clip.
* Each clip of a step (instruction, then prayer) gets a fresh platform player, disposed when it
  ends. In the browser a player that had finished one clip could not start another: it replayed
  the instruction instead of the prayer, and a playlist skipped the prayer. A fresh player per
  clip works on the web and on Android. `integration_test/clip_player_test.dart` checks the order
  and timing in Chrome and on an Android emulator.
* **Auto-advance** (off by default): when a clip ends, wait for the pause (1–5 s, default
  2 s), then go to the next step. The person can then simply listen and pray along.
  It **waits on each mystery announcement**, saying so under the voice bar, because the
  Bible passage is read silently and a few seconds is not enough (owner's first Rosary,
  2026-10-18). Tapping Next resumes it. When the passages are read aloud (F-18), this wait
  can be removed.
* Each step opens scrolled to the top, even if the previous one was scrolled down.
* **Auto-scroll with the voice** (Settings → Voice, on by default): when the step's text is
  longer than the screen, it scrolls from top to bottom over the length of its clip (at the
  current speed), starting when the prayer starts, after the instruction. It is approximate:
  there are no word timings, and the voice slows at commas and line ends. Touching, dragging or
  wheel-scrolling the text stops it for that step; stopping the voice stops it too.
* The Hail Mary is a single clip reused 53 times. Variants are a later idea.

### 3.8 Daily reminder (F-12), see ADR-023

A gentle nudge to build the habit, **Android phones and tablets only** (not TV, where
notifications are not part of the experience, and not the web, where a page cannot
notify once it is closed).

* Settings → **Daily reminder**: a switch (off by default) and a time (default 20:00),
  picked with the system time picker.
* Turning it on asks for the notification permission (Android 13+). If the person refuses,
  the switch stays off and a message explains how to allow notifications in Android settings.
* The notification names that day's mysteries: *"Time to pray the Rosary"* / *"Today: the
  Sorrowful Mysteries."* Sundays depend on the season, so the app schedules one dated
  notification per day for the next **12 weeks** (84), each with its own date's mysteries,
  rather than weekly repeats whose text would go stale when Advent or Lent begins (r-12,
  ADR-038). Opening the app renews the 12 weeks; after 12 weeks without opening it, the
  reminders stop.
* Texts follow the app language. Reminders are rescheduled at start-up and whenever the
  language, time or switch changes; Android restores them after a reboot or app update.
* If they can't be scheduled (an unknown time zone falls back to one with the same UTC
  offset; anything else), the switch goes back off with *"Couldn't set the reminder"*, and
  the next start tries again (r-11).
* Delivery is *inexact* (Android may shift it by a few minutes to save battery), so the app
  needs no exact-alarm permission.
* Tapping the notification opens the app on Home, where today's mysteries and any
  unfinished Rosary are waiting.

### 3.9 Bible passage of each mystery (F-17), see ADR-024

Each mystery announcement has a **Read the passage** button under its Scripture reference.
It opens the full passage (for example Luke 1:26-38 for the Annunciation), with verse numbers
and the translation's credit at the bottom, so the person can read it before meditating.

| Language | Translation | Licence |
|---|---|---|
| English | Douay-Rheims, 1899 American Edition (Catholic) | public domain |
| Spanish | Torres Amat, 1836 edition (Catholic), spelling modernized | public domain |
| French | Sainte Bible néo-Crampon Libre (Catholic, © 2022 Fraternité de Tibériade) | CC BY-SA 4.0 |

* All three say "full of grace" / "llena de gracia" / "pleine de grâce" at Luke 1:28, the words of
  the Hail Mary.
* The Assumption is not narrated in Scripture; like the Coronation it shows Revelation 12:1,
  the passage Tradition reads for it.
* `tool/scripture/build.py` downloads the sources and writes `assets/data/scripture/<lang>.json`
  (20 passages, 178 verses). The Spanish spelling update (accents, j/g, modern names such as
  Jerusalén and Belén) is an explicit list in `tool/scripture/modern_es.py`; the wording is unchanged.
* On TV the D-pad moves from verse to verse, scrolling as it goes.
* Read aloud: not yet (backlog F-18).

### 3.10 Liturgical season (F-14), see ADR-025

The home screen shows where the day falls in the Church year, with a dot in the
liturgical colour: *"● Second Sunday of Advent"*, *"● Lent"*, *"● Pentecost"*,
*"● 6th Sunday in Ordinary Time"*.

**Mysteries of the day.** Weekdays keep the *Rosarium Virginis Mariae* pattern. Sundays follow
the season, a long-standing custom:

| Sundays of | Mysteries |
|---|---|
| Advent and Christmas Time | Joyful |
| Lent (including Palm Sunday) | Sorrowful |
| the rest of the year | Glorious |

The daily reminder uses the same rule; a reminder already scheduled for Sunday is refreshed
the next time the app is opened.

**Calendar** (General Roman Calendar, computed offline for any year):

* Easter by the Gregorian computus; Ash Wednesday = Easter − 46 days; Pentecost = Easter + 49.
* Advent begins on the fourth Sunday before Christmas; Christ the King is the Sunday before.
* Christmas Time runs from 25 December to the Baptism of the Lord (the Sunday after 6 January).
  Holy Family is the Sunday after Christmas, or 30 December when Christmas is a Sunday.
* Sundays are numbered within Advent, Lent and Easter Time, and in Ordinary Time (counted
  forward from the Baptism, then backward from Christ the King, the 34th).
* Named days: Christmas, Holy Family, Mary Mother of God, Epiphany (6 January), Baptism of the
  Lord, Ash Wednesday, Palm Sunday, Holy Thursday, Good Friday, Holy Saturday, Easter Sunday,
  Ascension (Thursday), Pentecost, Most Holy Trinity, Christ the King.
* Colours: violet (rose on Gaudete and Laetare Sundays), white, red (Palm Sunday, Good Friday,
  Pentecost), green.
* National calendars (Canada, United States): see §3.18.

**About today.** Tapping the day (or today's mysteries) on Home opens *About today*: the
season explained in a few sentences, what the colour of the day means, why today's mysteries
are suggested (the weekday pattern, the seasonal Sundays, and that it is a custom rather than a
rule), and what each of the four sets of mysteries is about, with its five mysteries.

### 3.11 Saint of the day (F-19), see ADR-026

Under the liturgical day, Home names the celebration of the day and its rank:
*"Saint Augustine, bishop and doctor of the Church · Memorial"*. When several optional
memorials share a day they are listed together (*"… or Saint Ansgar, bishop"*).

* Source: the General Roman Calendar (221 celebrations incl. later additions such as
  Saints Martha, Mary and Lazarus, Gregory of Narek, Hildegard, Paul VI, Faustina, Our Lady of
  Loreto), plus the four moveable ones after Pentecost (Mary Mother of the Church, Corpus
  Christi, Sacred Heart, Immaculate Heart). Names in EN/ES/FR, in the style of each
  language's liturgical books.
* Precedence, simplified from the General Norms: nothing on days that are themselves the
  celebration (Christmas, Holy Week, the Easter octave, Ash Wednesday, Pentecost…); Sundays of
  Advent, Lent and Easter yield to nothing; other Sundays only to solemnities and feasts of the
  Lord; a solemnity or feast replaces the memorials of its day.
* Transfers: Saint Joseph and the Annunciation out of Holy Week, the Easter octave and Lenten
  Sundays; the Immaculate Conception off an Advent Sunday; John the Baptist when the Sacred Heart
  falls on 24 June.
* Tapping the saint opens a card: each celebration of the day, what its rank means, and a
  button **Read about the saint of the day on Vatican News**, the Holy See's news service,
  which has a page per date in English, Spanish and French. It opens in the browser; on TV,
  where there is rarely a browser, the address is shown instead. Three English dates have no
  page (29 February, 1 and 2 November) and link to the saints index;
  `tool/saints/check_vatican_links.py` re-checks every date.
* The calendar itself is offline. National calendars and patron saints are F-21.

### 3.12 More prayers (F-20)

The Prayer Library has two sections: **Prayers of the Rosary** (the eight prayers the guided
Rosary uses) and **Other prayers**: the Memorare, the prayer to Saint Michael, Come Holy
Spirit, the prayer to the Guardian Angel, an Act of Contrition, the Angelus, the Regina Caeli
(said instead of the Angelus in Easter Time), the Litany of Loreto (F-22) and a note on
praying for the Holy Father's intentions after the Rosary.

* Traditional public-domain wordings only (ADR-013): the older "thee/thou" English forms, and
  the older Spanish and French forms rather than current liturgical translations.
* These prayers are read on screen, not aloud: only the prayers of the guided Rosary have
  recordings.
* **Litany of Loreto** (F-22): the traditional wording, with every title the popes have added
  up to 2020 (Mother of mercy, Mother of hope, Solace of migrants), one invocation per line
  with its response, so a group can pray it with one person leading. For the 2020 titles
  the app uses its own translations. Its "About this prayer" page lists when each title was
  added. Saint Michael and the Holy Father's intentions can now end the guided Rosary (§3.19).

### 3.13 Artwork on the mystery announcements, see ADR-028

In the **classic theme**, each mystery announcement shows a painting of that mystery as a card
above its title, with a one-line credit (title, artist, museum, licence). The kid-friendly theme
never shows paintings, and the prayer steps stay plain so the text is always easy to read.

* 20 paintings, one per mystery, chosen by the owner from a shortlist of 42: Masolino's
  *Annunciation*, Duccio's *Nativity* and *Calling of Peter and Andrew*, Tintoretto's *Baptism*,
  ter Brugghen's *Crowning with Thorns*, Rogier van der Weyden's *Crucifixion*, Sittow's
  *Assumption*, Agnolo Gaddi's *Coronation*… The Transfiguration is an engraving (Procaccini) and
  Pentecost a woodcut (Dürer): the open collections have no painting of them.
* Only images their museums release as **CC0 or public domain**: National Gallery of Art
  (Washington), Cleveland Museum of Art, Statens Museum for Kunst (Copenhagen). Credits are also
  on the licence page.
* `tool/art/build_art.py` downloads them, resizes to 1200 px and writes WebP (3.1 MB in all) plus
  `assets/data/art.json`.
* The painting keeps to about a quarter of the screen height (160–360 px) so the title stays in
  view; it has a screen-reader label ("Painting: The Annunciation, by Masolino da Panicale").
* Artwork titles are the museums' English titles in every language.

### 3.14 Version, feedback and the Play Store

**Web:** the home screen ends, below the Prayer Library button, with a divider, the app version
and two links: the Android app on Google Play (marked "soon" until the listing is live, O-10)
and GitHub Issues to report a problem.

**Settings → About (Android and web):** the version, "Report a problem on GitHub", "Rate the app
on Google Play" (Android phones and tablets, once the listing is live) and the existing About
and credits (licences). The Android home screen stays focused on prayer. On TV, where there is
rarely a browser, the GitHub address is shown as text instead of a link.

* The version comes from `lib/src/app_info.dart`: the pubspec version (a test keeps them equal),
  or the tag on release builds (`--dart-define=APP_VERSION`). Web deploys add the short commit
  (`APP_BUILD`), e.g. "Version 1.0.0 · 081acaa", so a bug report can say which build it was.
* `playStoreListed` in the same file switches the Play links on when the listing is public.
* GitHub needs an account, so a feedback email for everyone else is planned (F-27, on hold until
  there is a dedicated address). The address in the app can change with any release; the one
  on the Play listing can change at any time without a release.

### 3.15 Mysteries only (F-30), see ADR-029

For people who know the prayers by heart. The mystery picker asks **How do you want to pray?**
(**Guided** or **Mysteries only**), above the sets so it is seen on a phone, and remembers the
choice.

* **7 steps:** an *Opening prayers* card (Sign of the Cross, Creed, Our Father, Hail Mary × 3,
  Glory Be), the five mysteries, and a *Closing prayers* card (Hail, Holy Queen, the closing
  prayer, Sign of the Cross). Each prayer on a card opens its words, for a moment of doubt.
* **A mystery** shows the same content as in the guided Rosary (title, painting, passage,
  fruit) plus one line: "Pray the decade: the Our Father, ten Hail Marys, the Glory Be and the
  Fatima Prayer." There is no "what to do" line and **no Hail Mary counter** (owner's choice):
  the whole decade is ringed on the beads, and the decades already prayed are filled in.
* **Voice:** it reads only the mystery announcement, without its instruction, and never
  auto-advances (the person prays the decade at their own pace). The auto-advance chip is
  hidden. The summary cards are silent.
* **Resume:** the saved session keeps the mode (`joyful:3:mysteriesOnly`; the guided format
  `joyful:12` is unchanged, so older saves still resume). Home shows "Mysteries only · Step 3 of 7".
* Model: `RosaryMode` and `buildSequence(mode)` in `rosary_sequence.dart`. Each mystery step
  `covers` its 10 Hail Mary beads; the opening card covers the pendant.

### 3.16 Colours of the Church year (F-31), see ADR-030

The **classic** theme takes the liturgical colour of the day, the same one as the dot on Home
(§3.10): green in Ordinary Time, violet in Advent and Lent, rose on Gaudete and Laetare
Sundays, white (drawn as gold, as white vestments are usually trimmed with it) at Christmas
and Easter, red on Palm Sunday, Good Friday and Pentecost.

* The colours are deep, muted tones, so the screens stay calm. Red days keep the maroon the
  app always had, and that maroon is also the colour when the option is off. The gold accent
  is kept in every season.
* Settings → Appearance: **Colours of the Church year**, on by default, shown only with the
  classic theme.
* The **kid-friendly** theme keeps its own bright colours all year: children get one familiar,
  cheerful look.
* Saints' days do not change the colour (a martyr's red, a Marian white): only the season and
  its named days do, so the app doesn't change colour from one day to the next.
* Each colour is checked for text contrast and tap targets on Home, Settings, the picker and a
  Rosary step.

### 3.17 About this prayer (F-32), see ADR-031

A teaching app should say why we pray what we pray. Every prayer of the library has an
**About this prayer** button, which opens a page with up to three short sections:

* **Where it comes from:** its origin and history (for example, Gabriel's and Elizabeth's
  greetings in the Hail Mary; Leo XIII and the prayer to Saint Michael).
* **When it is prayed:** its place in the Rosary, the Mass, the Hours or the day.
* **In Scripture:** the Bible references it draws on, only when there are some.

Where the button is:
* the prayer page of the **library**, above the text;
* every prayer step of the **guided Rosary**, under the text (so it doesn't push the prayer
  down on each bead);
* in **mysteries only**, the prayers on the opening and closing cards open the library page,
  which has the button.

**The texts are the app's own**, written for it (80–120 words each, en/es/fr in
`assets/data/prayer_notes/<lang>.json`), not copied from a source. They keep to established
facts; where a story is only tradition or legend (Leo XIII's vision, Gregory the
Great and the Regina Caeli), they say so. They are not read aloud. On TV, the D-pad moves from
section to section. A content test requires a note for every prayer, in every language.

### 3.18 National calendars (F-21), see ADR-032

Settings → **Liturgical calendar**: *General Roman Calendar*, *Canada* or *United States*. Until
the person chooses, the app follows the device's country (`en-CA`, `fr-CA` → Canada; `en-US`,
`es-US` → United States; anything else → the General Roman Calendar).

**Sunday transfers** (both countries): the **Epiphany** is the Sunday between 2 and 8 January,
and the **Baptism of the Lord** the Sunday after it, or the Monday when the Epiphany falls on 7
or 8 January; the **Ascension** replaces the 7th Sunday of Easter; **Corpus Christi** is the
Sunday after Trinity Sunday. (A few US provinces keep the Ascension on Thursday; the app uses
Sunday, as most dioceses do.)

**National saints**, from the official proper calendars:
* Canada: the calendar approved on 27 January 2016 (Prot. N. 32/16): André Bessette, Marguerite
  Bourgeoys, Kateri Tekakwitha, Marie de l'Incarnation, François de Laval, Marguerite d'Youville,
  Canadian blesseds… The Canadian Martyrs are a **feast on 26 September**, Saints Anne and
  Joachim a **feast**, Our Lady of Guadalupe a **feast**; Raymond of Penyafort, Pius V, Cosmas
  and Damian, Hedwig and Margaret Mary move a day to make room.
* United States: the USCCB Proper Calendar: Elizabeth Ann Seton, John Neumann, the Day of Prayer
  for the Legal Protection of Unborn Children (22 January, or 23 when the 22nd is a Sunday),
  Katharine Drexel, Kateri Tekakwitha, Frances Xavier Cabrini… Our Lady of Guadalupe is a
  **feast**; Vincent, Elizabeth of Portugal, Camillus and Paul of the Cross move a day.
* Civil days with their own Mass (Canada Day, Thanksgiving, Independence Day…) are left out:
  the saint row is for saints and feasts.

The Sunday suggestion of mysteries is unchanged: the transfers never move a Sunday out of its
season. Model: `CalendarRegion` in `liturgical_calendar.dart`; `canadaCalendar` and
`unitedStatesCalendar` in `sanctoral.dart` list only what differs (an entry with a general id
replaces it); `calendarFor(region)` merges them.

### 3.19 Optional ending: Holy Father, Saint Michael (F-23), see ADR-033

Settings → **End of the Rosary** has two switches, both **off** by default, so the Rosary keeps
its 80 steps unless the person chooses:
* **Pray for the Holy Father's intentions**: an Our Father, a Hail Mary and a Glory Be (3 steps).
* **Add the prayer to Saint Michael** (1 step).

They come after the closing prayer, still on the medal, in that order, and before the last Sign
of the Cross (84 steps with both). Each has its own "what to do" line and voice clip; the
prayers reuse the existing recordings, plus one new clip for Saint Michael. In mysteries-only
mode the closing card lists them. A Rosary uses the ending set when it starts; the Home
"Continue" card counts the steps with the current setting. Model: `RosaryEnding` in
`rosary_sequence.dart`, `SettingsController.ending`.

### 3.20 Prayer journal (F-13), see ADR-034

A private list of the Rosaries prayed to the end, **kept only on the device**: no account, no
network, and left out of cloud backups (§9).

* **Recorded automatically** when a Rosary is finished (guided or mysteries only): date and
  time, mysteries, mode. Going back and finishing again doesn't count it twice; *Pray again*
  starts a new one. The completion screen says "Added to your prayer journal" and offers **Add
  an intention** (optional, up to 200 characters).
* **Home → Prayer journal**: "*n* Rosaries this month", then the entries newest first, grouped
  by month, each with its intention. A menu on each entry edits the intention or removes it;
  **Clear the journal** asks for confirmation inside the app.
* **No streak** or "days in a row": prayer isn't a score, and a broken streak would make people
  feel guilty. The monthly count is the only number.
* **Settings → Prayer journal**: on by default. Turning it off stops recording and hides the
  Home button; existing entries stay until cleared.
* Storage: `journal_entries` (JSON) in the preferences store, `JournalController`.

### 3.21 Web addresses (W-02), see ADR-035

Every screen has an address, shown in the browser after `#` (GitHub Pages can't serve other
paths), so **refreshing keeps the screen** and **a link can open one**:

| Address | Screen |
|---|---|
| `#/` | Home |
| `#/settings`, `#/today`, `#/pray`, `#/journal` | Settings, About today, choosing the mysteries, prayer journal |
| `#/library`, `#/library/hail_mary`, `#/library/hail_mary/about` | Library, a prayer, its background |
| `#/rosary/joyful` (`?mode=mysteriesOnly`) | The Rosary |
| `#/rosary/joyful/passage/3` | A mystery's Bible passage, over its Rosary |
| `#/chaplet/divine-mercy` | The Divine Mercy Chaplet (§3.22), from its start |
| `#/learn`, `#/learn/joyful`, `#/learn/divine-mercy` | Learn about the Rosary (§3.23) |

* Every screen sits under Home, so after opening a link, Back climbs to Home.
* **The Rosary's step is not in the address**: on a refresh or a link, the Rosary resumes at
  the saved step (F-06) when it is the same Rosary, otherwise at the start. Starting from the
  picker always begins again.
* An unknown address opens Home; an unknown prayer, the library; an unknown set of mysteries,
  the picker.
* Android and TV use the same routes; only the web shows them.
* Model: `lib/src/routes.dart` (`Routes`, `buildRouter`, go_router).
### 3.22 Divine Mercy Chaplet (I-01), see ADR-036

Home → **Divine Mercy Chaplet**: the chaplet Saint Faustina recorded in 1935 (Diary, nos.
474-476), guided bead by bead on the **same rosary drawing**, with guidance, voice and
auto-advance like the Rosary (63 steps):

```
Opening (4):   Sign of the Cross (crucifix) · Our Father (bead 1) · Hail Mary (bead 2) ·
               Apostles' Creed (bead 3)
Decade ×5 (11 each = 55):
               Eternal Father (large bead) · "For the sake of His sorrowful Passion" ×10
Closing (4):   Holy God ×3 (medal) · Sign of the Cross (crucifix)
```

* The optional opening and closing prayers of the Diary are left out, to keep the core.
* No mysteries, paintings or passages. The chaplet isn't saved for later (it takes about
  10 minutes), and it leaves an unfinished Rosary's progress alone.
* The end screen says "You prayed the Divine Mercy Chaplet!" and "Jesus, I trust in you."
* The library has a **Divine Mercy Chaplet** section with its three prayers, each with
  "About this prayer".
* Texts: the app's own translations of the Polish original (public domain), in the
  traditional register of the other prayers (ADR-036).
* Model: `Devotion` and `buildDivineMercySequence()` in `rosary_sequence.dart`;
  `RosaryScreen.chaplet`, address `#/chaplet/divine-mercy`. Not recorded in the prayer journal
  (§3.20), which lists Rosaries. Another chaplet is a new sequence, its texts and recordings.

### 3.23 Learn about the Rosary (F-33), see ADR-037

The app's goal is to teach, so it explains the different ways of praying on the beads.

* **Home → Learn about the Rosary** (`#/learn`, after the Prayer Library): a list of topics, each with a one-line
  summary, in three groups:
  * *The Rosary*: what it is (prayer and meditation, history, the shape on the beads), then
    the Joyful, Luminous, Sorrowful and Glorious mysteries (what each set remembers, its days).
  * *Other prayers on the beads*: the Divine Mercy Chaplet (Saint Faustina, how it differs).
  * *Praying with the app*: guided or mysteries only, praying alone or in a group; the optional
    ending (the Holy Father's intentions, Saint Michael).
* **A topic page** (`#/learn/joyful`, `#/learn/divine-mercy`…): the title, its summary and a
  few short sections, laid out like "About this prayer" (§3.17). A mystery set also lists its
  five mysteries with their fruit, then **Pray these mysteries**. The chaplet page ends with
  **Pray the chaplet**, the ending page with **Settings**.
* **Where the choice is made:** each card in *Choose the mysteries* shows the set's summary
  and a **Learn more** button; the mode hint links to *Ways to pray*; Settings → End of the
  Rosary links to the ending page.
* Texts are the app's own writing, in `assets/data/learn/<lang>.json`, keeping to established
  facts and naming legends as legends (as for the prayer notes). Not read aloud.

## 4. The Rosary model

### 4.1 Sequence (80 steps)

```
Intro (7):    Sign of the Cross · Apostles' Creed · Our Father ·
              Hail Mary ×3 (faith, hope, charity) · Glory Be
Decade ×5 (14 each = 70):
              Announce mystery · Our Father · Hail Mary ×10 ·
              Glory Be · Fatima Prayer
Closing (3):  Hail, Holy Queen · Closing prayer · Sign of the Cross
```

Optional before the last Sign of the Cross (§3.19): Our Father · Hail Mary · Glory Be for the
Holy Father's intentions, and the prayer to Saint Michael.

Totals: 53 Hail Marys, 6 Our Fathers and 6 Glory Bes.

### 4.2 Physical rosary → bead indices

```
 index  0      1     2 3 4     5       6        7..16   17   18..27  28 ...  50   51..60
       ✝︎   ──  ● ──  ○○○  ──  ●  ──  [medal] ── ○×10 ── ● ── ○×10 ── ● ...  ● ── ○×10 ─┐
     crucifix                                  decade 1  OF2  decade 2       OF5  decade 5│
                                     ▲────────────────────────────────────────────────────┘
```

* The intro Glory Be, the first announcement and the first decade's Our Father
  are all said on the large bead `5`. That follows the usual "on the next large bead" instruction.
* After a decade, the Glory Be and Fatima Prayer move to the **next** large bead
  (or to the medal after the fifth decade). This tells the newcomer that the decade is finished.
* Hail, Holy Queen and the closing prayer are on the medal (`6`). The final Sign of the
  Cross returns to the crucifix (`0`).

### 4.3 Mysteries by weekday (Sundays: see §3.10)

| Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---|---|---|---|---|---|
| Joyful | Sorrowful | Glorious | Luminous | Sorrowful | Joyful | Glorious |

The user can always pick another set before starting. Liturgical-season
overrides (e.g. Sorrowful on Lent Sundays) are in the backlog.

## 5. Architecture

```
lib/
  main.dart                 bootstrap: load prefs + content, then runApp
  src/
    app.dart                MaterialApp, theme, locale, routes, Shortcuts
    domain/                 pure Dart, no Flutter imports → fast unit tests
      mysteries.dart        MysterySet, Mystery, weekday suggestion
      rosary_sequence.dart  RosaryStep, buildRosarySequence()
      rosary_session.dart   ChangeNotifier: index, next/previous, progress
      clock.dart            injectable time source
    models/prayer.dart      localized prayer value object
    data/content_repository.dart  merges assets/data/{prayers,mysteries}/<lang>.json
    data/preferences_store.dart   key/value interface (+ in-memory fake)
    data/device_profile.dart      TV detection via platform channel
    providers/
      theme_manager.dart    theme, persisted
      settings_controller.dart  locale + guidance toggle, persisted
      saved_session_controller.dart  unfinished Rosary, persisted
    ui/
      screens/              home, prayer_library, prayer_detail,
                            mystery_picker, rosary, settings
      widgets/              rosary_beads (CustomPainter), step_panel, …
```

* **State management** uses `provider` with `ChangeNotifier`. The domain layer has no
  dependency on Flutter, so its logic is tested in plain unit tests.
* **Persistence** uses `shared_preferences` (`SharedPreferencesAsync`) behind a
  `PreferencesStore` interface. It works on Android and web with no account.
* **Dependency injection** goes through constructor parameters. Tests pass fakes, such as an
  in-memory preferences store and an injected clock (`DateTime Function()`).

## 6. Quality strategy

| Layer | Tool | Gate in CI |
|---|---|---|
| Format | `dart format --set-exit-if-changed` | required |
| Static analysis | `flutter analyze` (flutter_lints + stricter rules) | required, infos are fatal |
| Unit (domain, models, data) | `flutter test` | required |
| Widget (screens, keyboard/D-pad) | `flutter test` | required |
| Content integrity (JSON/ARB parity) | `flutter test` | required |
| Coverage | `scripts/check_coverage.sh`, generated code excluded | required (≥ 90 %) |
| Builds | `flutter build web`, `flutter build apk` | required |
| Golden screenshots (2 themes × phone/tablet/TV) | `matchesGoldenFile`, 0.5 % tolerance | required |
| Accessibility (every screen, both themes; 200 % text on phone, sideways phone, TV) | `meetsGuideline` tap-target, label, contrast; overflow check | required |
| Device/integration | `integration_test` on an emulator | backlog |

## 7. Delivery pipeline (CI/CD)

```
 PR / push ──► ci.yml ─┬─ quality: format · analyze · test · coverage gate
                       ├─ build-web  (artifact)
                       └─ build-android (debug-signed APK artifact)

 push main ──► deploy-web.yml ─► flutter build web --base-href /CatholicPrayer/
                                ─► GitHub Pages

 tag vX.Y.Z ─► release.yml ─► verify: version tag on main, tests pass
   (owner only)              ─► build: owner approves (environment `release`),
                                 signed AAB + APK + web zip, never debug-signed
                             ─► publish: GitHub Release with assets
                             ─► (backlog) Google Play internal track
```

* **Toolchain pin:** the Flutter version is pinned in `pubspec.yaml`
  (`environment.flutter`). CI reads it from there (`flutter-version-file`), so
  local builds and CI use the same version.
* **Branching:** trunk-based. `main` is protected and changes arrive through short-lived PRs.
* **Versioning:** SemVer tags `vX.Y.Z`. The Android `versionCode` comes from
  `github.run_number` during releases.
* **Secrets** (environment `release` → Settings → Environments):
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD`. Without them the release fails: Gradle refuses to sign a release
  with the debug key when `REQUIRE_RELEASE_SIGNING=true`, and the workflow checks the APK's
  certificate. PR builds in `ci.yml` stay debug-signed (ADR-012).
* **Release safeguards** (r-01, ADR-039): only the owner can create `v*` tags (a tag
  ruleset); the tagged commit must be on `main`; the signing job waits for the owner's
  approval; only the final publish job can write to the repository, and it never sees the
  secrets.
* **Gradle:** the wrapper jar is checked against Gradle's official checksums in CI and
  release, and the distribution zip has a pinned `distributionSha256Sum` (r-08).
* **Dependencies:** Dependabot opens weekly PRs for pub, Gradle and Actions.

## 8. Brand assets

App icons (Android mipmaps, web, maskable, favicon), the Android TV banner and the
Play Store icon and feature graphic are **drawn in code** by
`tool/render_icons_test.dart`. The emblem is a gold rosary on a liturgical-maroon gradient.
Regenerate with `flutter test tool/render_icons_test.dart` (ADR-017).

## 9. Privacy & accessibility

* **Startup:** if the content can't be loaded, the app shows *"The app couldn't start"* with
  the address to report it, instead of a blank screen. If storage is unavailable (a
  private browser window), it opens anyway without remembering settings (r-13).
* No network calls and no analytics. The only links out open in the browser when the person
  taps them: the Vatican News page about the saint of the day and, on the web, the Google Play
  and GitHub Issues links (§3.14). Android permissions, all normal (none grant access
  to personal data):
  * `POST_NOTIFICATIONS`: the optional daily reminder; asked for only when it is turned on.
  * `RECEIVE_BOOT_COMPLETED`, `VIBRATE`: restore the reminder after a reboot, vibrate with it.
  * `ACCESS_NETWORK_STATE`: added by the audio player library (ExoPlayer); the app plays
    bundled files only.
* **Backup** (ADR-034): the app's data (settings, the prayer journal) is excluded from Android
  cloud backup. On Android 12 and later, a device-to-device transfer to a new phone carries
  it; on older versions nothing is carried. On the web it stays in the browser's storage.
* Screen readers (TalkBack, browser readers): the rosary drawing is one labelled button
  ("Rosary, bead 14 of 61") whose tap moves to the next step. The step title is a heading
  and a live region, so each new step is announced without moving focus. The progress
  bar is labelled "Rosary progress". Decorative icons are silent.
* The app respects the system text scale with no cap; layouts are checked at 200 %.
  Every tap target is at least 48 dp, and text meets WCAG AA contrast in both themes.
* All of this is enforced by `test/ui/accessibility_test.dart` (ADR-022).
