# hamtag

**Author:** Matt Hoskins, K2TTA — k2tta@arrl.net

> **Sister project:** hamtag works hand-in-hand with **hamdat**, which downloads and indexes the FCC
> amateur license database into a local SQLite file that hamtag looks up callsigns from.
> https://github.com/sysmatt/hamdat

A command-line tool (with optional GUI) that generates name badge labels for thermal printers —
ZPL for Zebra printers, or TSPL for TSC-compatible printers such as the MUNBYN ITPP130B
(see [`--lang tspl` compatibility](#--lang-tspl-compatibility--confirmed-vs-not) for
which models this actually covers).
Looks up HAM callsigns in a [hamdat](https://github.com/sysmatt/hamdat) SQLite database and produces
labels on standard 4"×6" or 4"×2" label stock.

---

## Requirements

- Python 3.9+
- [Pillow](https://pillow.readthedocs.io/) — `pip install Pillow`
- A [hamdat](https://github.com/sysmatt/hamdat) database — used automatically from `~/.hamdat/hamdat.db`
  if it exists, or point at one with `--db PATH` or the `HAMDAT_DB` environment variable  
  *(required for callsign lookup; manual `--name`/`--location` works without it. A `--db`/`HAMDAT_DB`
  path that is missing or can't be opened is a fatal error)*
- A Zebra thermal label printer (ZPL) or a TSC-compatible thermal printer such as the MUNBYN
  ITPP130B (TSPL) — see the TSPL compatibility note below — loaded with
  4"×6" or 4"×2" label stock

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

To send label data directly to a USB printer without `sudo`, add yourself to the `lp` group:

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
hamtag [--call CALLSIGN [CALLSIGN ...]] [--name NAME] [--location TEXT]
       [--banner TEXT] [--note TEXT] [--note-lookup FILE]
       [--label {4x6,4x2}] [--dpi {203,300}]
       [--db PATH] [--font FILE]
       [--output FILE] [--lang {zpl,tspl}] [--printer [DEVICE]]
       [--darkness 1-16] [--speed 1-8] [--media {gap,bline,continuous}]
       [--gap-mm MM] [--gap-offset-mm MM] [--shift-x-mm MM] [--shift-y-mm MM]
       [--copies N] [--blankevery N] [--jokes FILE] [--jokenote TEXT]
       [--calibrate] [--ruler] [--gui] [--attendance FILE]
```

### Options

| Flag | Description |
|---|---|
| `--call CALLSIGN [CALLSIGN ...]` | One or more HAM callsigns to look up in the hamdat database (space- and/or comma-delimited, e.g. `--call K2TTA W1AW` or `--call K2TTA,W1AW`) |
| `--name NAME` | Operator name — overrides the database value |
| `--location TEXT` | Location line, e.g. `Hoboken, NJ` — overrides the database value |
| `--banner TEXT` | Banner text at the top of the badge (e.g. `HAMFEST VOLUNTEER`) |
| `--note TEXT` | Small text pinned to the bottom of the badge — the default when `--note-lookup` has no entry for a callsign |
| `--note-lookup FILE` | CSV roster of `callsign, note` rows (e.g. `ke2r, Club President`); a listed callsign's note replaces `--note` (see [Per-callsign notes](#per-callsign-notes---note-lookup)) |
| `--label {4x6,4x2}` | Label stock — `4x6` landscape badge (default) or `4x2` portrait |
| `--dpi {203,300}` | Printer resolution — `203` (default) or `300` |
| `--db PATH` | hamdat SQLite database path. If omitted: `$HAMDAT_DB` if set, else `~/.hamdat/hamdat.db` if it exists, else lookup is disabled. A given path that is missing or not a valid hamdat DB exits with an error |
| `--font FILE` | TrueType font for all text (auto-detected if omitted) |
| `--output FILE` | Save label data to a file |
| `--lang {zpl,tspl}` | Printer command language — `zpl` (default, Zebra printers) or `tspl` (TSC-compatible printers, e.g. the MUNBYN ITPP130B) |
| `--printer [TARGET]` | Send label data to a USB device (default: `/dev/usb/lp0`) or network printer (`host[:port]`, default port 9100) |
| `--darkness 1-16` | TSPL print darkness, `1` (lightest) to `16` (darkest), default `12` (`--lang tspl` only) |
| `--speed 1-8` | TSPL print speed in inches/sec, `1` to `8`, default `4` (`--lang tspl` only) |
| `--media {gap,bline,continuous}` | TSPL media sensing mode — `gap` (default), `bline` (black mark), or `continuous` stock (`--lang tspl` only) |
| `--gap-mm MM` | TSPL gap/black-line height in mm, default `3.0` (`--lang tspl` only) |
| `--gap-offset-mm MM` | TSPL gap/black-line offset in mm, default `0.0` (`--lang tspl` only) |
| `--shift-x-mm MM` | Move the printed image across the print head — `+` right, `-` left as the `--ruler` label reads — default `0.0`, range ±25 (`--lang tspl` only; see [Aligning TSPL output](#aligning-tspl-output---ruler)) |
| `--shift-y-mm MM` | Move the printed image along the feed — `+` down, `-` up as the `--ruler` label reads — default `0.0`, range ±25 (`--lang tspl` only) |
| `--copies N` | Number of copies to print of each badge, sequentially (default: `1`) |
| `--blankevery N` | Print a blank (unprinted) label after every `N` labels, to mark break points for stapling a long run into a book — counts every printed label, including repeated `--copies` (CLI only) |
| `--jokes FILE` | Single-column jokes CSV (header row, then one joke per row); a random joke label prints before every badge copy. Works in CLI and GUI |
| `--jokenote TEXT` | Small attribution text pinned to the bottom of each joke label (requires `--jokes`) |
| `--calibrate` | Calibrate the printer's label sensor — requires `--printer` (see [Calibration](#calibration)) |
| `--ruler` | Print an alignment test label with mm rulers along every edge, for measuring `--shift-x-mm`/`--shift-y-mm`; honors `--label`, `--dpi`, `--lang` and the output options, can't be combined with `--call`/`--name` |
| `--gui` | Launch interactive GUI — other flags pre-fill the form |
| `--attendance FILE` | GUI only: record the callsign and name of every printed badge in a CSV, one row per person (see [Attendance](#attendance---attendance)) |

`--gui` currently pre-fills from `--lang` and the TSPL tuning flags too, so `hamtag --gui --lang tspl
--printer /dev/usb/lp0` runs the GUI against a TSPL printer. `--jokes`/`--jokenote` apply in the GUI
as well (a random joke label prints before each badge copy); `--blankevery` and `--output` are CLI-only.

At least one of `--call` or `--name` is required in CLI mode (not needed with `--calibrate`, `--ruler` or `--gui`).

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
With `--note-lookup`, **Look Up** fills **Note** from the roster (or the `--note` default), the
status bar shows the roster match, and **Note** resets to the default after each print.
The **Default** button (or **Escape**) restores Banner/Note to the values passed on the command
line and clears the per-badge fields, ready for the next operator.

The **Calibrate** button sends the calibration sequence to the printer (see [Calibration](#calibration)).
Run it whenever you load a new roll of labels.

### Attendance (`--attendance`)

```bash
hamtag --gui --note "Guest" --attendance attendance.csv
```

After every successful print the GUI records the badge's **Callsign** and **Name** in the CSV
(header `callsign,name`), and the status bar shows the running head count.

- One row per person, oldest first.  Printing someone again (e.g. to fix a typo in their name)
  replaces their row and moves it to the end — the most recent entry wins.
- People are matched by callsign (case-insensitive); guests with no callsign are matched by name.
- Extra copies of a badge don't add rows; failed prints aren't recorded.
- The file is created if missing, and read and rewritten at startup (so a bad path fails
  immediately) and after every print, so edits made to it while the GUI is running are kept.
- Saves are crash-safe: the new list is written to `FILE.new` and synced to disk, the current file
  is copied to `FILE.old` (the previous save), then `FILE.new` is atomically renamed over `FILE`.
- If a save fails after a print, a warning dialog appears; the label has already printed.

---

## Per-callsign notes (`--note-lookup`)

`--note` sets the default note; `--note-lookup FILE` supplies callsign-specific notes that replace
it.  Handy for a club roster: members get their role, everyone else gets the default.

```
# SCARC roster
callsign,note
k2tta, Club Member
ke2r, Club President
w1xyz, Treasurer, 2025-2026
```

```bash
hamtag --call K2TTA KE2R N0CALL --note "Guest" --note-lookup roster.csv --printer
# K2TTA → "Club Member", KE2R → "Club President", N0CALL → "Guest"
```

- One `callsign, note` row per line.  Callsigns match case-insensitively; surrounding spaces are ignored.
- Everything after the first comma is the note, so commas inside a note don't need quoting
  (quoted CSV fields work too).
- Blank lines, lines starting with `#`, and a first row of `callsign`/`call` column headers are skipped.
- A row with no note prints a warning to stderr, and that callsign falls back to `--note`.
- A callsign listed more than once prints a warning to stderr; the last row wins.
- A missing or unreadable file, or one with no notes at all, is a fatal error.

Badges without a callsign (`--name` only) always use `--note`.  Works in CLI and GUI, with or
without the hamdat database.

---

## Examples

```bash
# Interactive GUI with event banner and note pre-filled
hamtag --gui --banner "HAMFEST VOLUNTEER" --note "ARRL Field Day 2026"

# Club roster notes: listed members get their role, everyone else "Guest"
hamtag --gui --note "Guest" --note-lookup roster.csv

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

# TSPL printer (e.g. MUNBYN ITPP130B, TSC-compatible) — USB
hamtag --call K2TTA --banner "VOLUNTEER" --lang tspl --printer /dev/usb/lp0

# TSPL on black-mark stock, darker/slower for dense label art
hamtag --call K2TTA --lang tspl --media bline --darkness 15 --speed 2 --printer /dev/usb/lp0

# Network printer (auto-detected by hostname/IP)
hamtag --call K2TTA --banner "VOLUNTEER" --printer 192.168.1.100
hamtag --call K2TTA --banner "VOLUNTEER" --printer printer.local:9100

# 300 DPI printer
hamtag --call K2TTA --dpi 300 --printer

# Calibrate the label sensor before loading a new roll (USB or network)
hamtag --calibrate --printer
hamtag --calibrate --printer 192.168.1.100

# Batch-print a roster and staple it into a book, with a blank label
# every 10 badges marking where to fold/staple
hamtag --call K2TTA W1AW N2XYZ --printer --blankevery 10

# Print 20 copies of one badge, broken into blank-separated stacks of 5
hamtag --call K2TTA --copies 20 --blankevery 5 --printer
```

---

## Label layouts

### 4×6 (default) — landscape badge

The physical label is 4"×6" portrait on the printer roll.  The entire label is rendered as a PIL
bitmap and rotated 90° clockwise, so the badge reads correctly in landscape orientation
(6" wide, 4" tall when worn):

```
┌──────────────────────────────────────────────────────────┐
│                    HAMFEST VOLUNTEER                     │  ← --banner
│  ──────────────────────────────────────────────────────  │
│                          K2TTA                           │  ← callsign (large, auto-sized)
│  ──────────────────────────────────────────────────────  │
│                         Matthew                          │  ← first name (large)
│                        E Hoskins                         │  ← middle/last name (small)
│                      Lafayette, NJ                       │  ← city, state (small)
│                                                          │
│                   ARRL Field Day 2026                    │  ← --note
└──────────────────────────────────────────────────────────┘
```

### 4×2 — portrait label

Rendered at 4"×2" with no rotation — suitable for smaller adhesive labels or table tents:

```
┌──────────────────────────────────────────┐
│            HAMFEST VOLUNTEER             │  ← --banner
│  ──────────────────────────────────────  │
│                  K2TTA                   │  ← callsign (large, auto-sized)
│  ──────────────────────────────────────  │
│                 Matthew                  │  ← first name (large)
│                E Hoskins                 │  ← middle/last name (small)
│              Lafayette, NJ               │  ← city, state (small)
│           ARRL Field Day 2026            │  ← --note
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

Labelary only understands ZPL — there's no equivalent online viewer for TSPL. For `--lang tspl`,
sending straight to the printer (or a real print to a file and inspecting it with a TSPL-aware
tool) is the practical way to check output.

---

## Calibration

Zebra thermal printers use an optical sensor to detect the gaps between labels and align
each print correctly.  If labels print in the wrong position — too high, too low, or spanning
two labels — the sensor needs to be calibrated.

Run calibration whenever you:
- Load a new roll of labels
- Switch between label sizes or stock types
- Find the printer consistently mis-aligning prints

```bash
# USB
hamtag --calibrate --printer

# Network
hamtag --calibrate --printer 192.168.1.100
```

In the GUI, click the **Calibrate** button at any time.

The calibration sequence pushes the following settings to NVRAM before running the sensor cycle,
which prevents the common problem where the printer reverts to continuous-media mode after a
power cycle:

| ZPL command | Effect |
|---|---|
| `^MNN` | Non-continuous media, web (gap) sensing |
| `^LT0` | Reset label-top offset to zero |
| `^TA000` | Reset tear-off position to zero |
| `^JUS` | Save all settings to NVRAM |
| `~JC` | Run optical calibration cycle |

The printer will feed 2–4 labels during the calibration cycle — this is normal.

For `--lang tspl` printers, calibration instead sends a single `AUTODETECT` command, which feeds a
few labels and senses the paper/gap size in one shot — TSPL has no separate NVRAM-save step the
way ZPL's `^JUS` does.

### Aligning TSPL output (`--ruler`)

Some TSPL printers have a print head wider than 4" stock (e.g. 108 mm) and count position from
the head's edge rather than the label's, so the image lands a few mm to one side: one edge of the
badge border is cut off and there's extra white space on the opposite side.  Measure it with the
ruler label, then correct it with `--shift-x-mm` / `--shift-y-mm`:

```bash
# 1. Print the ruler (use the same --label you print badges on)
hamtag --ruler --lang tspl --label 4x2 --printer

# 2. Read the edges: the 0 mm tick of each ruler should sit on the label edge.
#    If the first visible tick on the left is 3 mm, shift right by 3 mm and re-check:
hamtag --ruler --lang tspl --label 4x2 --shift-x-mm 3 --printer

# 3. Use the same shift for real badges (CLI or GUI)
hamtag --gui --lang tspl --label 4x2 --shift-x-mm 3 --printer
```

Directions are as the ruler label reads: `+x` moves the image right, `+y` moves it down.  The ruler
prints its current shift values in the centre, so a photo of the label records the setting.

A positive `--shift-x-mm` also widens the TSPL `SIZE` width by the same amount.  These printers
(confirmed on the MUNBYN ITPP130B) clip at the `SIZE` width counted from their own origin, so
shifting the image right without it just moves the cut-off to the right edge.  `--shift-y-mm` never
changes the `SIZE` height, because that's the label length the printer feeds by; it hasn't been
tested on hardware yet.

---

## Printer notes

- Default DPI is **203**, which is correct for the Zebra LP2844, GX420d, ZD420, and most
  desktop label printers.  Use `--dpi 300` for higher-resolution models (ZD620, ZT410, etc.).
- The entire label is sent as a single bitmap (`^GFA` graphic field), so printer font support
  is irrelevant — any TTF font installed on the host machine can be used.
- To send multiple badges in a single print job, concatenate ZPL outputs — each `^XA...^XZ`
  block is one label.
- Each label job also sends a short config preamble (`^MNN ^LT0 ^JUS`) to ensure non-continuous
  gap sensing is active and saved, even if the printer was previously in continuous mode.
- For `--lang tspl`, the entire label is sent as a single `BITMAP` command (mode 0, OVERWRITE)
  with the packed 1bpp image data embedded as raw binary — unlike ZPL's `^GFA`, TSPL does not
  hex-encode the graphic, so `--output` for a TSPL job writes a binary file, not text.
- Every TSPL job resends `SIZE`/`GAP`/`DENSITY`/`SPEED`/`DIRECTION` from scratch rather than
  relying on prior NVRAM state, so each print is self-contained regardless of what a previous
  job (or a previous user) left configured.

### `--lang tspl` compatibility — confirmed vs. not

`--lang tspl` is confirmed working over raw USB on the **MUNBYN ITPP130B**
(tested end-to-end: 4×6 and 4×2, both print correctly).

**The MUNBYN RealWriter 403B does NOT work with `--lang tspl` — do not spend more time on it.**
It looked like a good candidate (USB ID `0d28:ccdd`, identifies as a standard USB Printer-class
device claimed by the kernel's `usblp` driver at `/dev/usb/lpN`, and a community CUPS filter,
[surma-lodur/Munbyn-CUPS](https://github.com/surma-lodur/Munbyn-CUPS), claims the protocol is
TSPL), but real-hardware testing disproved it:

- Raw TSPL and raw ESC/POS commands sent directly to `/dev/usb/lpN` produce zero reaction (no
  feed, no print, nothing) — same result over a paired Bluetooth RFCOMM (`/dev/rfcomm0`) connection.
- The standard USB Printer-class `GET_PORT_STATUS` control request (`usblp`'s `LPGETSTATUS`
  ioctl) returns `EIO` — the device doesn't answer basic class status queries either.
- A Bluetooth HCI snoop capture (`adb`, Developer options → Bluetooth HCI snoop log → **Full**
  mode — the default **Filtered** mode redacts payload content and is useless for this) of the
  official MUNBYN Android app doing a real successful print revealed the actual protocol: a
  **proprietary Protobuf-encoded message stream over Bluetooth SPP**, not TSPL or ESC/POS text at
  all (confirmed via textbook protobuf wire-format tag/varint bytes in the capture, e.g.
  `18 a0 8a 05 20 01 28 01 30 66 ...` decoding as sequential field tags 3–12). The 403B's USB
  Printer-class descriptor appears to be present for OS/driver-detection purposes only — the real
  print engine is likely wired to Bluetooth exclusively.
- Reverse-engineering that protobuf schema (plus its image encoding, which isn't simple 1bpp
  packed rows) would be a real undertaking — decompiling the MUNBYN app APK for the vendor SDK's
  unobfuscated class/field names is probably the fastest path in, if this is ever revisited.

If you pick up a *newer* MUNBYN model and hit the same "writes succeed, printer does nothing"
symptom, suspect the same thing before assuming a bug in this code.

### `/dev/usb/lp0` (or `lp3`, etc.) disappears shortly after plugging in

On Ubuntu/Debian systems with `system-config-printer-udev` installed, plugging in *any* USB
printer-class device — Zebra or MUNBYN alike — triggers a udev rule
(`/lib/udev/rules.d/70-printers.rules`) that runs `configure-printer@usb-<bus>-<dev>.service` →
`udev-configure-printer`. That helper probes the USB device to auto-create/refresh a CUPS queue
(often picking a nonsense driver — e.g. an HP DesignJet PostScript PPD for a MUNBYN label printer
that speaks neither HP PCL nor PostScript), and the probe transiently claims the USB interface —
which evicts the kernel's `usblp` driver out from under `/dev/usb/lpN`. `dmesg` will show
`usblpN: removed` a second or two after the device is detected, sometimes followed by repeated
remove/re-add cycles (and `apparmor="DENIED" ... capname="net_admin"` from `cupsd`'s USB backend
during the same probe — a side effect, not the cause).

Fix: stop udev from invoking the CUPS auto-configure helper on USB printer hotplug —

```bash
sudo systemctl mask configure-printer@.service
```

This is reversible (`sudo systemctl unmask configure-printer@.service`) and doesn't touch any
CUPS queues you already have — it just stops CUPS from grabbing the device every time it's
plugged in, leaving `/dev/usb/lpN` free for hamtag's raw writes. Unplug/replug the printer after
masking to confirm the device path stays put.

### Network printing

Network printers are auto-detected when `--printer` is given a hostname or IP address (anything
that doesn't start with `/`).  The default port is **9100**, which is the standard ZPL raw port
on all Zebra models.

```bash
hamtag --call K2TTA --printer 192.168.1.100        # default port 9100
hamtag --call K2TTA --printer printer.local:9100   # explicit port
```

The network socket uses a **30-second timeout** and `TCP_NODELAY` to minimise latency.  If you
see timeout errors, check that port 9100 is not blocked by a firewall and that the printer is
not paused or in an error state.
