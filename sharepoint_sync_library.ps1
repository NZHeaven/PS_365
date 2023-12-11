<#  
This PowerShell script is designed to synchronize files between a SharePoint document library and a local folder on a computer. 
The function Sync-Files takes two parameters: $folderUrl, which represents the SharePoint folder URL, and $localFolderPath, 
which is the local directory where the files will be synchronized. It will only synchronize files that are newer or do not exist locally.
Remeber to change the $siteUrl, $rootFolderUrl and localFolderPath variables to match your environment.
#>
function Sync-Library($folderUrl, $localFolderPath) {

    $folder = Get-PnPFolder -Url $folderUrl -Includes Files,Folders

    # Download files in the current folder
    foreach ($file in $folder.Files) {
        $fileName = $file.Name
        $fileUrl = $file.ServerRelativeUrl
        $lastModified = ($file.TimeLastModified).AddHours(13) # Add 13 hours to convert from UTC to NZST

        $localFilePath = Join-Path -Path $localFolderPath -ChildPath $fileName
        
        # Check if the file exists locally or if SharePoint version is newer
        if (-not (Test-Path -Path $localFilePath) -or (Get-Item $localFilePath).LastWriteTime -lt $lastModified) {
            # Download the file from SharePoint
            Write-Host "Downloading: $fileName" -ForegroundColor Yellow
            Get-PnPFile -Url $fileUrl -Path $localFolderPath -FileName $fileName -AsFile -Force
        } else {
            Write-Host "File '$fileName' already up to date." -ForegroundColor Green
        }
    }

    # Recursively call function for each subfolder
    foreach ($subFolder in $folder.Folders) {
        $subFolderUrl = $subFolder.ServerRelativeUrl
        $subLocalFolderPath = Join-Path -Path $localFolderPath -ChildPath $subFolder.Name

        if (-not (Test-Path -Path $subLocalFolderPath -PathType Container)) {
            New-Item -ItemType Directory -Path $subLocalFolderPath | Out-Null
        }

        Download-Files -folderUrl $subFolderUrl -localFolderPath $subLocalFolderPath
    }
}

# Connect to SharePoint site
$siteUrl = "https://<url>.sharepoint.com/sites/<site>"
$localFolderPath = "C:\<path to folder>"
$rootFolderUrl = "/sites/<site>/<Folder>"

# Connect to SharePoint
Connect-PnPOnline -Url $siteUrl -Interactive

# Start downloading files and folders
Sync-Library -folderUrl $rootFolderUrl -localFolderPath $localFolderPath