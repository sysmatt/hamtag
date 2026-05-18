# hamtag

**Author:** Matt Hoskins, K2TTA — k2tta@arrl.net

> **Sister project:** hamtag works hand-in-hand with **hamdat**, which downloads and indexes the FCC
> amateur license database into a local SQLite file that hamtag looks up callsigns from.
> https://github.com/sysmatt/hamdat

A command-line tool (with optional GUI) that generates ZPL name badge labels for Zebra thermal printers.
Looks up HAM callsigns in a [hamdat](https://github.com/sysmatt/hamdat) SQLite database and produces
labels on standard 4"×6" or 4"×2" label stock.

---

## Requirements

- Python 3.9+
- [Pillow](https://pillow.readthedocs.io/) — `pip install Pillow`
- A [hamdat](https://github.com/sysmatt/hamdat) database at `~/.hamdat/hamdat.db`  
  *(required for callsign lookup; manual `--name`/`--location` works without it)*
- A Zebra thermal label printer loaded with 4"×6" or 4"×2" label stock

### GUI mode additional requirements

```bash
sudo apt install python3-tk python3-pil.imagetk
```

### Font with slashed zero (recommended)

```bash
sudo apt install fonts-hack
```

The callsign font is auto-detected from installed system fonts.  Hack is preferred because it has a
slashed zero, making callsigns like `K0TTA` unambiguous.  See `--font` to specify a custom TTF.

---

## Installation

```bash
chmod +x hamtag
cp hamtag ~/bin/      # or anywhere on your PATH
```

### USB printer permissions (Linux)

To send ZPL directly to a USB printer without `sudo`, add yourself to the `lp` group:

```bash
sudo usermod -aG lp $USER
```

Then log out and back in.  To apply immediately without logging out:

```bash
sudo chmod a+rw /dev/usb/lp0
```

---

## Usage

```
hamtag [--call CALLSIGN] [--name NAME] [--location TEXT]
       [--banner TEXT] [--note TEXT]
       [--label {4x6,4x2}] [--dpi {203,300}]
       [--db PATH] [--font FILE]
       [--output FILE] [--printer [DEVICE]]
       [--gui]
```

### Options

| Flag | Description |
|---|---|
| `--call CALLSIGN` | HAM callsign to look up in the hamdat database |
| `--name NAME` | Operator name — overrides the database value |
| `--location TEXT` | Location line, e.g. `Hoboken, NJ` — overrides the database value |
| `--banner TEXT` | Banner text at the top of the badge (e.g. `HAMFEST VOLUNTEER`) |
| `--note TEXT` | Small text pinned to the bottom of the badge |
| `--label {4x6,4x2}` | Label stock — `4x6` landscape badge (default) or `4x2` portrait |
| `--dpi {203,300}` | Printer resolution — `203` (default) or `300` |
| `--db PATH` | hamdat SQLite database path (default: `~/.hamdat/hamdat.db`) |
| `--font FILE` | TrueType font for all text (auto-detected if omitted) |
| `--output FILE` | Save ZPL to a file |
| `--printer [TARGET]` | Send ZPL to a USB device (default: `/dev/usb/lp0`) or network printer (`host[:port]`, default port 9100) |
| `--gui` | Launch interactive GUI — other flags pre-fill the form |

At least one of `--call` or `--name` is required in CLI mode.

---

## GUI mode

Launch with `--gui` for an interactive badge-printing workflow:

```bash
hamtag --gui
hamtag --gui --banner "HAMFEST VOLUNTEER" --note "ARRL Field Day 2026"
```

The GUI shows a live preview that updates as you type.  The intended workflow at an event is:

1. Type a callsign and press **Enter** → database lookup fills Name and Location
2. Press **Enter** again (or click **Print It!**) → label prints

**Banner** and **Note** are preserved between badges (they're event-level constants).
The **Default** button (or **Escape**) restores Banner/Note to the values passed on the command
line and clears the per-badge fields, ready for the next operator.

---

## Examples

```bash
# Interactive GUI with event banner and note pre-filled
hamtag --gui --banner "HAMFEST VOLUNTEER" --note "ARRL Field Day 2026"

# Look up K2TTA and print to stdout
hamtag --call K2TTA

# Full badge sent directly to the USB printer
hamtag --call K2TTA --banner "HAMFEST VOLUNTEER" --note "ARRL Field Day 2026" --printer

# 4x2 label stock
hamtag --call K2TTA --label 4x2 --printer

# Send to a non-default printer device
hamtag --call W1AW --banner "GUEST" --printer /dev/usb/lp1

# Override the name and location from the database
hamtag --call K2TTA --name "Matt Hoskins" --location "Lafayette, NJ"

# Manual entry (no DB lookup)
hamtag --name "Guest Operator" --location "Newington, CT" --banner "ARRL MEMBER"

# Save ZPL to a file for later use or preview
hamtag --call K2TTA --banner "VOLUNTEER" --output badge.zpl

# Save to file AND send to printer in one shot
hamtag --call K2TTA --banner "ELMERFEST 2026" --output badge.zpl --printer

# Network printer (auto-detected by hostname/IP)
hamtag --call K2TTA --banner "VOLUNTEER" --printer 192.168.1.100
hamtag --call K2TTA --banner "VOLUNTEER" --printer printer.local:9100

# 300 DPI printer
hamtag --call K2TTA --dpi 300 --printer
```

---

## Label layouts

### 4×6 (default) — landscape badge

The physical label is 4"×6" portrait on the printer roll.  The entire label is rendered as a PIL
bitmap and rotated 90° clockwise, so the badge reads correctly in landscape orientation
(6" wide, 4" tall when worn):

```
┌──────────────────────────────────────────────────────────┐
│                  HAMFEST VOLUNTEER                       │  ← --banner
│  ──────────────────────────────────────────────────────  │
│                       K2TTA                              │  ← callsign (large, auto-sized)
│  ──────────────────────────────────────────────────────  │
│                  Matthew E Hoskins                       │  ← name
│                    Lafayette, NJ                         │  ← city, state
│                                                          │
│                  ARRL Field Day 2026                     │  ← --note
└──────────────────────────────────────────────────────────┘
```

### 4×2 — portrait label

Rendered at 4"×2" with no rotation — suitable for smaller adhesive labels or table tents:

```
┌──────────────────────────────────────────┐
│            HAMFEST VOLUNTEER             │  ← --banner
│  ──────────────────────────────────────  │
│                  K2TTA                   │  ← callsign (auto-sized)
│  ──────────────────────────────────────  │
│           Matthew E Hoskins              │  ← name
│              Lafayette, NJ               │  ← city, state
│            ARRL Field Day 2026           │  ← --note
└──────────────────────────────────────────┘
```

---

## Previewing ZPL

To preview a label without a printer, save to a `.zpl` file and upload it to the
[Labelary online viewer](http://labelary.com/viewer.html):

```bash
hamtag --call K2TTA --banner "TEST" --output preview.zpl
# then upload preview.zpl to labelary.com/viewer.html
```

---

## Printer notes

- Default DPI is **203**, which is correct for the Zebra LP2844, GX420d, ZD420, and most
  desktop label printers.  Use `--dpi 300` for higher-resolution models (ZD620, ZT410, etc.).
- The entire label is sent as a single bitmap (`^GFA` graphic field), so printer font support
  is irrelevant — any TTF font installed on the host machine can be used.
- To send multiple badges in a single print job, concatenate ZPL outputs — each `^XA...^XZ`
  block is one label.
