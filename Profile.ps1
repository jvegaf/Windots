# Initialise logging - helpful for debugging slow profile load times
$enableLog = $false

if ($enableLog) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $logPath = "$env:USERPROFILE/Profile.log"
}
function Add-ProfileLogEntry {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    if (!$enableLog) {
        return
    }

    "`n$($stopwatch.ElapsedMilliseconds)ms`t$Message" | Out-File -FilePath $logPath -Append
}
Add-ProfileLogEntry "Starting profile load"

${function:~} = { Set-Location ~ }
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ..\.. }
${function:....} = { Set-Location ..\..\.. }
${function:.....} = { Set-Location ..\..\..\.. }
${function:......} = { Set-Location ..\..\..\..\.. }

# Set Dark Mode
function darkMode
{
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
}

function lightMode
{
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1
}

function nvcfg
{
  Set-Location ~/AppData/Local/nvim/
}

function rmd($arg)
{
  Remove-Item -Recurse -Force $arg
}

# Git
Set-Alias g lazygit
function gaa
{
  git add -A
}
function gcm
{
  git commit -m
}
function gcl
{
  git clone
}
function gf
{
  git fetch --all -p
}
function gps
{
  git push
}
function gs
{
  git status -sb
}
function gsw($branch)
{
  git switch $branch
}

function gba
{
  git branch --all
}

function dotfiles
{
  Set-Location $env:USERPROFILE/.dotfiles
}

#search on google
function gg ($query)
{
  Start-Process "www.google.com/search?q=$query"
}

#winget
function ws ($query)
{
  winget search $query
}
function wi ($query)
{
  winget install $query
}


#chocolatey
function cs ($query)
{
  choco search $query
}
function ci ($query)
{
  cinst $query
}


#scoop
function scs ($query)
{
  scoop search $query
}
function sci ($query)
{
  scoop install $query
}

function o.{
  explorer .
}

function i. {
  idea .
}

function v. {
  nvim .
}

# Navigation Shortcuts
${function:cdc} = { Set-Location ~\Code }
${function:dt} = { Set-Location "$PSScriptRoot\..\..\Desktop" }
${function:doc} = { Set-Location "$PSScriptRoot\.." }
${function:dl} = { Set-Location ~\Downloads }
# Aliases
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Set-Alias -Name su -Value Start-AdminSession
Set-Alias -Name up -Value Update-Profile
Set-Alias -Name ff -Value Find-File
Set-Alias -Name grep -Value Find-String
Set-Alias -Name touch -Value New-File
Set-Alias -Name df -Value Get-Volume
Set-Alias -Name which -Value Show-Command
Set-Alias -Name tif Show-ThisIsFine
Set-Alias -Name v -Value nvim
Set-Alias -Name vi -Value nvim
Set-Alias -Name cat -Value bat
Set-Alias -Name us -Value Update-Software

Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias reboot Restart-Computer

# Directory Listing: Use `ls.exe` if available
if (Get-Command lsd.exe -ErrorAction SilentlyContinue | Test-Path)
{
  Remove-Item alias:ls -ErrorAction SilentlyContinue
  # Set `ls` to call `ls.exe` and always use --color
  ${function:ls} = { lsd.exe --color @args }
  # List all files in long format
  ${function:l} = { ls -lF @args }
  # List all files in long format, including hidden files
  ${function:ll} = { ls -laF @args }
  # List only directories
  ${function:lld} = { Get-ChildItem -Directory -Force @args }
} else
{
  # List all files, including hidden files
  ${function:ll} = { ls -Force @args }
  # List only directories
  ${function:ldd} = { Get-ChildItem -Directory -Force @args }
  Set-Alias l ls
}
Add-ProfileLogEntry "Aliases loaded"

# Putting the FUN in Functions
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function Find-WindotsRepository {
    <#
    .SYNOPSIS
        Finds the local Windots repository.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ProfilePath
    )

    Write-Verbose "Resolving the symbolic link for the profile"
    $profileSymbolicLink = Get-ChildItem $ProfilePath | Where-Object FullName -EQ $PROFILE.CurrentUserAllHosts
    return Split-Path $profileSymbolicLink.Target
}
function Get-LatestProfile {
    <#
    .SYNOPSIS
        Checks the Github repository for the latest commit date and compares to the local version.
        If the profile is out of date, instructions are displayed on how to update it.
    #>

    Write-Verbose "Checking for updates to the profile"
    $currentWorkingDirectory = $PWD
    Set-Location $ENV:WindotsLocalRepo
    $gitStatus = git status

    if ($gitStatus -like "*Your branch is up to date with*") {
        Write-Verbose "Profile is up to date"
        Set-Location $currentWorkingDirectory
        return
    }
    else {
        Write-Verbose "Profile is out of date"
        Write-Host "Your PowerShell profile is out of date with the latest commit. To update it, run Update-Profile." -ForegroundColor Yellow
        Set-Location $currentWorkingDirectory
    }
}
function Start-AdminSession {
    <#
    .SYNOPSIS
        Starts a new PowerShell session with elevated rights. Alias: su
    #>
    Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command &{Set-Location $PWD}"
}

function Update-Profile {
    <#
    .SYNOPSIS
        Downloads the latest version of the PowerShell profile from Github, updates the PowerShell profile with the latest version and reruns the setup script.
        Note that functions won't be updated, this requires a full restart. Alias: up
    #>
    Write-Verbose "Storing current working directory in memory"
    $currentWorkingDirectory = $PWD

    Write-Verbose "Updating local profile from Github repository"
    Set-Location $ENV:WindotsLocalRepo
    git pull | Out-Null

    Write-Verbose "Rerunning setup script to capture any new dependencies."
    Start-Process pwsh -Verb runAs -WorkingDirectory $PWD -ArgumentList "-Command .\Setup.ps1"

    Write-Verbose "Reverting to previous working directory"
    Set-Location $currentWorkingDirectory

    Write-Verbose "Re-running profile script from $($PROFILE.CurrentUserAllHosts)"
    .$PROFILE.CurrentUserAllHosts
}

function Update-Software {
    <#
    .SYNOPSIS
        Updates all software installed via Winget & Chocolatey. Alias: us
    #>
    Write-Verbose "Updating software installed via Winget & Chocolatey"
    Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -Command &{winget upgrade --all && choco upgrade all -y}"
    $ENV:UpdatesPending = ''
}

function Find-File {
    <#
    .SYNOPSIS
        Finds a file in the current directory and all subdirectories. Alias: ff
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
        [string]$SearchTerm
    )

    Write-Verbose "Searching for '$SearchTerm' in current directory and subdirectories"
    $result = Get-ChildItem -Recurse -Filter "*$SearchTerm*" -ErrorAction SilentlyContinue

    Write-Verbose "Outputting results to table"
    $result | Format-Table -AutoSize
}

function Find-String {
    <#
    .SYNOPSIS
        Searches for a string in a file or directory. Alias: grep
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SearchTerm,
        [Parameter(ValueFromPipeline, Mandatory = $false, Position = 1)]
        [string]$Directory,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    Write-Verbose "Searching for '$SearchTerm' in '$Directory'"
    if ($Directory) {
        if ($Recurse) {
            Write-Verbose "Searching for '$SearchTerm' in '$Directory' and subdirectories"
            Get-ChildItem -Recurse $Directory | Select-String $SearchTerm
            return
        }

        Write-Verbose "Searching for '$SearchTerm' in '$Directory'"
        Get-ChildItem $Directory | Select-String $SearchTerm
        return
    }

    if ($Recurse) {
        Write-Verbose "Searching for '$SearchTerm' in current directory and subdirectories"
        Get-ChildItem -Recurse | Select-String $SearchTerm
        return
    }

    Write-Verbose "Searching for '$SearchTerm' in current directory"
    Get-ChildItem | Select-String $SearchTerm
}

function New-File {
    <#
    .SYNOPSIS
        Creates a new file with the specified name and extension. Alias: touch
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    Write-Verbose "Creating new file '$Name'"
    New-Item -ItemType File -Name $Name -Path $PWD | Out-Null
}

function Show-Command {
    <#
    .SYNOPSIS
        Displays the definition of a command. Alias: which
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )
    Write-Verbose "Showing definition of '$Name'"
    Get-Command $Name | Select-Object -ExpandProperty Definition
}

function Get-OrCreateSecret {
    <#
    .SYNOPSIS
        Gets secret from local vault or creates it if it does not exist. Requires SecretManagement and SecretStore modules and a local vault to be created.
        Install Modules with:
            Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
        Create local vault with:
            Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
            Set-SecretStoreConfiguration -Authentication None -Confirm:$False

        https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/

    .PARAMETER secretName
        Name of the secret to get or create. It is recommended to use the username or public key / client id as secret name to make it easier to identify the secret later.

    .EXAMPLE
        $password = Get-OrCreateSecret -secretName $username

    .EXAMPLE
        $clientSecret = Get-OrCreateSecret -secretName $clientId

    .OUTPUTS
        System.String
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$secretName
    )

    Write-Verbose "Getting secret $secretName"
    $secretValue = Get-Secret $secretName -AsPlainText -ErrorAction SilentlyContinue

    if (!$secretValue) {
        $createSecret = Read-Host "No secret found matching $secretName, create one? Y/N"

        if ($createSecret.ToUpper() -eq "Y") {
            $secretValue = Read-Host -Prompt "Enter secret value for ($secretName)" -AsSecureString
            Set-Secret -Name $secretName -SecureStringSecret $secretValue
            $secretValue = Get-Secret $secretName -AsPlainText
        }
        else {
            throw "Secret not found and not created, exiting"
        }
    }
    return $secretValue
}

function Get-ChildItemPretty {
    <#
    .SYNOPSIS
        Runs eza with a specific set of arguments. Plus some line breaks before and after the output.
        Alias: ls, ll, la, l
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = $PWD
    )

    Write-Host ""
    eza -a -l --header --icons --hyperlink --time-style relative $Path
    Write-Host ""
}

function Show-ThisIsFine {
    <#
    .SYNOPSIS
        Displays the "This is fine" meme in the console. Alias: tif
    #>
    Write-Verbose "Running thisisfine.ps1"
    Invoke-Expression (Get-Content "$env:WindotsLocalRepo\art\thisisfine.ps1" -Raw)
}

Add-ProfileLogEntry -Message "Functions loaded"

# Environment Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
$ENV:WindotsLocalRepo = Find-WindotsRepository -ProfilePath $PSScriptRoot
$ENV:STARSHIP_CONFIG = "$ENV:WindotsLocalRepo\starship\starship.toml"
$ENV:_ZO_DATA_DIR = $ENV:WindotsLocalRepo

# Check for Git updates while prompt is loading
Start-Job -ScriptBlock { Set-Location $ENV:WindotsLocalRepo && git fetch --all } | Out-Null

Add-ProfileLogEntry -Message "Git fetch job started"

Start-ThreadJob -ScriptBlock {
    <#
        This is gross, I know. But there's a noticible lag that manifests in powershell when running the winget and choco commands
        within the main pwsh process. Running this whole block as an isolated job fails to set the environment variable correctly.
        The compromise is to run the main logic of this block within a threadjob and get the output of the winget and choco commands
        via two isolated jobs. This sets the environment variable correctly and doesn't cause any lag (that I've noticed yet).
    #>
    $wingetUpdatesString = Start-Job -ScriptBlock { winget list --upgrade-available | Out-String } | Wait-Job | Receive-Job
    $chocoUpdatesString = Start-Job -ScriptBlock { choco upgrade all --noop | Out-String } | Wait-Job | Receive-Job
    if ($wingetUpdatesString -match "upgrades available" -or $chocoUpdatesString -notmatch "can upgrade 0/") {
        $ENV:UpdatesPending = "`u{eb29}  "
    }
    else {
        $ENV:UpdatesPending = ""
    }
} | Out-Null

Add-ProfileLogEntry -Message "Update check job started"

# Prompt Setup
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })

Add-ProfileLogEntry -Message "Prompt setup complete"

# Check for updates
Get-LatestProfile

$enableLog ? $stopwatch.Stop() : $null
Add-ProfileLogEntry -Message "Profile load complete"

