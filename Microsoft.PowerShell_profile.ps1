$ErrorActionPreference = "stop"
$PSNativeCommandUseErrorActionPreference = $true

function IsInteractive {
    # not including `-NonInteractive` since it apparently does nothing
    # "Does not present an interactive prompt to the user" - no, it does present!
    $non_interactive = '-command', '-c', '-encodedcommand', '-e', '-ec', '-file', '-f'

    $args = [Environment]::GetCommandLineArgs()
    if(($args | Where-Object -FilterScript { $PSItem -in $non_interactive }) -or ($args.Length -eq 2 -and (Test-Path $args[1] -PathType Leaf))) {
	$lastArg = $args[$args.length - 1]
        return $lastArg.Contains('Microsoft VS Code') -or $lastArg.Contains('ms-vscode.powershell')
	#return $false
    }
    return $true
}

#"Console isInteractive: $(IsInteractive)"

if (IsInteractive) {
	oh-my-posh init pwsh --config "https://raw.githubusercontent.com/remyblok/posh-config/main/rjb.omp.json" | Invoke-Expression
	if ($isWindows) {
		Import-Module -Name Microsoft.WinGet.CommandNotFound
	}

	function Update-AzModule {
		[CmdletBinding()]
		param()

		Get-InstalledModule -Name Az -AllVersions -OutVariable AzVersions

		($AzVersions | ForEach-Object {
			Import-Clixml -Path (Join-Path -Path $_.InstalledLocation -ChildPath PSGetModuleInfo.xml)
		}).Dependencies.Name | Sort-Object -Descending -Unique -OutVariable AzModules

		$AzModules | ForEach-Object {
			Remove-Module -Name $_ -ErrorAction SilentlyContinue
			Write-Output "Attempting to uninstall module: $_"
			Uninstall-Module -Name $_ -AllVersions
		}


		Remove-Module -Name Az -ErrorAction SilentlyContinue
		Write-Output "Attempting to uninstall module: Az"
		Uninstall-Module -Name Az -AllVersions

		Write-Output "Installing module Az and dependencies"
		Install-Module -Name Az -Repository PSGallery -Force
	}

	Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)
		$completion_file = New-TemporaryFile
		$env:ARGCOMPLETE_USE_TEMPFILES = 1
		$env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
		$env:COMP_LINE = $commandAst
		$env:COMP_POINT = $cursorPosition
		$env:_ARGCOMPLETE = 1
		$env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
		$env:_ARGCOMPLETE_IFS = "`n"
		$env:_ARGCOMPLETE_SHELL = 'powershell'
		az 2>&1 | Out-Null
		Get-Content $completion_file | Sort-Object | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
		}
		Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
	}

	Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)

		dotnet complete --position $cursorPosition $commandAst.ToString() | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new(
				$_,               # completionText
				$_,               # listItemText
				'ParameterValue', # resultType
				$_                # toolTip
			)
		}
	}


	Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
	Set-Alias az azps
}

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

#Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58


