$gitversion = (gitversion|convertfrom-json)

$currentVersion = "v$($gitversion.SemVer.Trim())"

if (((git tag -l $currentVersion) -eq $null) -eq $false ) {
    Write-Host "Current version already set at $currentVersion" -ForegroundColor Yellow
}
else {
    Write-Host "Setting version tag to $currentVersion" -ForegroundColor Green
    git tag $currentVersion
    git log -1    
}

if (($env:Path.Split(";").Trim() | Where-Object { $_ -like "*hub*" }) -eq $null) {
    Write-Host "Hub not installed. Install and path it to create a release (https://hub.github.com/)" -ForegroundColor Yellow
    return
} 

$hubResponse = (& hub release show $currentVersion) 2>&1 | Out-String

if (($hubResponse -like "*Unable to find release with tag name*") -eq $false) {
    Write-Host "Release found" -ForegroundColor Green
    return
}

function Get-BooleanValue {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Message,
        [boolean]$Default
    )

    $index = if ($Default) { 0 } else { 1 }
    $enabled = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Enable $Title"
    $disabled = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Disable $Title"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($enabled, $disabled)
    $result = $Host.UI.PromptForChoice($Title, $Message, $options, $index)
    $flag = if ($result) { $false } else { $true }
    return $flag
}

$response = Get-BooleanValue -Title "Create Release" -Message "Release $($currentVersion) not found, create now?" -Default $false

if ($response -eq $true) {
    Write-Host "Creating $currentRelease release in GitHub"
}