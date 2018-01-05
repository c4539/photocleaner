<#
.SYNOPSIS
Moves and renames photos and videos.

.DESCRIPTION
The Move-Photos script moves and renames photo and video files based on the timestamp within their filenames. 

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
)

# BEGIN Define regular expressions
$TimeRegex = @()
$TimeRegex += @{"Regex" = "^(\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
$TimeRegex += @{"Regex" = "^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_\.]*";
				"Year" = 2; "Month" = 3; "Day" = 4; "Hour" = 5; "Minute" = 6; "Second" = 7; }
$TimeRegex += @{"Regex" = "^(Photo|Video)[\s-_\.](\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*";
				"Year" = 2; "Month" = 3; "Day" = 4; "Hour" = 5; "Minute" = 6; "Second" = 7; }
$TimeRegex += @{"Regex" = "^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_\.]*";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
$TimeRegex += @{"Regex" = "^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\d{3}_iOS";
				"Year" = 1; "Month" = 2; "Day" = 3; "Hour" = 4; "Minute" = 5; "Second" = 6; }
# END Define regular expressions

# Get files
$Files = Get-ChildItem -Path $Source -File -Recurse:$Recurse

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

	# Parse existing filename
	$Parsed = $false
	foreach ($TR in $TimeRegex){
		if (-not $Parsed -and $FileBaseName -match $TR.Regex) {
			$RegexMatches = [regex]::Match($FileBaseName,$TR.Regex)
			
			$DTPrefix = $RegexMatches.Groups[0].Value
			$FileTime = New-Object System.DateTime `
									$RegexMatches.Groups[$TR.Year].Value,`
									$RegexMatches.Groups[$TR.Month].Value,`
									$RegexMatches.Groups[$TR.Day].Value,`
									$RegexMatches.Groups[$TR.Hour].Value,`
									$RegexMatches.Groups[$TR.Minute].Value,`
									$RegexMatches.Groups[$TR.Second].Value
			
			$Parsed = $true
		}
	}
	if (-not $Parsed) {
		Write-Verbose "Could not parse `"$Filename`"."
		Write-Debug "Could not parse `"$Filename`"."
		return
	}

	# Get suffix
	$Suffix = $FileBaseName.Substring($DTPrefix.Length);

	# Separate suffix if exists
	if ($Suffix.Length -gt 0) {
		$Suffix = $Separator + $Suffix
	}

	# Build new filename
	$NewFilename = $FileTime.ToString($TimeFormat) + $Suffix + $FileExtension

	# Create subfolders if needed
	if ($UseSubfolders) {
		$DestinationFolder = [System.IO.Path]::Combine((Get-Item $Destination).FullName.ToString(),$FileTime.ToString($SubfolderFormat)).ToString()
		
		if (-not (Test-Path -PathType Container -Path $DestinationFolder)) {
			New-Item -Path $DestinationFolder -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
		}
	} else {
		$DestinationFolder = (Get-Item $Destination).FullName.ToString()
	}

	# Prepare pathes
	$SourceFilename = $File.FullName.Replace('[','`[').Replace(']','`]')
	$DestinationFilename = [System.IO.Path]::Combine($DestinationFolder,$NewFilename).ToString().Replace('[','`[').Replace(']','`]')

	# Check whether old and new filename are equal
	if ($SourceFilename -eq $DestinationFilename) {
		Write-Verbose "Filename of `"$Filename`" would not be changed. File will be ignored."
		return
	}

	# Check whether files already exists
	if (Test-Path -PathType Leaf -Path $DestinationFilename) {
		# Get file hashes
		$DestinationFilehashSHA512 = (Get-FileHash -Path $DestinationFilename -Algorithm SHA512).Hash
		$SourceFilehashSHA512 = (Get-FileHash -Path $SourceFilename -Algorithm SHA512).Hash
		
		# Compare file hashes
		if ($DestinationFilehashSHA512 -eq $SourceFilehashSHA512) {
			# Files are identical according to their hashes. Source can be removed.
			Write-Verbose "File `"$DestinationFilename`" already exists with same file hash. `"$SourceFilename`" will be removed."
			Remove-Item -Path $SourceFilename -Confirm:$false -WhatIf:$WhatIfPreference
		} else {
			Write-Verbose "File `"$DestinationFilename`" already exists with different file hash!"
			Write-Warning "File `"$DestinationFilename`" already exists with different file hash!"
		}
		return
	}
	
	# Move file
	Write-Verbose "Moving `"$SourceFilename`" to `"$DestinationFilename`"."
	Move-Item -Path $SourceFilename -Destination $DestinationFilename -WhatIf:$WhatIfPreference
}