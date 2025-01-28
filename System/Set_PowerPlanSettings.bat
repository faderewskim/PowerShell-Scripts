<#
DESCRIPTION:
PL.
Skrypt wyłącza opcję usypiania dysku twardego po konkretnym czasie. Wartość jest ustawiana na zero.

ENG.
The script disables the option to put the hard drive to sleep after a specific time. The value is set to zero.


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   18-02-2023
Version:                v1.0
What has been added?    1. Empty
#>

powercfg /SETDCVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0

powercfg /SETACVALUEINDEX SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
