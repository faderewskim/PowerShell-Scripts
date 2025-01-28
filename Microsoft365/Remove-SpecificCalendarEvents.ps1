<#
DESCRIPTION: 
PL.
W celu usunięcia usunięcia spotkania należy dodać do aplikacji Graph w tenancie następujące uprawnienia:
Calendars.Read
Calendars.ReadWrite
Calendars.ReadBasic.All

ENG.
To delete a deleted appointment, add the following permissions to the Graph application in tenant:
Calendars.Read
Calendars.ReadWrite
Calendars.ReadBasic.All


Name/Surname:           Mateusz Faderewski
Job:                    System Engineer
Date:                   24-09-2024
Version:                v1.0
What has been added?    1. Empty
#>

# Set variables for the Microsoft Graph app
$msGraphClientId = "<PUT_CLIENT_ID>" # The app's client ID
$msGraphTenantId = "<PUT_TENANT_ID>" # The tenant ID
$msGraphCertificateThumbprint = "<PUT_CERT_THUMBPRINT>" # The certificate thumbprint for authentication

# Connect to Microsoft Graph using the app credentials
Connect-MgGraph -ClientId $msGraphClientId `
                -TenantId $msGraphTenantId `
                -CertificateThumbprint $msGraphCertificateThumbprint `
                -NoWelcome 

# Test commands section

# Define the user to work with
$userUPN = "<PUT_USER_PRINCIPAL_NAME>" 
$userId = Get-MgUser -UserId $userUPN 

# Find events with a specific subject
[array] $eventId = Get-MgUserEvent -UserId $userId.Id -All | 
            ? { $_.Subject -like "<EXAMPLE_EVENT_NAME>" } 

# Show the found event IDs
$eventId

# Loop through the found events and delete them
foreach ($event in $eventId.Id) {
    Remove-MgUserEvent -UserId $userId.Id -EventId $event 
    Write-Verbose "OK | Event: $($event) was removed!" -Verbose 
}

# Check again if any events with the same subject are left
Get-MgUserEvent -UserId $userId.Id -All |
    ? { $_.Subject -like "<EXAMPLE_EVENT_NAME>" } | fl 


# # #

<#
DESCRIPTION: 
PL.
Poniższy skrypt wykonuje to samo co powyżej, tyle że w pętli. 
Aby zadziałał poprawnie, musimy przygotować plik o rozszerzeniu .csv a w nim kolumnę: UserPrincipalName.
Najlepiej zadziała dla event'u o konkretnej nazwie (patrz linijka 84).

ENG.
The following script performs the same thing as above, only that in a loop. 
In order for it to work properly, we need to prepare a file with the extension .csv and in column: UserPrincipalName.
It will work best for an event with a specific name (see line 84).
#>

# Import the CSV file containing a list of users

$fileName = "PUT_FILENAME"
$usersFromFile = Import-Csv "./$($fileName).csv"
$users = $usersFromFile.UserPrincipalName


# Loop through each user from the list
foreach ($user in $users) {
    
    try {
        # Get the user's ID from Microsoft Graph using their User Principal Name (UPN)
        $userId = Get-MgUser -UserId $user

        # Retrieve the IDs of calendar events for this user with a specific subject
        [array] $eventId = (Get-MgUserEvent -UserId $userId.Id -All |
                    ? { $_.Subject -like "<EXAMPLE_EVENT_NAME>" }).Id
    }

    catch { 
        Write-Error -Message ('Error processing user: {0}' -f $_.Exception.Message) 
    }

    # Loop through each event ID that was found and delete it
    foreach ($event in $eventId) {
        Remove-MgUserEvent -UserId $userId.Id -EventId $event
        Write-Verbose "User: $($user) | Event: $($event) was removed! `n" -Verbose
    }
}
