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
