<#
DESCRIPTION:
PL.

Skrypt:
1. Sprawdza stan usługi DNS na każdym kontrolerze domeny 
2. Wyszukuje rekordy w określonych strefach DNS.

Na koniec, zebrane dane, wysyła mailem przez O365 na wskazany poniżej adres.

ENG.

Script:
1. checks the status of the DNS service on each domain controller 
2. searches for records in specific DNS zones.

Finally, it sends the collected data by email via O365 to the address indicated below.


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   14-11-2024
Version:                v1.3
What has been added?    1. Successfully added a table with the results of the DCDiag command on the domain controllers.
                        2. Send mail via Graph connection.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [array] $DnsZone = @("<PUT_DOMAIN_ZONE>","_msdcs.<PUT_DOMAIN_ZONE>"),

    [Parameter(Mandatory=$false)]
    $DomainControllers = ((Get-ADForest).Domains | % { Get-ADDomainController -Filter * -Server $_ } | sort),

    [Parameter(Mandatory=$false)]
    $Date = (Get-Date -Format "dd-MM-yy"),

    [Parameter(Mandatory=$false)]
    $Date2 = ($((Get-Date).ToString()))
)

function Send-MailGraph {
    param(
        # Configuration
        $ClientId = "<PUT_CLIENT_ID>",
        $TenantId = "<PUT_TENANT_ID>",
        $ClientSecret = "<PUT_SECRET_KEY>"
    )
    # Convert the client secret to a secure string
    $ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    
    # Create a credential object using the client ID and secure string
    $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretPass
    
    # Connect to Microsoft Graph with Client Secret
    Connect-MgGraph -TenantId $TenantId `
                    -ClientSecretCredential $ClientSecretCredential `
                    -NoWelcome
    
    # Email details
    $FromAddress = "<PUT_MAIL_ADDRESS>"
    $ToAddress   = "<PUT_MAIL_ADDRESS>"
    $subject     = "Healthy DNS - $Date"
    $body        = $Report
    $type        = "HTML" #Or you can choose "Text"
    $save        = "false" #Or you can choose "true"
    
    $params = @{
        Message         = @{
            Subject       = $subject
            Body          = @{
                ContentType = $type
                Content     = $body
            }
            ToRecipients  = @(
                @{
                    EmailAddress = @{
                        Address = $ToAddress
                    }
                }
            )
        }
        SaveToSentItems = $save
    }
    # Send message
    Write-Verbose "Sending to $ToAddress..." -Verbose

    Send-MgUserMail -UserId $FromAddress -BodyParameter $params
}



Write-Verbose "Starting script... `n" -Verbose

Write-Verbose "Checking controllers via DCDiag... `n" -Verbose

$Report = @()

# Looping through domain controllers
foreach ($DC in $DomainControllers) {
    $result = New-Object PSObject -Property @{
        ControllerName        = $DC
        DnsBasic              = ""
        DnsRecordRegistration = ""
        DnsDynamicUpdate      = ""
    }

    # Execution of dcdiag commands and analysis of results
    $dcdiagCommand               = "dcdiag /test:dns /v /s:$DC /DnsBasic"
    $dnsBasicResult              = Invoke-Expression -Command $dcdiagCommand
    $dcdiagCommand               = "dcdiag /test:dns /v /s:$DC /DnsRecordRegistration"
    $dnsRecordRegistrationResult = Invoke-Expression -Command $dcdiagCommand
    $dcdiagCommand               = "dcdiag /test:dns /v /s:$DC /DnsDynamicUpdate"
    $dnsDynamicUpdateResult      = Invoke-Expression -Command $dcdiagCommand

    $result.DnsBasic              = if ($dnsBasicResult -match "passed" -or $dnsBasicResult -match "passed test") { "Pass" } else { "Fail" }
    $result.DnsRecordRegistration = if ($dnsRecordRegistrationResult -match "passed" -or $dnsRecordRegistrationResult -match "passed test") { "Pass" } else { "Fail" }
    $result.DnsDynamicUpdate      = if ($dnsDynamicUpdateResult -match "passed" -or $dnsDynamicUpdateResult -match "passed test") { "Pass" } else { "Fail" }

    $Report += $result
}

# Looping through DNS zones
foreach ($Zone in $DnsZone) {
    Write-Verbose "Generating SOA records in $Zone zone... `n" -Verbose

    $zoneReport = @()

    foreach ($DC in $DomainControllers) {
        $output = Get-DnsServerResourceRecord -ComputerName $DC -ZoneName $Zone -RRType SOA | 
            Select-Object @{Name='DomainController'; Expression={$_.RecordData.PrimaryServer}}, `
            @{'Name'='Zone'; Expression={$Zone}}, `
            RecordType, `
            TimeToLive, `
            @{Name='RecordData'; Expression={$_.RecordData.SerialNumber}} | Sort-Object DomainController
        
        $zoneReport += $output
    }

    # Generation to HTML format
    $zoneReportTable = $zoneReport | ConvertTo-Html -Fragment -PreContent "<h3><center>DNS zone - $Zone</center></h3><br>"
    $Report += $zoneReportTable
}

# Prepare DCdiag results for the report
$DCDiagResults = @"
<h3 style="text-align: center;">DCDiag Results</h3>
<table>
<tr>
    <th>DomainController</th>
    <th>DnsBasic</th>
    <th>DnsRecordRegistration</th>
    <th>DnsDynamicUpdate</th>
</tr>
"@
foreach ($DC in $DomainControllers) {
    $dnsBasicStatus              = if (($Report | Where-Object { $_.ControllerName -eq $DC }).DnsBasic -eq "Pass") { "Pass" } else { "Fail" }
    $dnsRecordRegistrationStatus = if (($Report | Where-Object { $_.ControllerName -eq $DC }).DnsRecordRegistration -eq "Pass") { "Pass" } else { "Fail" }
    $dnsDynamicUpdateStatus      = if (($Report | Where-Object { $_.ControllerName -eq $DC }).DnsDynamicUpdate -eq "Pass") { "Pass" } else { "Fail" }

    $DCDiagResults += @"
<tr>
    <td>$DC</td>
    <td style="background-color: $(if ($dnsBasicStatus -eq 'Pass') { '#7FFF00' } else { '#FF0000' }); color: $(if ($dnsBasicStatus -eq 'Pass') { '#000000' } else { '#FFFFFF' });">$dnsBasicStatus</td>
    <td style="background-color: $(if ($dnsRecordRegistrationStatus -eq 'Pass') { '#7FFF00' } else { '#FF0000' }); color: $(if ($dnsRecordRegistrationStatus -eq 'Pass') { '#000000' } else { '#FFFFFF' });">$dnsRecordRegistrationStatus</td>
    <td style="background-color: $(if ($dnsDynamicUpdateStatus -eq 'Pass') { '#7FFF00' } else { '#FF0000' }); color: $(if ($dnsDynamicUpdateStatus -eq 'Pass') { '#000000' } else { '#FFFFFF' });">$dnsDynamicUpdateStatus</td>
</tr>
"@
}
$DCDiagResults += "</table>"

# Convert to HTML
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

$Report = $Header + $DCDiagResults + $Report + $footer

Write-Host ""

# Send message
try{
    # using loaded function Send-MailGraph
    Send-MailGraph

    Write-Host "VERBOSE: Done! `n" -f Green
    Start-Sleep -s 2
}
catch{
    Write-Host "Failed to send email: $($_.Exception.Message)"
}
