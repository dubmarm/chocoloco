#REFERENCE SITE: https://chocolatey.org/docs/how-to-recompile-packages


<#

#install-chocolateypackager : the term XXX is not recognized as the name of a cmdlet
	#- C:\ProgramData\chocolatey\helpers
	#- import-module .\chocolateyInstaller.psm1
	#- import-modeul .\chocolateyProfile.psm1
# C:\ProgramData\chocolatey\helpers
# import-module .\chocolateyInstaller.psm1
# import-modeul .\chocolateyProfile.psm1
#>
import-module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
import-module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1


#downloads typically go to C:\Users\USERNAME\AppData\Local\Temp
#this location sucks, changing location to C:\ProgramData\chocolatey\cache
$cacheLocation = choco config get cacheLocation
if (($cacheLocation[1]) -ne "C:\ProgramData\chocolatey\cache") {
    Write-Host "Setting cacheLocation to 'C:\ProgramData\chocolatey\cache'" -foreground Yellow
    if ((Test-Path C:\ProgramData\chocolatey\cache) -eq $False) {
        Write-Host "Cache directory does not exist; creating cache directory" -foreground Yellow
        mkdir C:\ProgramData\chocolatey\cache
    }
    choco config set cacheLocation C:\Programdata\chocolatey\cache
}
else {
    Write-Host "cacheLocation is already set to 'C:\ProgramData\chocolatey\cache'; moving on" -foreground Yellow
}



#The following block of bad code is to see if the package being installed is standalone or if it has dependancies
#if a package has dependancies than the main package "ex. git" is a metapackage (a pointer) to all the other mini packages needed
#the mini packages will come with a suffix of .install or .commandline
#if a package has a .install then we want to focus on that package because it contains the installer files (exe or msi)
#which are needed down the road when we need to repackage the package or SCCM/Puppet/Chef etc.
#otherwise, if there is no .install then we need to focus on the base directory for our files

#Define the packages to be install and manipulated
$pkg = "notepadplusplus"
choco install $pkg -y


#does the package contain a .install suffix?
$metatest = "C:\ProgramData\chocolatey\lib\$pkg.install"
$basetest = "C:\ProgramData\chocolatey\lib\$pkg"

if ((Test-Path $metatest) -eq $True) {
    Write-Host "Found the .install virtual package, proceeding"
    $pkghome = $metatest
    cd $pkghome
}
elseif ((Test-Path $basetest) -eq $True) {
    Write-Host "Could not find .install metapackages, working from base directory"
    $pkghome = $basetest
    cd $pkghome
}
else {
    Write-Host "Not sure which directory is the package directory; stopping"
    end
}

#unzip the nupkg file
cp $pkghome\*.nupkg $pkghome\$pkg.zip
expand-archive -path "$pkghome\$pkg.zip" -destinationpath "$pkghome\package" -force

#remove un-needed, soon to be recreated elements
cd "$pkghome\package"
remove-item -Recurse _rels, package
remove-item -LiteralPath [Content_Types].xml

#search the cache for any necessary files
#get the content of chocolateyinstall.ps1
#find the exe files listed in url
#search for the exe files in cache

#get the content of the file
#find only items that contain an '='
#build a table of variables listed so that we may call upon them
$chocohash = Get-Content -path .\tools\chocolateyInstall.ps1 | Where-Object {$_.Contains("=")} | ConvertFrom-StringData

#select which url to use 32 vs 64
#parse the html for the exe name
#break up string by /
#replace the last character with nothing (its a left over ', from the 'https://BLAH'
#select the last parsing of /
#that's the file
if ((gwmi win32_operatingsystem | select osarchitecture).osarchitecture -eq "64-bit") {
    Write-Host "64-bit OS Architecture" -ForegroundColor "Yellow"
    $file = ($chocohash."`$url64").split("/") -replace ".$"| Select-Object -Last 1
}
else {
    Write-Host "32-bit OS Architecture" -ForegroundColor "Yellow"
    $file = ($chocohash."`$url32").split("/") | Select-Object -Last 1
}

#Lookup file in cache
#copy it to package directory
$file = Get-ChildItem -Path C:\ProgramData\chocolatey\cache -Filter $file -Recurse
$folder = Get-ChildItem -Path $file64.DirectoryName
foreach ($f in $folder) {
    cp $f.fullname .\tools
}

#Begin to re-wrap the package for local distribution
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

<#
inspect chocolateyInstall.ps1
 if web url dl, find and replace with new line
 if exe ,  find and replace with new line
 if zip,  find and replace with new line
#>
$webmatches = select-string -path .\tools\chocolateyInstall.ps1 -pattern "Install-ChocolateyPackage" -AllMatches
$exematches = select-string -path .\tools\chocolateyInstall.ps1 -pattern "Install-ChocolateyInstallPackage" -AllMatches
$zipmatches = select-string -path .\tools\chocolateyInstall.ps1 -pattern "Install-ChocolateyZipPackage" -AllMatches

if ($webmatches.matches.count -gt 0) {
    #ex. notpadplusplus
    Write-Host "Matched: $webmatches.Pattern"
    Install-ChocolateyPackage $pkg $url "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
}
elseif ($exematches.matches.count -gt 0) {
    #ex. 7zip
    Write-Host "Matched: $exematches.Pattern"
    Install-ChocolateyInstallPackage $pkg $url "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
}
elseif ($zipmatches.Matches.Count -gt 0) {
    #ex. notpadplusplus.commandline
    Write-Host "Matched: $zipmatches.Pattern"
    Install-ChocolateyZipPackage $pkg $url "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
}
else {
    Write-Host "Stopping: Uncertain how to handle these instructions"
}



