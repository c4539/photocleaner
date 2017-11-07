# photocleaner

## Supported timestrings
- `^(\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*`
- `^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\.]*`
- `^(Photo|Video)[\s-_\.](\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*`
- `^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\.]*`

## Usage
-Source

-Destination

-TimeFormat="yyyy-MM-dd HH-mm-ss"

-Separator = " "

-UseSubfolders=$false

-SubfolderFormat = "yyyy\\MM"

-Recurse=$false

-ExtensionCase = "Keep" ("UpperCase","LowerCase","Keep")