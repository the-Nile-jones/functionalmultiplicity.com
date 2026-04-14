#!/usr/bin/env python3
"""
FM Site — Structural Audit

Usage:
  python3 scripts/audit.py          # local / static checks only (fast)
  python3 scripts/audit.py --live   # also run live HTTP + header checks

Covers:
  - Internal link + anchor integrity
  - Tooltip/DICT coverage (data-did wraps vs did-tooltip.js DICT keys)
  - Pages with tooltips must have the did-tooltip div + script
  - Cache-bust version consistency (did-tooltip.js, styles*.css)
  - Naming hygiene (stale "Handbook", bare "Story")
  - Metadata sanity (canonical vs og:url, H1 count per page)
  - Skip-link target existence

No changes made. Report-only.

Requires running from repo root.
"""
import os, re, subprocess, sys, time
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)


def collect_pages():
    pages = sorted(f for f in subprocess.check_output(['git', 'ls-files', '*.html']).decode().split()
                   if not f.startswith('assets/') and not f.endswith('.bak'))
    all_tracked = set(subprocess.check_output(['git', 'ls-files']).decode().split())
    for root, _, fs in os.walk('.'):
        if '/.git' in root: continue
        for fn in fs:
            all_tracked.add(os.path.join(root, fn).lstrip('./'))
    return pages, all_tracked


def url_to_files(u):
    if u == '/' or u == '': return ['index.html']
    p = u.lstrip('/').rstrip('/')
    return [p, p + '.html', p + '/index.html']


def main():
    live = '--live' in sys.argv

    pages, all_tracked = collect_pages()
    page_content = {f: open(f).read() for f in pages}

    href_rx = re.compile(r'href="([^"]+)"')
    src_rx = re.compile(r'src="([^"]+)"')
    id_rx = re.compile(r'\sid="([^"]+)"')
    ids_in_page = {f: set(id_rx.findall(c)) for f, c in page_content.items()}

    broken = {'internal': [], 'anchor_same': [], 'anchor_cross': []}
    total_hrefs = 0
    external = []

    for f, content in page_content.items():
        for link in href_rx.findall(content) + src_rx.findall(content):
            total_hrefs += 1
            if link.startswith(('mailto:', 'tel:', 'data:', 'javascript:')):
                continue
            if link.startswith(('http://', 'https://')):
                external.append((f, link))
                continue
            if link.startswith('#'):
                target = link[1:]
                if target == 'main' or target in ids_in_page[f]:
                    continue
                broken['anchor_same'].append((f, link))
                continue
            if link.startswith('/'):
                path, _, frag = link.partition('#')
                path_clean = path.split('?')[0]
                cands = url_to_files(path_clean)
                tgt = next((c for c in cands if c in all_tracked), None)
                if not tgt:
                    broken['internal'].append((f, link, cands))
                elif frag and tgt.endswith('.html'):
                    if frag not in ids_in_page.get(tgt, set()):
                        broken['anchor_cross'].append((f, link, tgt, frag))

    # Tooltip/DICT
    dict_js = open('did-tooltip.js').read()
    dict_keys = set(re.findall(r'^\s+"([^"]+)":\s*\{', dict_js, re.MULTILINE))
    wrap_rx = re.compile(r'<span class="did-term" data-did="([^"]+)">([^<]+)</span>')
    wrap_by_page = defaultdict(list)
    for f, c in page_content.items():
        for k, v in wrap_rx.findall(c):
            wrap_by_page[f].append((k, v))
    all_wraps = {k for ws in wrap_by_page.values() for k, _ in ws}
    missing = all_wraps - dict_keys
    unused = dict_keys - all_wraps
    pages_with_wraps = [f for f, w in wrap_by_page.items() if w]
    no_div = [f for f in pages_with_wraps if 'id="did-tooltip"' not in page_content[f]]
    no_script = [f for f in pages_with_wraps if '/did-tooltip.js' not in page_content[f]]

    # Cache-bust versions
    js_vers = defaultdict(list)
    css_vers = defaultdict(list)
    for f, c in page_content.items():
        for m in re.finditer(r'did-tooltip\.js\?v=(\d+)', c):
            js_vers[m.group(1)].append(f)
        for m in re.finditer(r'styles(-additions)?\.css\?v=(\d+)', c):
            css_vers[m.group(2)].append(f)

    # Naming
    stale_handbook = []
    for f, c in page_content.items():
        stripped = re.sub(r'<script\b[^>]*>.*?</script>', '', c, flags=re.DOTALL)
        stripped = re.sub(r'<style\b[^>]*>.*?</style>', '', stripped, flags=re.DOTALL)
        stripped = re.sub(r'class="[^"]*"|id="[^"]*"|aria-labelledby="[^"]*"', '', stripped)
        stripped = re.sub(r'<!--.*?-->', '', stripped, flags=re.DOTALL)
        for m in re.finditer(r'>\s*([^<]*Handbook[^<]*)\s*<', stripped):
            txt = m.group(1).strip()
            if txt and len(txt) < 250:
                stale_handbook.append((f, txt))

    # Meta
    meta_issues = []
    for f, c in page_content.items():
        canon_m = re.search(r'<link rel="canonical" href="([^"]+)"', c)
        ogurl_m = re.search(r'<meta property="og:url" content="([^"]+)"', c)
        if canon_m and ogurl_m and canon_m.group(1) != ogurl_m.group(1):
            meta_issues.append((f, 'canonical/og:url mismatch'))
        h1s = re.findall(r'<h1[^>]*>([^<]+)</h1>', c)
        if not h1s:
            meta_issues.append((f, 'no H1'))
        elif len(h1s) > 1:
            meta_issues.append((f, f'multiple H1s ({len(h1s)})', h1s))

    # Skip-links
    skip_issues = []
    for f, c in page_content.items():
        m = re.search(r'<a href="#([^"]+)" class="skip-link"', c)
        if m and m.group(1) not in ids_in_page[f]:
            skip_issues.append((f, m.group(1)))

    print("═══════════════════════════════════════════════")
    print("  FM Site Audit")
    print("═══════════════════════════════════════════════")
    print(f"Scope: {len(pages)} HTML pages, {total_hrefs} hrefs")
    print()

    def ok(label): print(f"  ✓ {label}")
    def warn(label): print(f"  ⚠️  {label}")

    print("## Link Integrity")
    ok("No broken internal links") if not broken['internal'] else [warn(f"{f} -> {h}") for f, h, _ in broken['internal']]
    ok("No broken same-page anchors") if not broken['anchor_same'] else [warn(f"{f} -> {h}") for f, h in broken['anchor_same']]
    ok("No broken cross-page anchors") if not broken['anchor_cross'] else [warn(f"{f} -> {h} (target {t} has no #{fg})") for f, h, t, fg in broken['anchor_cross']]

    print("\n## Tooltip / DICT")
    print(f"  {len(dict_keys)} DICT keys | {len(all_wraps)} unique wraps | {len(pages_with_wraps)}/{len(pages)} pages use tooltips")
    if missing: warn(f"WRAPS MISSING DICT ENTRY: {sorted(missing)}")
    else: ok("every data-did key has a DICT entry")
    if no_div: warn(f"pages with wraps but no #did-tooltip div: {no_div}")
    else: ok("every page with wraps has the tooltip div")
    if no_script: warn(f"pages with wraps but no script tag: {no_script}")
    else: ok("every page with wraps loads did-tooltip.js")
    if unused:
        print(f"  {len(unused)} DICT keys unused on any page (dead weight candidates):")
        for k in sorted(unused): print(f"    \"{k}\"")

    print("\n## Cache-Bust")
    print(f"  did-tooltip.js ?v= versions: {dict(js_vers)}")
    if len(js_vers) == 1: ok("consistent")
    else: warn("mismatch — should be one version site-wide")
    print(f"  styles*.css ?v= versions: {dict(css_vers)}")
    if len(css_vers) == 1: ok("consistent")
    else: warn("mismatch")

    print("\n## Naming")
    if stale_handbook:
        warn(f"{len(stale_handbook)} stale 'Handbook' mentions")
        for f, t in stale_handbook[:5]: print(f"    {f}: {t[:140]}")
    else: ok("no stale 'Handbook' in body text")

    print("\n## Meta / SEO")
    if meta_issues:
        for issue in meta_issues: warn(str(issue))
    else: ok("canonical matches og:url; H1 count OK")

    print("\n## Skip-links")
    if skip_issues:
        for f, t in skip_issues: warn(f"{f} -> #{t} (target missing)")
    else: ok("all skip-links valid")

    if live:
        print("\n═══════════════════════════════════════════════")
        print("  Live HTTP + Cache Header")
        print("═══════════════════════════════════════════════")
        base = "https://functionalmultiplicity.com"
        routes = sorted(set('/' + f.replace('.html', '').replace('/index', '') for f in pages))
        routes = [r.rstrip('/') if r != '/' else r for r in routes]
        for r in routes:
            url = base + r
            cb = str(int(time.time() * 1000000))
            sep = '&' if '?' in url else '?'
            try:
                code = subprocess.check_output(
                    ["curl", "-sL", "-o", "/dev/null", "-w", "%{http_code}",
                     "-H", "Cache-Control: no-cache", url + sep + "cb=" + cb],
                    stderr=subprocess.DEVNULL).decode()
                hdrs = subprocess.check_output(
                    ["curl", "-sLI", "-H", "Cache-Control: no-cache", url + sep + "cb=" + cb],
                    stderr=subprocess.DEVNULL).decode()
                cc = re.search(r'cache-control:\s*(.+)', hdrs, re.IGNORECASE)
                cc_val = cc.group(1).strip() if cc else '-'
                cc_count = len(re.findall(r'^cache-control:', hdrs, re.IGNORECASE | re.MULTILINE))
                extra = f' [{cc_count} CC]' if cc_count > 1 else ''
                mark = '  ✓' if code == '200' else '  ⚠️'
                print(f"{mark} {code}  {r:50s}  {cc_val[:50]}{extra}")
            except Exception as e:
                print(f"  ⚠️  ERROR {r}: {e}")


if __name__ == '__main__':
    main()
