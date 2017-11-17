# Powershell Photo Cleaner

## Supported timestrings
- `^(\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*`
- `^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\.]*`
- `^(Photo|Video)[\s-_\.](\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*`
- `^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\.]*`

## Parameters
### Source 
Source directory to read the files from.

### Destination
Destination directory to move the files to.

### TimeFormat
The format of the new timestring.

Default is "yyyy-MM-dd HH-mm-ss".

### Separator
The separator between the timestring and the old filename suffix.

Default is " ".

### UseSubfolders
Switch whether to use subfolders in the destination or not.

Default is "$false"

### SubfolderFormat
The format to create subfolders in the destination.

Possible values are "yyyy\\MM", "yyyy-MM", or "yyyy".

Default is "yyyy\\MM".

### Recurse
Switch whether to scan the source recursive.

Default is "$false".

### ExtensionCase
Switch how to treat the file extension.

Possible values are "UpperCase", "LowerCase", and "Keep".

Default is "Keep".