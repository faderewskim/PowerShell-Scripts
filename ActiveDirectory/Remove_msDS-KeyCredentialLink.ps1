<#
DESCRIPTION: 
PL.
Skrypt usuwa wybranym komputerom atrybut msDS-KeyCredentialLink.

ENG.
The script removes the msDS-KeyCredentialLink attribute from the selected computers.


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   20-11-2024
Version:                v1.0
What has been added?    1. Empty
#>

param (
    [Parameter(Mandatory=$false)]
    [string] $attribute = "msds-keycredentiallink",

    [Parameter(Mandatory=$false)]
    [array] $computers = @("PUT_COMPUTER_NAME")
)

foreach ($comp in $computers) {

    try {
        $computer = Get-ADComputer -Identity $comp -Properties $attribute
        $attributeValue = $computer.$attribute

        if (-not $attributeValue) {
            Write-Warning "Attribute is empty for $($comp)"
        }
        else {
            $dn = (Get-ADComputer -Identity $comp).distinguishedName
            Set-ADObject -Identity $dn -Clear $attribute
            Write-Host "$($comp) | Removed succesfully!" -f Green }
    }
    catch { 
        Write-Host "$($_.Exception.Message)" -f Red
    }
}
