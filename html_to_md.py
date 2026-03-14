#!/usr/bin/env python3
"""
html_to_md.py — extract live site sections and emit markdown for ClickUp backup
Usage: echo "$HTML" | python3 html_to_md.py [YYYY-MM-DD]
"""
import sys
import re
from html.parser import HTMLParser

today = sys.argv[1] if len(sys.argv) > 1 else "unknown"
html = sys.stdin.read()


class SectionExtractor(HTMLParser):
    SECTIONS = ("intro", "approach", "characteristics", "exocortex")
    SKIP_TAGS = {"script", "style", "nav", "header", "footer"}

    def __init__(self):
        super().__init__()
        self.sections = []          # list of (id, md_lines)
        self.cur_id = None
        self.cur_lines = []
        self.cur_para = []
        self.list_stack = []        # track ol/ul nesting
        self.in_li = False
        self.skip_depth = 0
        self.bold_open = False

    # ── helpers ───────────────────────────────────────────────────────────────
    def _flush_para(self):
        text = "".join(self.cur_para).strip()
        if text:
            if self.in_li:
                self.cur_lines.append(f"- {text}")
            else:
                self.cur_lines.append(text)
                self.cur_lines.append("")
        self.cur_para = []

    # ── parser events ─────────────────────────────────────────────────────────
    def handle_starttag(self, tag, attrs):
        attrs_d = dict(attrs)

        if tag in self.SKIP_TAGS:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return

        if tag == "section":
            sid = attrs_d.get("id", "")
            if sid in self.SECTIONS:
                self.cur_id = sid
                self.cur_lines = []
                self.cur_para = []

        elif self.cur_id:
            if tag in ("h1", "h2", "h3"):
                self._flush_para()
                self.cur_para = []
            elif tag == "strong":
                self.cur_para.append("**")
                self.bold_open = True
            elif tag in ("ol", "ul"):
                self._flush_para()
                self.list_stack.append(tag)
            elif tag == "li":
                self._flush_para()
                self.in_li = True
            elif tag == "p":
                self._flush_para()

    def handle_endtag(self, tag):
        if tag in self.SKIP_TAGS:
            self.skip_depth = max(0, self.skip_depth - 1)
            return
        if self.skip_depth:
            return

        if tag == "section" and self.cur_id:
            self._flush_para()
            self.sections.append((self.cur_id, list(self.cur_lines)))
            self.cur_id = None
            self.cur_lines = []

        elif self.cur_id:
            if tag in ("h1", "h2"):
                text = "".join(self.cur_para).strip()
                if text:
                    self.cur_lines.append(f"## {text}")
                    self.cur_lines.append("")
                self.cur_para = []
            elif tag == "h3":
                text = "".join(self.cur_para).strip()
                if text:
                    self.cur_lines.append(f"### {text}")
                    self.cur_lines.append("")
                self.cur_para = []
            elif tag == "strong":
                self.cur_para.append("**")
                self.bold_open = False
            elif tag == "li":
                self._flush_para()
                self.in_li = False
            elif tag in ("ol", "ul"):
                if self.list_stack:
                    self.list_stack.pop()
                self.cur_lines.append("")
            elif tag == "p":
                self._flush_para()

    def handle_data(self, data):
        if self.skip_depth:
            return
        if self.cur_id:
            self.cur_para.append(data)

    def handle_entityref(self, name):
        entities = {"amp": "&", "lt": "<", "gt": ">", "nbsp": " ",
                    "mdash": "—", "ndash": "–", "ldquo": "\u201c",
                    "rdquo": "\u201d", "lsquo": "\u2018", "rsquo": "\u2019",
                    "hellip": "…"}
        if self.cur_id:
            self.cur_para.append(entities.get(name, ""))

    def handle_charref(self, name):
        try:
            ch = chr(int(name[1:], 16) if name.startswith("x") else int(name))
            if self.cur_id:
                self.cur_para.append(ch)
        except Exception:
            pass


LABELS = {
    "intro":           "INTRO",
    "approach":        "SECTION 3 — Functional Multiplicity: An Approach to Living with DID & Related Disorders",
    "characteristics": "SECTION 4 — Characteristics. Not Symptoms.",
    "exocortex":       "SECTION 5 — The Exocortex",
}

parser = SectionExtractor()
parser.feed(html)

out = []
out.append("# LIVE SITE COPY — functionalmultiplicity.com")
out.append("")
out.append(f"**Source:** https://functionalmultiplicity.com")
out.append(f"**Last fetched:** {today}")
out.append("**Purpose:** Reference snapshot of live site. Maintained via WORKFLOW 003 — SITE-COPY-SYNC.")
out.append("> ⚠️ Overwritten on every sync. Do not edit directly.")
out.append("")

for sid, lines in parser.sections:
    out.append(f"## {LABELS.get(sid, sid)}")
    out.append("")
    out.extend(lines)
    out.append("---")
    out.append("")

print("\n".join(out))
