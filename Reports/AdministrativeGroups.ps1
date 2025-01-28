<#
DESCRIPTION: 
PL.
Skrypt generujący listę kont z uprawnieniami: Domain, Schema i Enterprise Admins.

ENG.
A script that generates a list of accounts with permissions: Domain, Schema and Enterprise Admins.


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   18-02-2023
Version:                v1.0
What has been added?    1. Empty
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string] $Date  = (Get-Date -Format "MM-yyyy"),
    [string] $Date2 = (Get-Date).ToString(),

    [Parameter(Mandatory=$false)]
    [string] $FileName = ("AdministrativeGroups"),

    [Parameter(Mandatory=$false)]
    [array] $AdminGroups = @("Domain Admins","Schema Admins","Enterprise Admins")
)

#Generating a report
$Body = $null

foreach ($Group in $AdminGroups) {
    $Report = Get-ADGroupMember -Identity $Group | 
        Get-ADUser -Properties * |
            sort samAccountName | 
            select samAccountName, `
            Name, `
            PasswordLastSet, `
            PasswordNeverExpires, `
            Enabled, `
            @{Name="Group";Expression={$Group}}
            
            
    $Report = $Report | ConvertTo-Html -Fragment -PreContent "<h2><center>Domain Administrative Accounts - $Group</center></h2><br>"
    $Body += $Report
} 

#Convert to HTML

$Header = @"
<style>

    TABLE { 
        border-width: 1px; 
        border-style: solid; 
        border-color: black; 
        border-collapse: collapse; 
    }

    TH { 
        border-width: 1px; padding: 3px; 
        border-style: solid; 
        border-color: black; background-color: #DBDEDC; 
    }

    TD { 
        border-width: 1px; padding: 3px; 
        border-style: solid; 
        border-color: black; 
    }
      
</style>
"@

$footer = @" 
    <br><small><i>The report was generated automatically at $Date2 on server $env:COMPUTERNAME.</i></small>
    <br>
    <br>
"@

$Report = ConvertTo-Html -Head $Header -Body $Body -PostContent $Footer
$Report = ([string]::Join("", $Report.split("`n"))).replace("<table></table>", "")


#Sending e-mail

$FromAddress = '<PUT_MAIL_ADDRESS>'
$ToAddress   = @('<PUT_MAIL_ADDRESS>')
$Encoding    = 'UTF8'
$SmtpServer  = 'PUT_SMTP_SERVER'
$Subject     = "Administrative groups for the period - $Date"


$mailparams = @{
    From        = $FromAddress
    To          = $ToAddress
    Subject     = $Subject
    Body        = $Report -join ""
    BodyAsHTML  = $True
    Encoding    = $Encoding
    SmtpServer  = $SmtpServer
}

Write-Verbose "Sending to $ToAddress..." -Verbose
Send-MailMessage @mailparams

Write-Verbose "Done!" -Verbose
Start-Sleep -s 2
