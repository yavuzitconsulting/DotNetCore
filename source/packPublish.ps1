$backupextension = ".psbak"
$yitcpostfix = Read-Host "Please enter the yitc-package version, just the number, no dots"
$yitcversion = '.' + $yitcpostfix + '-yitc';
Write-Host 'YITC version will be: ' + $yitcversion
Write-Host 'Please check, then continue to enter apikey.'
PAUSE
$buildprops = 'Directory.Build.props'
Write-Host 'Backup file: ' + $buildprops + ' to ' + $buildprops + $backupextension
Copy-Item $buildprops -Destination ($buildprops + $backupextension)
Write-Host 'Updating version'
[xml]$xmlfile = Get-Content $buildprops

$originalVersion = $xmlfile.Project.PropertyGroup.Version
$newVersion = $originalVersion + $yitcversion
Write-Host 'oVER: ' $originalVersion
Write-Host 'nVER: ' $newVersion



$originalURL = $xmlfile.Project.PropertyGroup.RepositoryUrl
$newURL = 'https://github.com/yavuzitconsulting/DotNetCore'
Write-Host 'oURL: ' $originalURL
Write-Host 'nURL: ' $newURL

$xmlfile.Project.PropertyGroup.Version = $newVersion
$xmlfile.Project.PropertyGroup.RepositoryUrl = $newURL

$xmlfile.Save($buildprops)

Write-Host 'Saved'
PAUSE


$apikey = Read-Host "Please enter nuget api key"



Write-Host 'Changing Package IDs to YITC.[PID]'
#RENAME ORIGINAL PACKAGE TO YITC.OPCKG
$csprojs = (Get-ChildItem -Path * -Filter *.csproj -Recurse -ErrorAction SilentlyContinue -Force).FullName
Write-Host $csprojs
foreach ($proj in $csprojs)
{

Write-Host 'Backup file: ' + $proj + ' to ' + $proj + $backupextension
Copy-Item $proj -Destination ($proj + $backupextension)

	[xml]$xmlfile = Get-Content $proj
$originalPackageId = $xmlfile.Project.PropertyGroup.PackageId
$newPackageId = 'YITC.' + $originalPackageId
Write-Host 'oPID: ' originalPackageId
Write-Host 'nPID: ' $newPackageId

$originalDescription = $xmlfile.Project.PropertyGroup.Description
$newDescription = $originalDescription + ' forked by YITC'
Write-Host 'oDES: ' $originalDescription
Write-Host 'nDES: ' $newDescription

$originalTitle = $xmlfile.Project.PropertyGroup.Title
$newTitle = $originalTitle + ' forked by YITC'
Write-Host 'oTIT: ' $originalTitle
Write-Host 'nTIT: ' $newTitle

$xmlfile.Project.PropertyGroup.PackageId = $newPackageId
$xmlfile.Project.PropertyGroup.Title = $newTitle
$xmlfile.Project.PropertyGroup.Description = $newDescription

$xmlfile.Save($proj)
Write-Host 'Saved'
}





Write-Host 'PACKING'
#PACK
dotnet pack -o packages

#PUBLISH


$files=get-childitem -Path ./packages | where {$_.Name -like "*.nupkg" -and $_.Name -notlike "*symbols*"}

foreach($file in $files) {
  Write-Host "Pushing " + $file
  nuget push -Source "https://api.nuget.org/v3/index.json" -ApiKey $apikey $file.fullname
	
}





Write-Host 'CHANGE BACK TO ORIGINAL PACKAGE IDs'

#RENAME PACKAGE BACK, to make merges easier when original changes
$csprojs = (Get-ChildItem -Path * -Filter *.csproj -Recurse -ErrorAction SilentlyContinue -Force).FullName
Write-Host $csprojs
foreach ($proj in $csprojs)
{
Write-Host 'Back to original file: ' + $proj	
Remove-Item $proj
Rename-Item -Path ($proj + $backupextension) -NewName $proj

}

####################

Write-Host 'Back to original version'

Remove-Item $buildprops
Rename-Item -Path ($buildprops + $backupextension) -NewName $buildprops

Write-Host 'clean-up packages'

$files=get-childitem -Path ./packages 

foreach($file in $files) {
  Write-Host "Deleting " + $file
  
	Remove-Item $file.fullname
	
}



Write-Host 'Done'

PAUSE

