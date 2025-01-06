$PowerShellProfileUrl = 'https://raw.githubusercontent.com/andreizhvaleuski/dotfiles/refs/heads/main/terminal/pwsh_profile.ps1'
$OhMyPoshConfigUrl = 'https://raw.githubusercontent.com/andreizhvaleuski/dotfiles/refs/heads/main/terminal/themes/main.omp.json'
$OhMyPoshConfigFile = "$ENV:USERPROFILE/.config/oh-my-posh/main.omp.json"

# Opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Import Modules and External Profiles

# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module -Name Terminal-Icons

# PowerShell parameter completion shim for the winget CLI
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

function Clear-Cache {
    # add clear cache logic here
    Write-Host 'Clearing cache...' -ForegroundColor Cyan

    # Clear Windows Prefetch
    Write-Host 'Clearing Windows Prefetch...' -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    # Clear Windows Temp
    Write-Host 'Clearing Windows Temp...' -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear User Temp
    Write-Host 'Clearing User Temp...' -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Internet Explorer Cache
    Write-Host 'Clearing Internet Explorer Cache...' -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host 'Cache clearing completed.' -ForegroundColor Green
}

function uptime {
    try {
        # check powershell version
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)
        }
        else {
            $lastBootStr = net statistics workstation | Select-String 'since' | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
            # check date format
            if ($lastBootStr -match '^\d{2}/\d{2}/\d{4}') {
                $dateFormat = 'dd/MM/yyyy'
            }
            elseif ($lastBootStr -match '^\d{2}-\d{2}-\d{4}') {
                $dateFormat = 'dd-MM-yyyy'
            }
            elseif ($lastBootStr -match '^\d{4}/\d{2}/\d{2}') {
                $dateFormat = 'yyyy/MM/dd'
            }
            elseif ($lastBootStr -match '^\d{4}-\d{2}-\d{2}') {
                $dateFormat = 'yyyy-MM-dd'
            }
            elseif ($lastBootStr -match '^\d{2}\.\d{2}\.\d{4}') {
                $dateFormat = 'dd.MM.yyyy'
            }
            
            # check time format
            if ($lastBootStr -match '\bAM\b' -or $lastBootStr -match '\bPM\b') {
                $timeFormat = 'h:mm:ss tt'
            }
            else {
                $timeFormat = 'HH:mm:ss'
            }

            $bootTime = [System.DateTime]::ParseExact($lastBootStr, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        # Format the start time
        ### $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $formattedBootTime = $bootTime.ToString('dddd, MMMM dd, yyyy HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBootStr]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

        # calculate uptime
        $uptime = (Get-Date) - $bootTime

        # Uptime in days, hours, minutes, and seconds
        $days = $uptime.Days
        $hours = $uptime.Hours
        $minutes = $uptime.Minutes
        $seconds = $uptime.Seconds

        # Uptime output
        Write-Host ('Uptime: {0} days, {1} hours, {2} minutes, {3} seconds' -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue
        

    }
    catch {
        Write-Error 'An error occurred while retrieving system uptime.'
    }
}

# Navigation Shortcuts
function docs { 
    $docs = if (([Environment]::GetFolderPath('MyDocuments'))) { ([Environment]::GetFolderPath('MyDocuments')) } else { $HOME + '\Documents' }
    Set-Location -Path $docs
}
    
function dtop { 
    $dtop = if ([Environment]::GetFolderPath('Desktop')) { [Environment]::GetFolderPath('Desktop') } else { $HOME + '\Documents' }
    Set-Location -Path $dtop
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    PredictionSource              = 'HistoryAndPlugin'
    PredictionViewStyle           = 'InlineView'
}

Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $line -match $_ }
    return ($null -eq $hasSensitive)
}

# Improved prediction settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -MaximumHistoryCount 10000

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

function Open-Solution() {
    $solutions = Get-ChildItem -Path '*.sln'

    if ($solutions.Count -eq 1) {
        & $solutions.FullName
    }
    elseif ($solutions.Count -eq 0) {
        Write-Host "I couldn't find any solution files here!"
    }
    elseif ($solutions.Count -gt 1) {
        Write-Host 'I found more than solution. Which one do you want to open?'
        $solutions | ForEach-Object { Write-Host " - $($_.FullName)" }
    }
}

Set-Alias sln Open-Solution

#
# Oh My Posh setup
# Should be configured after PSReadLine
#

oh-my-posh init pwsh --config $OhMyPoshConfigFile | Invoke-Expression

function __oh-my-posh_debug {
    if ($env:BASH_COMP_DEBUG_FILE) {
        "$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
    }
}

filter __oh-my-posh_escapeStringWithSpecialChars {
    $_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&', '`$&'
}

[scriptblock]${__oh_my_poshCompleterBlock} = {
    param(
        $WordToComplete,
        $CommandAst,
        $CursorPosition
    )

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __oh-my-posh_debug ''
    __oh-my-posh_debug '========= starting completion logic =========='
    __oh-my-posh_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CursorPosition location, so we need
    # to truncate the command-line ($Command) up to the $CursorPosition location.
    # Make sure the $Command is longer then the $CursorPosition before we truncate.
    # This happens because the $Command does not include the last space.
    if ($Command.Length -gt $CursorPosition) {
        $Command = $Command.Substring(0, $CursorPosition)
    }
    __oh-my-posh_debug "Truncated command: $Command"

    $ShellCompDirectiveError = 1
    $ShellCompDirectiveNoSpace = 2
    $ShellCompDirectiveNoFileComp = 4
    $ShellCompDirectiveFilterFileExt = 8
    $ShellCompDirectiveFilterDirs = 16
    $ShellCompDirectiveKeepOrder = 32

    # Prepare the command to request completions for the program.
    # Split the command at the first space to separate the program and arguments.
    $Program, $Arguments = $Command.Split(' ', 2)

    $RequestComp = "$Program __complete $Arguments"
    __oh-my-posh_debug "RequestComp: $RequestComp"

    # we cannot use $WordToComplete because it
    # has the wrong values if the cursor was moved
    # so use the last argument
    if ($WordToComplete -ne '' ) {
        $WordToComplete = $Arguments.Split(' ')[-1]
    }
    __oh-my-posh_debug "New WordToComplete: $WordToComplete"


    # Check for flag with equal sign
    $IsEqualFlag = ($WordToComplete -Like '--*=*' )
    if ( $IsEqualFlag ) {
        __oh-my-posh_debug 'Completing equal sign flag'
        # Remove the flag part
        $Flag, $WordToComplete = $WordToComplete.Split('=', 2)
    }

    if ( $WordToComplete -eq '' -And ( -Not $IsEqualFlag )) {
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __oh-my-posh_debug 'Adding extra empty parameter'
        # PowerShell 7.2+ changed the way how the arguments are passed to executables,
        # so for pre-7.2 or when Legacy argument passing is enabled we need to use
        # `"`" to pass an empty argument, a "" or '' does not work!!!
        if ($PSVersionTable.PsVersion -lt [version]'7.2.0' -or
            ($PSVersionTable.PsVersion -lt [version]'7.3.0' -and -not [ExperimentalFeature]::IsEnabled('PSNativeCommandArgumentPassing')) -or
            (($PSVersionTable.PsVersion -ge [version]'7.3.0' -or [ExperimentalFeature]::IsEnabled('PSNativeCommandArgumentPassing')) -and
            $PSNativeCommandArgumentPassing -eq 'Legacy')) {
            $RequestComp = "$RequestComp" + ' `"`"'
        }
        else {
            $RequestComp = "$RequestComp" + ' ""'
        }
    }

    __oh-my-posh_debug "Calling $RequestComp"
    # First disable ActiveHelp which is not supported for Powershell
    ${env:OH_MY_POSH_ACTIVE_HELP} = 0

    #call the command store the output in $out and redirect stderr and stdout to null
    # $Out is an array contains each line per element
    Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null

    # get directive from last line
    [int]$Directive = $Out[-1].TrimStart(':')
    if ($Directive -eq '') {
        # There is no directive specified
        $Directive = 0
    }
    __oh-my-posh_debug "The completion directive is: $Directive"

    # remove directive (last element) from out
    $Out = $Out | Where-Object { $_ -ne $Out[-1] }
    __oh-my-posh_debug "The completions are: $Out"

    if (($Directive -band $ShellCompDirectiveError) -ne 0 ) {
        # Error code.  No completion.
        __oh-my-posh_debug 'Received error from custom completion go code'
        return
    }

    $Longest = 0
    [Array]$Values = $Out | ForEach-Object {
        #Split the output in name and description
        $Name, $Description = $_.Split("`t", 2)
        __oh-my-posh_debug "Name: $Name Description: $Description"

        # Look for the longest completion so that we can format things nicely
        if ($Longest -lt $Name.Length) {
            $Longest = $Name.Length
        }

        # Set the description to a one space string if there is none set.
        # This is needed because the CompletionResult does not accept an empty string as argument
        if (-Not $Description) {
            $Description = ' '
        }
        @{Name = "$Name"; Description = "$Description" }
    }


    $Space = ' '
    if (($Directive -band $ShellCompDirectiveNoSpace) -ne 0 ) {
        # remove the space here
        __oh-my-posh_debug 'ShellCompDirectiveNoSpace is called'
        $Space = ''
    }

    if ((($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0 ) -or
       (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0 )) {
        __oh-my-posh_debug 'ShellCompDirectiveFilterFileExt ShellCompDirectiveFilterDirs are not supported'

        # return here to prevent the completion of the extensions
        return
    }

    $Values = $Values | Where-Object {
        # filter the result
        $_.Name -like "$WordToComplete*"

        # Join the flag back if we have an equal sign flag
        if ( $IsEqualFlag ) {
            __oh-my-posh_debug 'Join the equal sign flag back to the completion value'
            $_.Name = $Flag + '=' + $_.Name
        }
    }

    # we sort the values in ascending order by name if keep order isn't passed
    if (($Directive -band $ShellCompDirectiveKeepOrder) -eq 0 ) {
        $Values = $Values | Sort-Object -Property Name
    }

    if (($Directive -band $ShellCompDirectiveNoFileComp) -ne 0 ) {
        __oh-my-posh_debug 'ShellCompDirectiveNoFileComp is called'

        if ($Values.Length -eq 0) {
            # Just print an empty string here so the
            # shell does not start to complete paths.
            # We cannot use CompletionResult here because
            # it does not accept an empty string as argument.
            ''
            return
        }
    }

    # Get the current mode
    $Mode = (Get-PSReadLineKeyHandler | Where-Object { $_.Key -eq 'Tab' }).Function
    __oh-my-posh_debug "Mode: $Mode"

    $Values | ForEach-Object {

        # store temporary because switch will overwrite $_
        $comp = $_

        # PowerShell supports three different completion modes
        # - TabCompleteNext (default windows style - on each key press the next option is displayed)
        # - Complete (works like bash)
        # - MenuComplete (works like zsh)
        # You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

        # CompletionResult Arguments:
        # 1) CompletionText text to be used as the auto completion result
        # 2) ListItemText   text to be displayed in the suggestion list
        # 3) ResultType     type of completion result
        # 4) ToolTip        text for the tooltip with details about the object

        switch ($Mode) {

            # bash like
            'Complete' {

                if ($Values.Length -eq 1) {
                    __oh-my-posh_debug 'Only one completion left'

                    # insert space after value
                    [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

                }
                else {
                    # Add the proper number of spaces to align the descriptions
                    while ($comp.Name.Length -lt $Longest) {
                        $comp.Name = $comp.Name + ' '
                    }

                    # Check for empty description and only add parentheses if needed
                    if ($($comp.Description) -eq ' ' ) {
                        $Description = ''
                    }
                    else {
                        $Description = "  ($($comp.Description))"
                    }

                    [System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
                }
            }

            # zsh like
            'MenuComplete' {
                # insert space after value
                # MenuComplete will automatically show the ToolTip of
                # the highlighted value at the bottom of the suggestions.
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }

            # TabCompleteNext and in case we get something unknown
            Default {
                # Like MenuComplete but we don't want to add a space here because
                # the user need to press space anyway to get the completion.
                # Description will not be shown because that's not possible with TabCompleteNext
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }
        }

    }
}

Register-ArgumentCompleter -CommandName 'oh-my-posh' -ScriptBlock ${__oh_my_poshCompleterBlock}

#
# Zoxide setup
# Should be configured after Oh My Posh: https://github.com/ajeetdsouza/zoxide/issues/270
#

function InitZoxide() {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    InitZoxide
}
else {
    Write-Host 'zoxide command not found. Attempting to install via winget...'
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host 'zoxide installed successfully. Initializing...'
        InitZoxide
    }
    catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

function Update-OhMyPoshConfig {
    try {
        Copy-FileFromRemoteIfDifferent -sourceFileUrl $OhMyPoshConfigUrl -destinationFile $OhMyPoshConfigFile
    }
    catch {
        Write-Error "Unable to check for Oh My Posh config updates: $_"
    }
    finally {
        Remove-Item $newProfile -ErrorAction SilentlyContinue
    }
}

function Update-Profile {
    try {
        Copy-FileFromRemoteIfDifferent -sourceFileUrl $PowerShellProfileUrl -destinationFile $PROFILE
    }
    catch {
        Write-Error "Unable to check for PowerShell profile updates: $_"
    }
    finally {
        Remove-Item $newProfile -ErrorAction SilentlyContinue
    }
}

function Copy-FileFromRemoteIfDifferent {
    param(
        [Parameter(Mandatory)]
        [string]
        $sourceFileUrl,
        [Parameter(Mandatory)]
        [string]
        $destinationFile
    )

    if (Test-Path $destinationFile -PathType Leaf -ErrorAction Stop) {
        throw [System.IO.FileNotFoundException]::new('The file is not found', $destinationFile)
    }

    $sourceFile = "$env:temp/Microsoft.PowerShell_profile_$([guid]::NewGuid().ToString()).ps1"

    try {
        Invoke-RestMethod $sourceFileUrl -OutFile $sourceFile -ErrorAction Stop
        Copy-FileIfDifferent -sourceFile $sourceFile -destinationFile $destinationFile
    }
    finally {
        Remove-Item $sourceFile -ErrorAction SilentlyContinue
    }
}

function Copy-FileIfDifferent {
    param(
        [Parameter(Mandatory)]
        [string]
        $sourceFile,
        [Parameter(Mandatory)]
        [string]
        $destinationFile
    )

    if (Test-Path $sourceFile -PathType Leaf -ErrorAction Stop) {
        throw [System.IO.FileNotFoundException]::new('The file is not found', $sourceFile)
    }

    if (Test-Path $destinationFile -PathType Leaf -ErrorAction Stop) {
        throw [System.IO.FileNotFoundException]::new('The file is not found', $destinationFile)
    }

    $sourceFileHash = (Get-FileHash $sourceFile -Algorithm SHA512 -ErrorAction Stop).Hash
    Write-Debug "Source file hash: $sourceFileHash"

    $destinationFileHash = (Get-FileHash $destinationFile -Algorithm SHA512 -ErrorAction Stop).Hash
    Write-Debug "Destination file hash: $destinationFileHash"

    if ($sourceFileHash -ne $destinationFileHash) {
        Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        Write-Verbose 'File has been copied'
    }
    else {
        Write-Verbose 'Files are the same'
    }
}
