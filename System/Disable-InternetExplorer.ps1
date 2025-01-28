<#
DESCRIPTION: 
PL.
Wyłączenie IE11 na serwerze.

ENG.
Disable IE11 on the server.

Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   08-10-2024
Version:                v1.0
What has been added?    1. Empty
#>

param (
    [Parameter()]
    $statusIE = (Get-WindowsOptionalFeature -Online –FeatureName Internet-Explorer-Optional-amd64).State
)

if ($statusIE -eq 'Enabled') {
    dism /online /disable-feature /featurename:Internet-Explorer-Optional-amd64 /NoRestart
}
else { break }
