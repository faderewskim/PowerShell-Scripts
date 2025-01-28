<#
DESCRIPTION: 
PL.
Skrypt ma na celu usunięcie plików z rozszerzeniem .msp w lokalizacji C:\Windows\Installer\
Pliki zapychają dysk C:

ENG.
The script is designed to remove files with the .msp extension in the C:Windows location.
The files are clogging up the C: partition


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   18-02-2023
Version:                v1.0
What has been added?    1. Empty
#>


<# : batch script
@echo off
setlocal
cd %~dp0
powershell -executionpolicy remotesigned -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))"
endlocal
goto:eof
#>

$MSP_path = cd C:\Windows\Installer\

Write-Verbose "Initializing process..." -Verbose


if(![System.IO.File]::Exists($MSP_path))
{
    $MSP_path2 = Get-ChildItem .\*.msp | Measure-Object

    if( -not ($MSP_path2.Count -eq "0"))
    {
        $Files = Get-ChildItem '.\*.msp'
        foreach($File in $Files)
        {
            $File | Remove-Item -Verbose -Recurse -Force

        }
            Write-Verbose "Files deleted!" -Verbose
            Start-Sleep -Seconds 4
            exit
    }
    else
    { 
        Write-Host "No files with the extension .msp" -ForegroundColor Green 
        Start-Sleep 4
        exit
    }
}
else
{
    Write-Host "Path no exist!" -ForegroundColor Red
	Start-Sleep -Seconds 4
    exit    
}
