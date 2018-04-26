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

function New-GitHubRelease {
    [CmdletBinding()]
    param ()
    process {
    
        $gitversion = (gitversion|convertfrom-json)

        $currentVersion = "v$($gitversion.SemVer.Trim())"
        $preRelease = [string]::IsNullOrEmpty(((gitversion|convertfrom-json).PreReleaseLabel).Trim()) -eq $false

        $unpushedCommits = (git branch -r --contains $gitversion.Sha) -eq $null

        if ($unpushedCommits -eq $true) {

            $response = Get-BooleanValue -Title "Unpushed Commits" -Message "Commit $($gitversion.Sha) is not in origin, push now?" -Default $true

            if ($response -eq $false) {
                Write-Host "You will want the current commits pushed befure you create a release tag - bye" -ForegroundColor DarkYellow
                return
            }

            Write-Host "Setting upstream (git push -u origin head)" -ForegroundColor Green
            git push -u origin head
            Write-Host "Pushign commits (git push origin head)" -ForegroundColor Green
            git push origin head
        }

        if (((git tag -l $currentVersion) -eq $null) -eq $false ) {
            Write-Host "Current commit already tagged with $currentVersion" -ForegroundColor Green
        }
        else {

            $response = Get-BooleanValue -Title "Tag Commit" -Message "Add & push tag $currentVersion to commit $($gitversion.Sha)?" -Default $true

            if ($response -eq $false) {
                Write-Host "Tags are required for releases - bye" -ForegroundColor DarkYellow
                return
            }

            Write-Host "Setting version tag to $currentVersion (git tag $currentVersion)" -ForegroundColor Green
            git tag $currentVersion
            Write-Host "Pushing tag $currentVersion to origin (git push origin $currentVersion)" -ForegroundColor Green
            git push origin $currentVersion
            git log -1    
        }

        if (($env:Path.Split(";").Trim() | Where-Object { $_ -like "*hub*" }) -eq $null) {
            Write-Host "Hub not installed. Install and path it to create a release (https://hub.github.com/)" -ForegroundColor Yellow
            return
        } 

        $hubResponse = (& hub release show $currentVersion) 2>&1 | Out-String

        if (($hubResponse -like "*Unable to find release with tag name*") -eq $false) {
            Write-Host "Release $currentVersion already published" -ForegroundColor Green
            return
        }

        $releaseLabel = if ($preRelease -eq $true) { "Pre-Release" } else { "Release" }
        Write-Verbose -m "Release lable => $releaseLabel"

        # Default to not creating a pre-release tag 
        $createRelease = Get-BooleanValue -Title "Create $releaseLabel" -Message "$releaseLabel $($currentVersion) not found, create now?" -Default:$(-not $preRelease)

        if ($createRelease -eq $true) {
            if ($preRelease -eq $true) {
                Write-Host "Creating $currentVersion $releaseLabel in GitHub (hub release create -p -m $($currentVersion) $($currentVersion))" -ForegroundColor Green
                Start-Process -FilePath hub -Args @("release", "create", "-p", "-m", $currentVersion, $currentVersion) -NoNewWindow -Wait
            }
            else {
                Write-Host "Creating $currentVersion $releaseLabel in GitHub (hub release create -m $($currentVersion) $($currentVersion))" -ForegroundColor Green
                Start-Process -FilePath hub -Args @("release", "create", "-m", $currentVersion, $currentVersion) -NoNewWindow -Wait
            }
        }
    }
}

Set-Alias -Name ghr -Value New-GitHubRelease
