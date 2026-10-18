"""Checks that Vatican News has a saint-of-the-day page for every date and
language the app links to (DESIGN §3.11). Prints the dates without one; they
belong in `missingSaintPages` in lib/src/data/saint_links.dart.

  python tool/saints/check_vatican_links.py
"""
import concurrent.futures as cf
import datetime
import urllib.request

PAGES = {
    "en": "https://www.vaticannews.va/en/saints/{m:02d}/{d:02d}.html",
    "es": "https://www.vaticannews.va/es/santos/{m:02d}/{d:02d}.html",
    "fr": "https://www.vaticannews.va/fr/saint-du-jour/{m:02d}/{d:02d}.html",
}


def status(job):
    lang, (m, d) = job
    req = urllib.request.Request(PAGES[lang].format(m=m, d=d), method="HEAD",
                                 headers={"User-Agent": "RosaryCompanion-build/1.0"})
    try:
        return job, urllib.request.urlopen(req, timeout=30).status
    except Exception as e:  # noqa: BLE001  (report any failure)
        return job, getattr(e, "code", str(e))


def main():
    day, days = datetime.date(2024, 1, 1), []  # a leap year: all 366 dates
    while day.year == 2024:
        days.append((day.month, day.day))
        day += datetime.timedelta(days=1)
    with cf.ThreadPoolExecutor(6) as pool:
        missing = [job for job, code in pool.map(status, [(l, md) for l in PAGES for md in days]) if code != 200]
    print("missing:", missing or "none")


if __name__ == "__main__":
    main()
