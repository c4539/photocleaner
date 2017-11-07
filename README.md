# photocleaner

## Supported timestrings
- ^(\d{4})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\s-_\\.]*
- ^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\\.]*
- ^(Photo|Video)[\\s-_\\.](\d{4})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\\s-_\\.](\d{2})[\s-_\\.]*
- ^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\\.]*

## Usage
[ValidateScript({Test-Path -PathType Container -Path $_ })]
	[Parameter(Mandatory=$true)]
	[String]
	$Source
,
	[ValidateScript({Test-Path -PathType Container -Path $_ })]
	[Parameter(Mandatory=$true)]
	[String]
	$Destination
,
	[String]
	$TimeFormat="yyyy-MM-dd HH-mm-ss"
,
	[String]
	$Separator = " "
,
	[Switch]
	$UseSubfolders=$false
,
	[string]
	[ValidateSet("yyyy\\MM","yyyy-MM","yyyy")]
	$SubfolderFormat = "yyyy\\MM"
,
	[Switch]
	$Recurse=$false
,
	[String]
	[ValidateSet("UpperCase","LowerCase","Keep")]
	$ExtensionCase = "Keep"