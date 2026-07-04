#!/usr/bin/env python3
import json, sys, os, re, subprocess

data = json.load(sys.stdin)

# ANSI escape codes
R = '\033[0m'
DIM = '\033[2m'
BOLD = '\033[1m'
BLOCKS = ' \u258f\u258e\u258d\u258c\u258b\u258a\u2589\u2588'


def gradient(pct):
    # Gruvbox: green → yellow → orange → red
    stops = [
        (0,   0xb8, 0xbb, 0x26),  # #b8bb26 green
        (33,  0xfa, 0xbd, 0x2f),  # #fabd2f yellow
        (66,  0xfe, 0x80, 0x19),  # #fe8019 orange
        (100, 0xfb, 0x49, 0x34),  # #fb4934 red
    ]
    pct = min(max(pct, 0), 100)
    for i in range(len(stops) - 1):
        p0, r0, g0, b0 = stops[i]
        p1, r1, g1, b1 = stops[i + 1]
        if pct <= p1:
            t = (pct - p0) / (p1 - p0) if p1 != p0 else 0
            r = int(r0 + (r1 - r0) * t)
            g = int(g0 + (g1 - g0) * t)
            b = int(b0 + (b1 - b0) * t)
            return f'\033[38;2;{r};{g};{b}m'
    return f'\033[38;2;{stops[-1][1]};{stops[-1][2]};{stops[-1][3]}m'


def bar(pct, width=10):
    pct = min(max(pct, 0), 100)
    filled = pct * width / 100
    full = int(filled)
    frac = int((filled - full) * 8)
    b = '\u2588' * full
    if full < width:
        b += BLOCKS[frac]
        b += '\u2591' * (width - full - 1)
    return b


def fmt(label, pct):
    p = round(pct)
    return f'{label} {gradient(pct)}{bar(pct)} {p}%{R}'


def format_tokens(total):
    if total >= 1_000_000:
        return f'{total / 1_000_000:.1f}M'
    elif total >= 1_000:
        return f'{total / 1_000:.1f}k'
    return str(total)


def portless_url(cwd, branch, branch_is_symbolic):
    """起動中の portless ルートの URL を返す。なければ ''（失敗も常に ''）。"""
    try:
        state_dir = os.environ.get('PORTLESS_STATE_DIR') or os.path.expanduser('~/.portless')
        routes_path = os.path.join(state_dir, 'routes.json')
        if not cwd or not os.path.isfile(routes_path):
            return ''
        with open(routes_path) as f:
            routes = json.load(f)
        if not isinstance(routes, list) or not routes:
            return ''

        def sanitize(name):
            s = re.sub(r'[^a-z0-9-]', '-', name.lower())
            s = re.sub(r'-{2,}', '-', s)
            return s.strip('-')

        # base 名の導出（portless 本体と同じ優先順）
        pkg_portless = pkg_name = pl_name = git_root = ''
        d = cwd
        while True:
            if not (pkg_name or pkg_portless):
                try:
                    with open(os.path.join(d, 'package.json')) as f:
                        pkg = json.load(f)
                    p = pkg.get('portless')
                    if isinstance(p, str):
                        pkg_portless = p
                    elif isinstance(p, dict) and isinstance(p.get('name'), str):
                        pkg_portless = p['name']
                    if isinstance(pkg.get('name'), str):
                        pkg_name = re.sub(r'^@[^/]+/', '', pkg['name'])
                except (OSError, ValueError):
                    pass
            if not pl_name:
                try:
                    with open(os.path.join(d, 'portless.json')) as f:
                        pl = json.load(f)
                    if isinstance(pl.get('name'), str):
                        pl_name = pl['name']
                except (OSError, ValueError):
                    pass
            if not git_root and os.path.exists(os.path.join(d, '.git')):
                git_root = d
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
        base = ''
        for cand in (pkg_portless, pl_name, pkg_name,
                     os.path.basename(git_root) if git_root else ''):
            if cand and sanitize(cand):
                base = sanitize(cand)
                break
        if not base:
            return ''

        # linked worktree のみブランチ最終セグメントを prefix（portless と同じ規則）
        prefix = ''
        if git_root and os.path.isfile(os.path.join(git_root, '.git')):
            if branch_is_symbolic and branch not in ('main', 'master', 'HEAD'):
                prefix = sanitize(branch.split('/')[-1])
        effective = f'{prefix}.{base}' if prefix else base
        hostname = f'{effective}.localhost'

        for r in routes:
            if not isinstance(r, dict) or r.get('hostname') != hostname:
                continue
            try:
                os.kill(int(r['pid']), 0)
            except (ProcessLookupError, ValueError, TypeError, OverflowError, KeyError):
                return ''
            except PermissionError:
                pass  # 生存しているが別ユーザー
            tls = os.path.isfile(os.path.join(state_dir, 'proxy.tls'))
            port = 443 if tls else 80
            try:
                with open(os.path.join(state_dir, 'proxy.port')) as f:
                    port = int(f.read().strip())
            except (OSError, ValueError):
                pass
            proto = 'https' if tls else 'http'
            if port == (443 if tls else 80):
                return f'{proto}://{hostname}'
            return f'{proto}://{hostname}:{port}'
        return ''
    except Exception:
        return ''


# --- Data extraction ---
cwd = data.get('workspace', {}).get('current_dir') or data.get('cwd', '')
project_dir = data.get('workspace', {}).get('project_dir') or ''
model = data.get('model', {}).get('display_name', '')
effort = os.environ.get('CLAUDE_CODE_EFFORT_LEVEL', '')
ctx_pct = data.get('context_window', {}).get('used_percentage')
total_in = data.get('context_window', {}).get('total_input_tokens')
total_out = data.get('context_window', {}).get('total_output_tokens')
transcript = data.get('transcript_path', '')
five_pct = data.get('rate_limits', {}).get('five_hour', {}).get('used_percentage')
week_pct = data.get('rate_limits', {}).get('seven_day', {}).get('used_percentage')

# Worktree name: --worktree session or linked worktree via workspace.git_worktree
worktree_name = (
    (data.get('worktree') or {}).get('name')
    or data.get('workspace', {}).get('git_worktree')
    or ''
)

# Session slug from transcript JSONL
session_slug = ''
if transcript and os.path.isfile(transcript):
    try:
        with open(transcript, 'r') as f:
            for i, line in enumerate(f):
                if i >= 5:
                    break
                try:
                    obj = json.loads(line)
                    slug = obj.get('slug', '')
                    if slug:
                        session_slug = slug
                        break
                except json.JSONDecodeError:
                    continue
    except OSError:
        pass

# Git branch
branch = ''
branch_is_symbolic = False
if cwd:
    try:
        result = subprocess.run(
            ['git', '-C', cwd, 'symbolic-ref', '--short', 'HEAD'],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            branch_is_symbolic = True
        else:
            result = subprocess.run(
                ['git', '-C', cwd, 'rev-parse', '--short', 'HEAD'],
                capture_output=True, text=True, timeout=2
            )
            if result.returncode == 0:
                branch = result.stdout.strip()
    except (subprocess.TimeoutExpired, OSError):
        pass

# --- Line 1: Directory + Session slug ---
# Use project_dir (repo root) as the display name; fall back to cwd basename
display_dir = os.path.basename(project_dir) if project_dir else (os.path.basename(cwd) if cwd else '')
short_cwd = f'\U0001f4c2 {display_dir}' if display_dir else ''
line1 = short_cwd
if session_slug:
    line1 += f'  \U0001f506 {session_slug}'

# --- Line 2: Git branch + Worktree + Model + Effort ---
parts2 = []
if branch:
    branch_str = branch
    if worktree_name:
        branch_str += f'  \U0001f333 {worktree_name}'
    parts2.append(branch_str)
if model:
    model_str = model
    if effort:
        model_str += f'  [{effort}]'
    parts2.append(model_str)
url = portless_url(cwd, branch, branch_is_symbolic)
if url:
    parts2.append(f'\U0001f310 {url}')
line2 = '  '.join(parts2)

# --- Line 3: Context bar + tokens | 5h bar | 7d bar ---
parts3 = []

# Context bar (Pattern 4 style)
ctx_section = ''
if ctx_pct is not None:
    ctx_section = fmt('ctx', ctx_pct)

# Token count
if total_in is not None and total_out is not None:
    total = total_in + total_out
    tok = format_tokens(total)
    if ctx_section:
        ctx_section += f'  tokens:{tok}'
    else:
        ctx_section = f'tokens:{tok}'

if ctx_section:
    parts3.append(ctx_section)

# Rate limits (Pattern 4 style)
if five_pct is not None:
    parts3.append(fmt('5h', five_pct))
if week_pct is not None:
    parts3.append(fmt('7d', week_pct))

line3 = f' {DIM}\u2502{R} '.join(parts3)

# --- Output ---
lines = [l for l in [line1, line2, line3] if l]
print('\n'.join(lines), end='')
