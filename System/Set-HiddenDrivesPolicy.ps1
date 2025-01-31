<#
DESCRIPTION: 
PL.
Skrypt tworzy lub aktualizuje wartość rejestru NoDrives w lokalizacjach:
1. HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer lub
2. HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer
Może być używany do ukrywania dysków w Eksploratorze Windows dla bieżącego użytkownika lub w kontekście komputera.

ENG.
The script creates or updates the NoDrives registry value in the locations:
1. HKCU:\NSOFTWARE\NMicrosoftWindows\NCurrentVersion\NPoliciesExplorer or
2. HKLM:\NSOFTWARE\NMicrosoft\NWindows\NCurrentVersion\NPoliciesExplorer.
Can be used to hide drives in Windows Explorer for the current user or in the context of the computer.

.LINK
https://support.microsoft.com/en-us/topic/hide-physical-drives-in-windows-explorer-25e8ddaf-b6d4-e5ac-5342-ff22eaefb2f1


Name/Surname:           Mateusz Faderewski
Job:                    System Engineer
Date:                   31-01-2025
Version:                v1.0
What has been added?    1. Empty
#>


param(  
    [ValidateNotNullorEmpty()] 
    [string] $nameDWORD = ("NoDrives"),
                    
    [Parameter(Mandatory=$false)] 
    #$registryPath = ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")
    $registryPath = ("HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")
)


if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $nameDWORD -Force | Out-Null
}

else {
    New-ItemProperty -Path $registryPath -Name $nameDWORD -Force | Out-Null
}
