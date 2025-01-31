<#
DESCRIPTION: 
PL.
Skrypt analizuje użytkowników Microsoft 365 pod kątem ich licencji i skrzynek pocztowych. Sprawdza dwie sytuacje:
.PART1 - Użytkownicy z licencją, ale bez skrzynki pocztowej – identyfikuje konta, które mają przypisaną licencję, ale nie posiadają aktywnej skrzynki e-mail.
.PART2 - Użytkownicy z wyłączonymi kontami, którzy nadal mają skrzynkę pocztową – wykrywa użytkowników z dezaktywowanymi kontami, którzy nadal posiadają skrzynki pocztowe w Exchange Online.

ENG.
The script analyzes Microsoft 365 users based on their licenses and mailboxes. It checks two scenarios:
.PART1 - Users with a license but no mailbox – identifies accounts that have an assigned license but do not have an active email mailbox.
.PART2 - Disabled users who still have a mailbox – detects users with deactivated accounts who still retain their Exchange Online mailboxes.


Name/Surname:           Mateusz Faderewski
Job:                    System Engineer
Date:                   31-01-2025
Version:                v1.0
What has been added?    1. Empty
#>


param(
    [ValidateNotNullorEmpty()]
    [array] $skuPartNumber = @("O365_BUSINESS_ESSENTIALS", "SPB"),

    [ValidateNotNullorEmpty()]
    [array] $mgProperties  = @("UserPrincipalName", "DisplayName", "Id", "AssignedLicenses", "AccountEnabled")
)

#Import-Module Microsoft.Graph
#Import-Module ExchangeOnlineManagement

Connect-MgGraph -Scopes "Directory.Read.All", "User.Read.All", "Organization.Read.All"
Connect-ExchangeOnline

# .PART1

$GraphUsers = $null

foreach ($sku in $skuPartNumber) {

    $subscribedSku = Get-MgSubscribedSku -All | where SkuPartNumber -eq $sku
    
    $mgUser = Get-MgUser -Filter "assignedLicenses/any(x:x/skuId eq $($subscribedSku.SkuId))" -All -Property $mgProperties | 
        sort UserPrincipalName |
            select UserPrincipalName, `
            DisplayName, `
            Id, `
            AccountEnabled, `
            @{l="isLicensed";e={($_.AssignedLicenses.Count -gt 0)}}
    
    $GraphUsers += $mgUser
    $GraphUsers
}
Write-Host ""
Write-Verbose "Total accounts with the licenses: $($GraphUsers.Count) `n" -Verbose

$usersWithoutMailbox = @()

Write-Verbose "Users who have a license but do not have a mailbox..." -Verbose
$GraphUsers | ForEach-Object {
    if (!(Get-Mailbox $_.UserprincipalName -ErrorAction SilentlyContinue)) {
        $usersWithoutMailbox += $_.UserPrincipalName
    }
}

if ($usersWithoutMailbox.Count -eq 0) {
    Write-Host "No users without a mailbox.`n" -f Green
} else {
    Write-Host "List of users without a mailbox:" -f Yellow
    $usersWithoutMailbox | ForEach-Object { Write-Host $_ }
}


# .PART2 

$usersDisabled = @()

$DisabledGraphUsers = $GraphUsers | Where-Object { $_.AccountEnabled -eq $false }

Write-Verbose "Total disabled accounts with the licenses: $($DisabledGraphUsers.Count) `n" -Verbose

$DisabledGraphUsers | ForEach-Object {
    if (Get-Mailbox $_.UserPrincipalName -ErrorAction SilentlyContinue) {
        $usersDisabled += $_.UserPrincipalName
    }
}

if ($usersDisabled.Count -eq 0) {
    Write-Host "No users without a mailbox." -f Green
} else {
    Write-Host "List of users without a mailbox:" -f Yellow
    $usersDisabled | ForEach-Object { Write-Host $_ }
}
