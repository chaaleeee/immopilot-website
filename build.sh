#!/bin/sh
# Erzeugt die deutsche Seite de/index.html aus index.html (gleiche Vorlage, Texte aus data-de).
# Vor jedem Push ausführen. Braucht Google Chrome und einen lokalen Server (python3 http.server).
set -e
cd "$(dirname "$0")"
# FAQ-Markup (FR) statisch in index.html schreiben, damit es ohne JavaScript lesbar ist
python3 - <<'PY'
import re, json, html
p='index.html'; s=open(p).read()
items=[]
for m in re.finditer(r'<summary data-fr="([^"]*)"[^>]*>.*?<p class="faq-a" data-fr="([^"]*)"', s, re.S):
    items.append({'@type':'Question','name':html.unescape(m.group(1)),'acceptedAnswer':{'@type':'Answer','text':html.unescape(m.group(2))}})
ld=json.dumps({'@context':'https://schema.org','@type':'FAQPage','inLanguage':'fr','mainEntity':items}, ensure_ascii=False)
s=re.sub(r'(<script type="application/ld\+json" id="faq-ld">).*?(</script>)', lambda m: m.group(1)+ld+m.group(2), s, flags=re.S)
open(p,'w').write(s); print('FAQ-Markup FR:', len(items), 'Fragen')
PY
mkdir -p de /tmp/immopilot_site_build/de
cp index.html /tmp/immopilot_site_build/de/index.html
cp -R img /tmp/immopilot_site_build/img
PORT=8765
(cd /tmp/immopilot_site_build && python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1) &
SRV=$!
sleep 1
{ echo '<!DOCTYPE html>'; "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --virtual-time-budget=3000 --dump-dom "http://127.0.0.1:$PORT/de/index.html" 2>/dev/null; } > de/index.html
kill $SRV 2>/dev/null || true
rm -rf /tmp/immopilot_site_build
grep -q 'lang="de"' de/index.html && echo "de/index.html erzeugt" || { echo "FEHLER: deutsche Seite nicht erzeugt"; exit 1; }
