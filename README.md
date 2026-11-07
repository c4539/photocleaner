# Powershell Photo Cleaner

A simple PowerShell script to rename photos by changing the format of the timestring in its filename.

## Supported timestrings

Patterns are tried in the order listed below and the first match wins, so more specific patterns
are listed before more general ones they could otherwise be mistaken for.

- `^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\d{3}_iOS`
- `^(\d{4})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]*`
- `^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\.]*`
- `^(Photo|Video)[\s-_\.](\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*`
- `^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\.]*`
- `^FullSizeRender-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})[-]?`
- `^IMG_(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})`
- `^(\d{2})-(\d{2})-(\d{2})[\s-_](\d{2})-(\d{2})-(\d{2})[\s-_\.]*`

## Duplicate handling

If a file with the same new name already exists at the destination and its content is byte-for-byte
identical to the source file (compared via SHA512 hash), the source file is **deleted** instead of
moved, since it is considered a duplicate. If the content differs, the source file is left untouched
and a warning is shown.

## Parameters

### Source

Source directory to read the files from.

### Destination

Destination directory to move the files to.

### TimeFormat

The format of the new timestring.  
Default is "`yyyy-MM-dd HH-mm-ss`".

### Separator

The separator between the timestring and the old filename suffix.  
Default is "` `".

### UseSubfolders

Switch whether to use subfolders in the destination or not.  
Default is "`$false`"

### SubfolderFormat

The format to create subfolders in the destination.  
Possible values are "`yyyy\\MM`", "`yyyy-MM`", or "`yyyy`".  
Default is "`yyyy\\MM`".

### Recurse

Switch whether to scan the source recursively.  
Default is "`$false`".

### ExtensionCase

Switch how to treat the file extension.  
Possible values are "`UpperCase`", "`LowerCase`", and "`Keep`".  
Default is "`Keep`".

### UseFileAttributeFallback

Switch whether to fall back to file metadata when no timestring can be extracted from the filename,
instead of skipping the file. The capture date stored in the file (EXIF `DateTimeOriginal`, or the video
creation date; needs [exiftool](https://exiftool.org) for videos, or Windows PowerShell for images; see [ExifTool](#exiftool-optional))
is preferred, then the earlier of `CreationTime`/`LastWriteTime`.  
Default is "`$false`".

### ExifToolPath

Path to the `exiftool` executable, e.g. a portable copy that isn't on `PATH`. If omitted, `exiftool`
is looked up on `PATH`. Only used together with `-UseFileAttributeFallback`.

## ExifTool (optional)

With `-UseFileAttributeFallback`, the script reads the real capture date from the file's metadata.
[ExifTool](https://exiftool.org) is optional but recommended: it adds support for videos (MP4/MOV),
HEIC and RAW files, and works with PowerShell 7. Without it, only images are checked, via
System.Drawing on Windows PowerShell; everything else falls back to the file's `CreationTime`/`LastWriteTime`.
Video creation dates, which QuickTime/MP4 store in UTC, are converted to local time.
Implausible dates (year 1904 or earlier) are ignored.

- **Windows:** `winget install OliverBetz.ExifTool`, `choco install exiftool`, `scoop install exiftool`, or
  download `exiftool.exe` from exiftool.org and either put it on `PATH` or pass `-ExifToolPath`.
- **macOS:** `brew install exiftool`
- **Linux:** `apt install libimage-exiftool-perl` or `dnf install perl-Image-ExifTool`
