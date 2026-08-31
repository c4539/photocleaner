# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

PowerShell Photo Cleaner is a single-script utility (`Move-Photos.ps1`) that renames and moves photo/video files based on a timestamp embedded in their original filename (e.g. `IMG_20220101_120000.jpg` → `2022-01-01 12-00-00.jpg`). Requires PowerShell v4+.

## Running the script

There is no build step, package manager, or test suite — this is a standalone `.ps1` file.

Run it directly, e.g.:

```powershell
.\Move-Photos.ps1 -Source D:\in -Destination D:\out
```

Use `-WhatIf` to preview changes without moving/deleting any files, and `-Verbose`/`-Debug` to see per-file parsing decisions (including files that fail to match any pattern).

Key parameters (see the comment-based help at the top of `Move-Photos.ps1` or `README.md` for full details): `-Source`, `-Destination`, `-TimeFormat`, `-Separator`, `-UseSubfolders`, `-SubfolderFormat`, `-Recurse`, `-ExtensionCase`.

## Architecture

The entire logic lives in `Move-Photos.ps1` as a single sequential pipeline:

1. **`$TimeRegex` table** (top of the script): an array of hashtables, each pairing a regex against known filename formats (stock Android/iOS camera names, `IMG_`/`VID_` prefixes, Windows Phone `WP_` names, `FullSizeRender-...`, etc.) with the capture-group indices for Year/Month/Day/Hour/Minute/Second (and optionally `Suffix`, when the remaining filename text isn't simply "everything after the matched prefix"). **This table is the source of truth for supported formats — `README.md`'s "Supported timestrings" list is a manually maintained copy and must be kept in sync whenever a regex is added, removed, or changed.**
2. **Main loop** (`$Files | ForEach-Object`): for each file, tries every `$TimeRegex` entry in order until one matches, builds a `System.DateTime` from the captured groups (2-digit years are assumed to be 2000+), formats the new filename via `-TimeFormat`, and computes the destination path (optionally nested into `-SubfolderFormat` subfolders).
3. **Collision handling**: if the destination file already exists, it compares SHA512 hashes — identical files cause the source to be deleted (dedup), differing files are left alone with a warning.
4. **Move**: otherwise the file is moved via `Move-Item`, respecting `-WhatIf`.

When adding support for a new filename format, add an entry to `$TimeRegex` with the correct group-index mapping, and mirror the exact regex string into the "Supported timestrings" section of `README.md`.
