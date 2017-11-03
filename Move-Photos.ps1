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
	$TimeFormat="yyyy-MM-dd_HH-mm-ss"
,
	[Switch]
	$UseSubfolders=$true
	# [string]
	# [ValidateSet("Restart","LogOff","Shutdown","PowerOff")]
)



Get-ChildItem -Path $Source -File | ForEach-Object {
	$File = $_
	$Filename = $_.Name

	# Parse Filename
	switch -regex ($Filename) {
		# Android syntax
		#IMG_20150504_080042
		#IMG_yyyyMMdd_HHmmss
		"^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_]*" {
			$RegexMatches = [regex]::Match($Filename,"^(IMG|VID)_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})[\s-_]*")
			
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
			$RegexMatches = [regex]::Match($Filename,"^(Photo|Video)-(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})[\s-_]*")
			
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
			$RegexMatches = [regex]::Match($Filename,"^WP_(\d{4})(\d{2})(\d{2})_(\d{2})_(\d{2})_(\d{2})[\s-_]*")
			
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
			Write-Debug "Could not parse `"$Filename`"."
			return
		}
	}

	# Get suffix
	$Suffix = $Filename.Substring($DTPrefix.Length);
	if (-not $Suffix.StartsWith(".")) {
		$Suffix = "_" + $Suffix
	}

	# Build new filename
	$NewFilename = $FileTime.ToString($TimeFormat) + $Suffix

	# Create subfolders if needed
	if ($UseSubfolders) {
		$DestinationFolder = [System.IO.Path]::Combine($Destination,$FileTime.ToString("yyyy\\MM")).ToString()
		
		if (-not (Test-Path -PathType Container -Path $DestinationFolder)) {
			New-Item -Path $DestinationFolder -ItemType Directory -WhatIf:$WhatIfPreference | Out-Null
		}
	} else {
		$DestinationFolder = $Destination
	}

	# Prepare pathes
	$SourceFilename = $File.FullName.Replace('[','``[').Replace(']','``]')
	$DestinationFilename = [System.IO.Path]::Combine($DestinationFolder,$NewFilename).ToString().Replace('[','``[').Replace(']','``]')

	# Move File
	#if ($pscmdlet.ShouldProcess("$File", "Move-File")){
	#    
	#}

	# Check whether old and new filename are equal
	if ($Filename -eq $NewFilename) {
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