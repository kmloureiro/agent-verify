#!/usr/bin/env python3
"""measure_tokens.py — count the tokens a verification payload injects into context.

Honest and reproducible: reports raw bytes + a token estimate. If `tiktoken` is
installed it uses cl100k_base (a real BPE tokenizer); otherwise it falls back to a
documented chars/divisor heuristic. Claude has no public tokenizer, so treat token
counts as estimates (±15%); the RATIO between modes is the robust signal.

Usage:
    measure_tokens.py text <file>          # tokens of a text payload (DOM/snapshot/CLI output)
    measure_tokens.py image <W> <H>        # tokens of a screenshot of W×H px (Anthropic formula)
    measure_tokens.py compare <cli_file> <browser_file> [screenshot WxH]
"""
import sys
import os

CHARS_PER_TOKEN = 3.6  # conservative estimate for mixed DOM/code/English


def count_text_tokens(text: str) -> int:
    try:
        import tiktoken
        return len(tiktoken.get_encoding("cl100k_base").encode(text))
    except Exception:
        return round(len(text) / CHARS_PER_TOKEN)


def count_image_tokens(w: int, h: int) -> int:
    # Anthropic: image tokens ~= (width px * height px) / 750
    return round((w * h) / 750)


def _fmt(n: int) -> str:
    return f"{n:,}"


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    mode = argv[1]

    if mode == "text":
        with open(argv[2], "r", errors="replace") as f:
            data = f.read()
        print(f"bytes={_fmt(len(data.encode()))} tokens~={_fmt(count_text_tokens(data))}")
        return 0

    if mode == "image":
        w, h = int(argv[2]), int(argv[3])
        print(f"{w}x{h}px tokens~={_fmt(count_image_tokens(w, h))}")
        return 0

    if mode == "compare":
        cli = open(argv[2], errors="replace").read()
        browser = open(argv[3], errors="replace").read()
        cli_t = count_text_tokens(cli)
        br_t = count_text_tokens(browser)
        shot_t = 0
        if len(argv) >= 5 and "x" in argv[4]:
            w, h = (int(x) for x in argv[4].lower().split("x"))
            shot_t = count_image_tokens(w, h)
        browser_total = br_t + shot_t
        ratio = (browser_total / cli_t) if cli_t else float("inf")
        print("mode          tokens~")
        print(f"CLI           {_fmt(cli_t)}")
        print(f"browser DOM   {_fmt(br_t)}")
        if shot_t:
            print(f"+ screenshot  {_fmt(shot_t)}")
            print(f"browser total {_fmt(browser_total)}")
        print(f"ratio         {ratio:.0f}x  (browser / CLI)")
        print(f"saved/verify  {_fmt(browser_total - cli_t)} tokens")
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
