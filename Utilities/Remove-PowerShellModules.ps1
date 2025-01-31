<#
DESCRIPTION: 
PL.
Skrypt umożliwia odinstalowanie modułów PowerShell na podstawie ich nazwy lub wzorca.
1. Domyślnie usuwa wszystkie moduły pasujące do określonego wzorca.
2. Umożliwia podanie konkretnej nazwy modułu do usunięcia.
3. Usuwa wszystkie wersje danego modułu i wymusza jego deinstalację.

ENG.
This script allows you to uninstall PowerShell modules based on their name or pattern.
1. By default, it removes all modules matching a given pattern.
2. Allows specifying a specific module name for removal.
3. Removes all versions of a module and forces uninstallation.


Name/Surname:           Mateusz Faderewski
Job:                    System Engineer
Date:                   31-01-2025
Version:                v1.0
What has been added?    1. Empty
#>


param(
    [Parameter(Mandatory=$false)] 
    #[string] $moduleName = "<PUT_MODULE_NAME>", # example 'Microsoft.Graph*'
    [string] $moduleName = "Microsoft.Graph*", # example 'Microsoft.Graph*'

    [Parameter(Mandatory=$false)] 
    [array] $Modules = (Get-InstalledModule | ? {$_.Name -like $moduleName}).Name
)

foreach($module in $Modules){
    try {
        Uninstall-Module -Name $module -AllVersions -Force -ErrorAction Stop
        Write-Verbose "$($module) module has been removed from your computer!" -Verbose
    }
    catch { 
        throw $_.Exception 
    }
}
