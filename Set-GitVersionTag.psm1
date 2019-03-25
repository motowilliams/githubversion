#requires -modules Get-GitVersion

function Set-GitVersionTag {
    [CmdletBinding()]
    param(
        [switch]$PushTag
    )
    
    process {

        $gitversion = Get-GitVersion
        $currentVersion = "$($gitversion.SemVer.Trim())"

        if (((git tag -l $currentVersion) -eq $null) -eq $false ) {
            Write-Host "Current commit $($gitversion.Sha) already tagged with $currentVersion" -ForegroundColor Green
        }
        else {

            $commitDetails = (git show --name-only $gitversion.Sha)
            Write-Host $commitDetails[0] -ForegroundColor Green
            Write-Host $commitDetails[1] -ForegroundColor DarkYellow
            for ($i = 2; $i -lt $commitDetails.Count; $i++) {
                Write-Host $commitDetails[$i] -ForegroundColor Yellow
            }

            $response = Get-BooleanValue -Title "Tag Commit" -Message "Add tag $currentVersion to commit $($gitversion.Sha)?" -Default $true

            if ($response -eq $false) {
                return
            }

            Write-Host "Setting version tag to $currentVersion (git tag $currentVersion)" -ForegroundColor Green
            git tag $currentVersion


        }
        
        if ($PushTag) {
            git push -u origin head
            git push origin $currentVersion
            git push origin head
        }
    }
}

Set-Alias -Name gt -Value Set-GitVersionTag

Export-ModuleMember -Function Set-GitVersionTag
Export-ModuleMember -Alias gt
