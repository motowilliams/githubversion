function Get-GitVersion {
    [CmdletBinding()]
    param()
    
    process {
        return (gitversion|convertfrom-json)
    }
}

Set-Alias -Name gitver -Value Get-GitVersion

Export-ModuleMember -Function Get-GitVersion
Export-ModuleMember -Alias gitver
