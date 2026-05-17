# hamtag

**Author:** Matt Hoskins, K2TTA — k2tta@arrl.net

A command-line tool that generates ZPL name badge labels for Zebra thermal printers.
Looks up HAM callsigns in a [hamdat](https://github.com/sysmatt/hamdat) SQLite database
and produces landscape-oriented badges on standard 4"×6" label stock.

---

## Requirements

- Python 3.9+
- A [hamdat](https://github.com/sysmatt/hamdat) database at `~/.hamdat/hamdat.db`  
  *(required for callsign lookup; manual `--name`/`--location` works without it)*
- A Zebra thermal label printer loaded with 4"×6" label stock

No third-party Python packages are required — only the standard library.

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
       [--db PATH] [--dpi {203,300}]
       [--output FILE] [--printer [DEVICE]]
```

### Options

| Flag | Description |
|---|---|
| `--call CALLSIGN` | HAM callsign to look up in the hamdat database |
| `--name NAME` | Operator name — overrides the database value |
| `--location TEXT` | Location line, e.g. `Hoboken, NJ` — overrides the database value |
| `--banner TEXT` | Banner text at the top of the badge (e.g. `HAMFEST VOLUNTEER`) |
| `--note TEXT` | Small text pinned to the bottom of the badge |
| `--db PATH` | hamdat SQLite database path (default: `~/.hamdat/hamdat.db`) |
| `--dpi {203,300}` | Printer resolution — `203` (default) or `300` |
| `--output FILE` | Save ZPL to a file |
| `--printer [DEVICE]` | Send ZPL directly to USB printer (default device: `/dev/usb/lp0`) |

At least one of `--call` or `--name` is required.

---

## Examples

```bash
# Look up K2TTA and print to stdout
hamtag --call K2TTA

# Full badge with banner and note, sent directly to the USB printer
hamtag --call K2TTA --banner "HAMFEST VOLUNTEER" --note "ARRL Field Day 2026" --printer

# Send to a non-default printer device
hamtag --call W1AW --banner "GUEST" --printer /dev/usb/lp1

# Override the name and location from the database
hamtag --call K2TTA --name "Matt Hoskins" --location "Lafayette, NJ"

# Manual entry (no DB lookup)
hamtag --name "Guest Operator" --location "Newington, CT" --banner "ARRL MEMBER"

# Save ZPL to a file for later use
hamtag --call K2TTA --banner "VOLUNTEER" --output badge.zpl

# Save to file AND send to printer in one shot
hamtag --call K2TTA --banner "ELMERFEST 2026" --output badge.zpl --printer

# Network printer (pipe to netcat)
hamtag --call K2TTA --banner "VOLUNTEER" | nc 192.168.1.100 9100

# 300 DPI printer
hamtag --call K2TTA --dpi 300 --printer
```

---

## Label layout

The physical label is 4"×6" (portrait on the printer roll).  All content is
rotated 90° clockwise in ZPL so the badge reads correctly when the label is
oriented in landscape (6" wide, 4" tall):

```
┌──────────────────────────────────────────────────────────┐
│                  HAMFEST VOLUNTEER                        │  ← --banner
│  ──────────────────────────────────────────────────────  │
│                       K2TTA                               │  ← callsign (large)
│  ──────────────────────────────────────────────────────  │
│                  Matthew E Hoskins                        │  ← name
│                    Lafayette, NJ                          │  ← city, state
│                                                           │
│                  ARRL Field Day 2026                      │  ← --note
└──────────────────────────────────────────────────────────┘
```

---

## Previewing ZPL

To preview a label without a printer, pipe the ZPL output into the
[Labelary online viewer](http://labelary.com/viewer.html), or save to a
`.zpl` file and upload it there.

```bash
hamtag --call K2TTA --banner "TEST" --output preview.zpl
# then upload preview.zpl to labelary.com/viewer.html
```

---

## Printer notes

- Default DPI is **203**, which is correct for the Zebra LP2844, GX420d, ZD420, and most
  desktop label printers.  Use `--dpi 300` for higher-resolution models (ZD620, ZT410, etc.).
- The label home (`^LH0,0`) and media type are left at printer defaults; adjust your
  printer's configuration via ZPL `^PR` (print speed) and `^MD` (darkness) if needed.
- To send multiple badges in a single print job, concatenate the ZPL outputs — each
  `^XA...^XZ` block is one label.
