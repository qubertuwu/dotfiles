#!/usr/bin/env python3
import sys
import os
import subprocess
import csv
import io
import json
import urllib.request
import urllib.parse

def translate_lines(lines_to_translate, source_lang="en", target_lang="ru"):
    translations = {}
    if not lines_to_translate:
        return translations

    batches = []
    current_batch = []
    current_len = 0

    for text in lines_to_translate:
        t_len = len(text)
        if current_batch and (current_len + t_len > 1200 or len(current_batch) >= 25):
            batches.append(current_batch)
            current_batch = []
            current_len = 0
        current_batch.append(text)
        current_len += t_len

    if current_batch:
        batches.append(current_batch)

    for batch in batches:
        combined = "\n".join(batch)
        url = (
            "https://clients5.google.com/translate_a/t?client=dict-chrome-ex"
            f"&sl={urllib.parse.quote(source_lang)}"
            f"&tl={urllib.parse.quote(target_lang)}"
            f"&q={urllib.parse.quote(combined)}"
        )
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        )
        try:
            with urllib.request.urlopen(req, timeout=6) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                if isinstance(data, list):
                    trans_text = data[0] if (len(data) == 1 and isinstance(data[0], str)) else "\n".join(str(x) for x in data)
                elif isinstance(data, str):
                    trans_text = data
                else:
                    trans_text = str(data)

                trans_lines = trans_text.split("\n")
                for orig, tr in zip(batch, trans_lines):
                    translations[orig] = tr.strip()
        except Exception:
            for orig in batch:
                translations[orig] = orig

    return translations

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"paragraphs": [], "translations": {}, "error": "No image provided"}))
        return

    img_path = sys.argv[1]
    if not os.path.exists(img_path):
        print(json.dumps({"paragraphs": [], "translations": {}, "error": f"File not found: {img_path}"}))
        return

    # Run tesseract with TSV output
    cmd = ["tesseract", img_path, "stdout", "--oem", "1", "-c", "tessedit_do_invert=0", "tsv"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    except Exception as e:
        print(json.dumps({"paragraphs": [], "translations": {}, "error": str(e)}))
        return

    if res.returncode != 0:
        print(json.dumps({"paragraphs": [], "translations": {}, "error": res.stderr}))
        return

    reader = csv.DictReader(io.StringIO(res.stdout), delimiter='\t')
    grouped_lines = {}

    for row in reader:
        text = (row.get('text') or '').strip()
        try:
            conf = float(row.get('conf') or -1)
        except ValueError:
            conf = -1

        if text and conf > 15:
            key = (row.get('page_num', '1'), row.get('block_num', '0'), row.get('par_num', '0'), row.get('line_num', '0'))
            if key not in grouped_lines:
                grouped_lines[key] = []
            grouped_lines[key].append(row)

    paragraphs = []
    lines_to_translate = []

    for key, words in grouped_lines.items():
        line_text = " ".join(w['text'] for w in words).strip()
        if not line_text or len(line_text) < 2:
            continue
        # Require at least one letter
        if not any(c.isalpha() for c in line_text):
            continue

        try:
            x1 = min(int(w['left']) for w in words)
            y1 = min(int(w['top']) for w in words)
            x2 = max(int(w['left']) + int(w['width']) for w in words)
            y2 = max(int(w['top']) + int(w['height']) for w in words)
        except (ValueError, KeyError):
            continue

        pad_x = 2
        pad_y = 1
        x1 = max(0, x1 - pad_x)
        y1 = max(0, y1 - pad_y)
        x2 = x2 + pad_x
        y2 = y2 + pad_y

        paragraphs.append({
            "text": line_text,
            "boundingBox": {
                "vertices": [
                    {"x": x1, "y": y1},
                    {"x": x2, "y": y1},
                    {"x": x2, "y": y2},
                    {"x": x1, "y": y2}
                ]
            }
        })
        lines_to_translate.append(line_text)

    translations = translate_lines(lines_to_translate, source_lang="en", target_lang="ru")

    output = {
        "paragraphs": paragraphs,
        "translations": translations
    }
    print(json.dumps(output, ensure_ascii=False))

if __name__ == "__main__":
    main()
