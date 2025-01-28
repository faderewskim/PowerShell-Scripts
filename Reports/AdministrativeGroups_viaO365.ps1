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
    $Date  = (Get-Date -Format "MM-yyyy"),
    $Date2 = ($((Get-Date).ToString())),

    [Parameter(Mandatory=$false)]
    [array] $AdminGroups = @("Domain Admins","Schema Admins","Enterprise Admins")
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
    $subject     = "Administrative Groups for period - $Date"
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

#Generating a report

Write-Verbose "Generating a report..." -Verbose

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
