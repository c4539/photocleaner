[CmdletBinding(SupportsShouldProcess=$true)]

param(
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
)

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
	Write-Progress -Activity "Moving Photos" -Status "Moving $Filename" -PercentComplete ([int] (($ProgressBarCount++/$ProgressBarTotal)*100))
	
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

	# Parse existing gilename
	switch -regex ($FileBaseName) {
		# Generic syntax
		#2015-05-04_08-00-42
		#yyyy-MM-dd_HH-mm-ss
		"^(\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*" {
			$RegexMatches = [regex]::Match($FileBaseName,"^(\d{4})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.](\d{2})[\s-_\.]*")
			
			$DTPrefix = $RegexMatches.Groups[0].Value
			$FileTime = New-Object System.DateTime `
									$RegexMatches.Groups[1].Value,`
									$RegexMatches.Groups[2].Value,`
									$RegexMatches.Groups[3].Value,`
									$RegexMatches.Groups[4].Value,`
									$RegexMatches.Groups[5].Value,`
									$RegexMatches.Groups[6].Value
		}

		# Android syntax
		#IMG_20150504_080042
		#IMG_yyyyMMdd_HHmmss
		"^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_]*" {
			$RegexMatches = [regex]::Match($FileBaseName,"^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_]*")
			
			$DTPrefix = $RegexMatches.Groups[0].Value
			$FileTime = New-Object System.DateTime `
									$RegexMatches.Groups[2].Value,`
									$RegexMatches.Groups[3].Value,`
									$RegexMatches.Groups[4].Value,`
									$RegexMatches.Groups[5].Value,`
									$RegexMatches.Groups[6].Value,`
									$RegexMatches.Groups[7].Value
		}

		#Photo-2016-09-03-16-17-07_0033
		#Photo-yyyy-MM-dd-HH-mm-ss_####
		"^(Photo|Video)-(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})[\s-_]*" {
			$RegexMatches = [regex]::Match($FileBaseName,"^(Photo|Video)-(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})[\s-_]*")
			
			$DTPrefix = $RegexMatches.Groups[0].Value
			$FileTime = New-Object System.DateTime `
									$RegexMatches.Groups[2].Value,`
									$RegexMatches.Groups[3].Value,`
									$RegexMatches.Groups[4].Value,`
									$RegexMatches.Groups[5].Value,`
									$RegexMatches.Groups[6].Value,`
									$RegexMatches.Groups[7].Value
		}

		# Windows Phone / Mobile syntax
		#WP_20161231_12_27_56
		#WP_yyyyMMdd_HH_mm_ss
		"^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_]*" {
			$RegexMatches = [regex]::Match($FileBaseName,"^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_]*")
			
			$DTPrefix = $RegexMatches.Groups[0].Value
			$FileTime = New-Object System.DateTime `
									$RegexMatches.Groups[1].Value,`
									$RegexMatches.Groups[2].Value,`
									$RegexMatches.Groups[3].Value,`
									$RegexMatches.Groups[4].Value,`
									$RegexMatches.Groups[5].Value,`
									$RegexMatches.Groups[6].Value
		}
		default {
			Write-Verbose "Could not parse `"$Filename`"."
			Write-Debug "Could not parse `"$Filename`"."
			return
		}
	}

	# Get suffix
	$Suffix = $FileBaseName.Substring($DTPrefix.Length);
	if ($Suffix.Length -gt 0) {
		$Suffix = $Separator + $Suffix
	}

	# Build new filename
	$NewFilename = $FileTime.ToString($TimeFormat) + $Suffix + $FileExtension

	# Create subfolders if needed
	if ($UseSubfolders) {
		$DestinationFolder = [System.IO.Path]::Combine($Destination,$FileTime.ToString($SubfolderFormat)).ToString()
		
		if (-not (Test-Path -PathType Container -Path $DestinationFolder)) {
			New-Item -Path $DestinationFolder -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
		}
	} else {
		$DestinationFolder = $Destination
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
		Write-Warning "File `"$DestinationFilename`" already exists!"
		return
	}
	
	# Move file
	Write-Verbose "Moving `"$SourceFilename`" to `"$DestinationFilename`"."
	Move-Item -Path $SourceFilename -Destination $DestinationFilename -WhatIf:$WhatIfPreference
}