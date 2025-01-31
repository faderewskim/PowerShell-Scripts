<#
DESCRIPTION: 
PL.
Skrypt dodaje użytkowników do określonej grupy Active Directory na podstawie danych importowanych z pliku CSV. 
Plik musi zawierać kolumnę i dane o nazwie `SamAccountName`. Skrypt sprawdza, czy użytkownik już należy do grupy, aby uniknąć duplikacji.
Jednocześnie usuwa, jeżeli użytkownik nie znajduje się na liście.

ENG.
The script adds users to a specified Active Directory group based on data imported from a CSV file. 
The file must contain a column and datas named `SamAccountName`. The script checks if the user is already a member of the group to prevent duplication.
At the same time, it removes if the user is not on the list.


Name/Surname:           Mateusz Faderewski
Profession:             System Engineer
Date:                   26-04-2024
Version:                v1.0
What has been added?    1. Empty
#>


param (   
    [Parameter()]
    [string] $ADGroupName = "<PUT_AD_GROUP_NAME>",

    [Parameter()]
    [string] $fileName = "<PUT_FILE_NAME>",

    [Parameter()]
    [array] $importData = (Import-Csv -Path .\$fileName.csv -Delimiter ",")     
)


$ADGroupMember = Get-ADGroupMember -Identity $ADGroupName -Recursive | 
                    Sort SamAccountName | 
                        Select -ExpandProperty SamAccountName


$totalItems = $importData.Count
$processedItems = 0

foreach ($row in $importData) {
    
    $user = $row.SamAccountName
    
    if($ADGroupMember -contains $user) {        
        Write-Host "User: $($user) is already a member of the group : $($ADGroupName)" -f Yellow
        Continue;      
    }
    elseif($ADGroupMember -notcontains $user) {
        Write-Verbose "User: $($user) was removed from the group : $($ADGroupName)" -Verbose
        Remove-ADGroupMember -Identity $ADGroupName -Members $user -Confirm:$false
    }
    else {
        Write-Verbose "User: $($user) was added to the group : $($ADGroupName)" -Verbose
        Add-ADGroupMember -Identity $ADGroupName -Members $user -Confirm:$false   
    } 
    
    $processedItems++
    $progress = $processedItems / $totalItems * 100
    $status   = "Processing $processedItems of $totalItems elements..."
    Write-Progress -Activity "Processing..." -Status $status -PercentComplete $progress
}
