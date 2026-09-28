"""Turn your Chapters experiences into a Markdown manuscript.

Usage:
    pip install -r tools/requirements.txt
    export SUPABASE_URL=...  SUPABASE_ANON_KEY=...
    export CHAPTERS_EMAIL=you@example.com  CHAPTERS_PASSWORD=...
    python tools/export_book.py            # writes manuscript.md
    python tools/export_book.py --title "Bad day"   # only one kind of day

You sign in as yourself, so Row Level Security still applies: the script can
only ever read your own entries.
"""
import argparse
import os
from collections import defaultdict
from datetime import date

from supabase import create_client


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--title", help="only export entries with this title")
    parser.add_argument("--out", default="manuscript.md")
    args = parser.parse_args()

    client = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_ANON_KEY"])
    client.auth.sign_in_with_password(
        {"email": os.environ["CHAPTERS_EMAIL"], "password": os.environ["CHAPTERS_PASSWORD"]}
    )

    query = client.table("experiences").select("*").order("happened_on")
    if args.title:
        query = query.eq("title", args.title)
    rows = query.execute().data

    by_month = defaultdict(list)
    for r in rows:
        d = date.fromisoformat(r["happened_on"])
        by_month[(d.year, d.month)].append((d, r))

    lines = ["# My Story", ""]
    for (year, month), entries in sorted(by_month.items()):
        lines += [f"## {date(year, month, 1):%B %Y}", ""]
        for d, r in entries:
            lines += [f"### {r['title']} ({d:%A %d %B})", "", r["body"].strip(), ""]
            if r.get("media_path"):
                lines += [f"_[{r['media_type']} attached: {r['media_path']}]_", ""]

    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Wrote {len(rows)} experiences to {args.out}")


if __name__ == "__main__":
    main()
