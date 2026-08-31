<#
.SYNOPSIS
Moves and renames photos and videos.

.DESCRIPTION
The Move-Photos script moves and renames photo and video files based on the timestamp within their filenames.

If a file with the same new name already exists at the destination and its content is byte-for-byte
identical to the source file (compared via SHA512 hash), the source file is deleted instead of moved,
since it is considered a duplicate. If the content differs, the source file is left untouched and a
warning is written.

.PARAMETER Source
Source directory to read the files from.

.PARAMETER Destination
Destination directory to move the files to.

.PARAMETER TimeFormat
The format of the new timestring.
Default is "yyyy-MM-dd HH-mm-ss".

.PARAMETER Separator
The separator between the timestring and the old filename suffix.
Default is " ".

.PARAMETER UseSubfolders
Switch whether to use subfolders in the destination or not.
Default is "$false"

.PARAMETER SubfolderFormat
The format to create subfolders in the destination.
Possible values are "yyyy\\MM", "yyyy-MM", or "yyyy".
Default is "yyyy\\MM".

.PARAMETER Recurse
Switch whether to scan the source recursive.
Default is "$false".

.PARAMETER ExtensionCase
Switch how to treat the file extension.
Possible values are "UpperCase", "LowerCase", and "Keep".
Default is "Keep".

.PARAMETER UseFileAttributeFallback
Switch whether to fall back to the file's CreationTime/LastWriteTime attributes (whichever is
earlier) when no timestring can be extracted from the filename, instead of skipping the file.
Default is "$false".

.EXAMPLE
Move photos from D:\in to D:\out
.\Move-Photos.ps1 -Source D:\in -Destination D:\out

.NOTES
	File Name  : Move-Photos.ps1
	Author     : c4539  
	Requires   : PowerShell V4

.LINK
https://github.com/c4539/photocleaner

#>

#Requires -Version 4

[CmdletBinding(SupportsShouldProcess=$true,PositionalBinding=$false)]

param(
	[ValidateScript({Test-Path -PathType Container -Path $_ })]
	[Parameter(Mandatory=$true,Position=1)]
	[String]
	$Source
,
	[ValidateScript({Test-Path -PathType Container -Path $_ })]
	[Parameter(Mandatory=$true,Position=2)]
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
	[String]
	[ValidateSet("yyyy\\MM","yyyy-MM","yyyy")]
	$SubfolderFormat = "yyyy\\MM"
,
	[Switch]
	$Recurse=$false
,
	[String]
	[ValidateSet("UpperCase","LowerCase","Keep")]
	$ExtensionCase = "Keep"
,
	[Switch]
	$UseFileAttributeFallback=$false
)

# BEGIN Define regular expressions
# NOTE: Order matters. Patterns are tried top to bottom and the first match wins, so more
# specific patterns (e.g. the iOS format) must come before more general ones that would
# otherwise match a prefix of the same filename first (e.g. the generic numeric pattern).
$TimeRegex = @()
$TimeRegex += @{"Regex" = "^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\d{3}_iOS";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
$TimeRegex += @{"Regex" = "^(\d{4})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]?(\d{2})[\s-_\.]*";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
$TimeRegex += @{"Regex" = "^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\.]*";
				"Year" = 2; "Month" = 3; "Day" = 4; "Hour" = 5; "Minute" = 6; "Second" = 7; }
$TimeRegex += @{"Regex" = "^(Photo|Video)[\s-_\.](\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*";
				"Year" = 2; "Month" = 3; "Day" = 4; "Hour" = 5; "Minute" = 6; "Second" = 7; }
$TimeRegex += @{"Regex" = "^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\.]*";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
$TimeRegex += @{"Regex" = "^FullSizeRender-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})[-]?";
				"Year" = 3; "Month" = 2; "Day" = 1; "Hour" = 4; "Minute" = 5; "Second" = $null; }
$TimeRegex += @{"Regex" = "^IMG_(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})";
				"Year" = 4; "Month" = 3; "Day" = 2; "Hour" = 5; "Minute" = 6; "Second" = $null; "Suffix" = 1; }
$TimeRegex += @{"Regex" = "^(\d{2})-(\d{2})-(\d{2})[\s-_](\d{2})-(\d{2})-(\d{2})[\s-_\.]*";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
# END Define regular expressions

# Get files
# Force an array even when there is exactly one (or zero) matching files, since PowerShell
# unwraps a single-item result to a plain FileInfo object, whose .Length is its byte size
# rather than a count of 1 - that broke the progress bar percentage below.
$Files = @(Get-ChildItem -Path $Source -File -Recurse:$Recurse)

# Init progress bar
$ProgressBarCount = 0;
$ProgressBarTotal = $Files.Length

# Go through all files
$Files | ForEach-Object {
	$File = $_
	$Filename = $File.Name
	$FileBaseName = $File.BaseName
	
	# Write progress
	Write-Progress -Activity "Moving Photos" -Status "Processing $Filename" -PercentComplete ([int] (($ProgressBarCount++/$ProgressBarTotal)*100))
	
	# Set file name extension
	switch ($ExtensionCase) {
		"UpperCase" {
			$FileExtension = $File.Extension.ToUpper()
		}

		"LowerCase" {
			$FileExtension = $File.Extension.ToLower()
		}

		default {
			$FileExtension = $File.Extension
		}
	}

	try {
		# Parse existing filename
		$Parsed = $false
		foreach ($TR in $TimeRegex){
			if (-not $Parsed -and $FileBaseName -match $TR.Regex) {
				$RegexMatches = [regex]::Match($FileBaseName,$TR.Regex)

				$DTPrefix = $RegexMatches.Groups[0].Value
				$FileTime = New-Object System.DateTime `
										$(if ($RegexMatches.Groups[$TR.Year].Value.Length -eq 2) { 2000 + $RegexMatches.Groups[$TR.Year].Value } else { $RegexMatches.Groups[$TR.Year].Value }),`
										$RegexMatches.Groups[$TR.Month].Value,`
										$RegexMatches.Groups[$TR.Day].Value,`
										$RegexMatches.Groups[$TR.Hour].Value,`
										$RegexMatches.Groups[$TR.Minute].Value,`
										$(if ($TR.Second -eq $null) { "00" } else { $RegexMatches.Groups[$TR.Second].Value })

				$Parsed = $true

				# Store SuffixID for later use
				$SuffixID = $TR.Suffix;
			}
		}
		if (-not $Parsed) {
			if ($UseFileAttributeFallback) {
				# No timestring in the filename - fall back to the file's own timestamps.
				# The earlier of CreationTime/LastWriteTime is used, since CreationTime alone
				# can be reset to "when this file was copied here" on some platforms/filesystems,
				# which would be later than when the photo was actually taken.
				$FileTime = if ($File.CreationTime -lt $File.LastWriteTime) { $File.CreationTime } else { $File.LastWriteTime }
				$DTPrefix = ""
				$SuffixID = $null
			} else {
				Write-Verbose "Could not parse `"$Filename`"."
				Write-Debug "Could not parse `"$Filename`"."
				return
			}
		}

		# Get suffix
		if ($SuffixID -eq $null) {
			# Get suffix from the end of the filename
			$Suffix = $FileBaseName.Substring($DTPrefix.Length);

			# Separate suffix if exists
			if ($Suffix.Length -gt 0) {
				$Suffix = $Separator + $Suffix
			}
		} else {
			# Get suffix from the RegEx
			if ($RegexMatches.Groups[$SuffixID].Value.Length -gt 0) {
				$Suffix = $Separator + $RegexMatches.Groups[$SuffixID].Value
			} else {
				$Suffix = ""
			}
		}

		# Build new filename
		$NewFilename = $FileTime.ToString($TimeFormat) + $Suffix + $FileExtension

		# Create subfolders if needed
		if ($UseSubfolders) {
			$DestinationFolder = [System.IO.Path]::Combine((Get-Item -LiteralPath $Destination).FullName.ToString(),$FileTime.ToString($SubfolderFormat)).ToString()

			if (-not (Test-Path -PathType Container -LiteralPath $DestinationFolder)) {
				New-Item -LiteralPath $DestinationFolder -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
			}
		} else {
			$DestinationFolder = (Get-Item -LiteralPath $Destination).FullName.ToString()
		}

		# Prepare pathes
		# Using -LiteralPath everywhere below avoids these being interpreted as wildcard
		# expressions, so filenames containing characters like [ or ] are handled correctly
		# without needing to be manually escaped.
		$SourceFilename = $File.FullName
		$DestinationFilename = [System.IO.Path]::Combine($DestinationFolder,$NewFilename).ToString()

		# Check whether old and new filename are equal
		if ($SourceFilename -eq $DestinationFilename) {
			Write-Verbose "Filename of `"$Filename`" would not be changed. File will be ignored."
			return
		}

		# Check whether files already exists
		if (Test-Path -PathType Leaf -LiteralPath $DestinationFilename) {
			# Get file hashes
			$DestinationFilehashSHA512 = (Get-FileHash -LiteralPath $DestinationFilename -Algorithm SHA512).Hash
			$SourceFilehashSHA512 = (Get-FileHash -LiteralPath $SourceFilename -Algorithm SHA512).Hash

			# Compare file hashes
			if ($DestinationFilehashSHA512 -eq $SourceFilehashSHA512) {
				# Files are identical according to their hashes. Source can be removed.
				Write-Verbose "File `"$DestinationFilename`" already exists with same file hash. `"$SourceFilename`" will be removed."
				Remove-Item -LiteralPath $SourceFilename -Confirm:$false -WhatIf:$WhatIfPreference
			} else {
				Write-Verbose "File `"$DestinationFilename`" already exists with different file hash!"
				Write-Warning "File `"$DestinationFilename`" already exists with different file hash!"
			}
			return
		}

		# Move file
		Write-Verbose "Moving `"$SourceFilename`" to `"$DestinationFilename`"."
		Move-Item -LiteralPath $SourceFilename -Destination $DestinationFilename -WhatIf:$WhatIfPreference
	} catch {
		Write-Warning "Failed to process `"$Filename`": $($_.Exception.Message)"
		return
	}
}