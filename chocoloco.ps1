#REFERENCE SITE: https://chocolatey.org/docs/how-to-recompile-packages

<#
#install-chocolateypackager : the term XXX is not recognized as the name of a cmdlet
	#- C:\ProgramData\chocolatey\helpers
	#- import-module .\chocolateyInstaller.psm1
	#- import-modeul .\chocolateyProfile.psm1
# C:\ProgramData\chocolatey\helpers
# import-module .\chocolateyInstaller.psm1
# import-module .\chocolateyProfile.psm1
#>
import-module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
import-module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1

#Variables
$pkg = "notepadplusplus.commandline"
$pkgcache = "C:\ProgramData\chocolatey\cache"
$pkglib = "C:\ProgramData\chocolatey\lib\$pkg"
$pkgcache = "C:\ProgramData\chocolatey\cache\$pkg"
$pkginstall = "$pkgnupkg\tools\chocolateyInstall.ps1"


#downloads typically go to C:\Users\USERNAME\AppData\Local\Temp
#this location sucks, changing location to C:\ProgramData\chocolatey\cache
$cacheLocation = choco config get cacheLocation
if (($cacheLocation[1]) -ne "C:\ProgramData\chocolatey\cache") {
    Write-Host "Setting cacheLocation to 'C:\ProgramData\chocolatey\cache'" -foreground Yellow
    if ((Test-Path C:\ProgramData\chocolatey\cache) -eq $False) {
        Write-Host "Cache directory does not exist; creating cache directory" -foreground Yellow
        mkdir C:\ProgramData\chocolatey\cache
    }
    choco config set cacheLocation $pkgcache
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
choco install $pkg -y


##does the package contain a dependancy?
#build an array of all dependencies
[xml]$nuspec = Get-Content "$pkglib\*nuspec"
Write-Host "We found some dependencies; $nuspec.package.metadata.dependencies.dependency"
$pkgarray = @($pkg)
foreach($i in ($nuspec.package.metadata.dependencies.dependency)) {
    #do the repackaging
    $pkgarray += $i.id

}
$pkgarray
Write-Host "There are $pkgarray.count items to package"


$counter = 0 
DO 
{
    Write-host "Working with $pkgarray["$counter"]" -ForegroundColor Yellow
    $pkg = $pkgarray["$counter"]
    $pkgcache = "C:\ProgramData\chocolatey\cache"
    $pkglib = "C:\ProgramData\chocolatey\lib\$pkg"
    $pkgcache = "C:\ProgramData\chocolatey\cache\$pkg"
    $pkginstall = "$pkgnupkg\tools\chocolateyInstall.ps1"

        #unzip the nupkg file
        cp "$pkglib\*.nupkg" "$pkglib\$pkg.zip"
        if(! (Test-Path $pkgnupkg)) {
            New-Item -ItemType Directory -Force -Path $pkgnupkg
        }
        expand-archive -path "$pkglib\$pkg.zip" -destinationpath $pkgnupkg -force

        #remove un-needed, soon to be recreated elements
        remove-item -Recurse "$pkgnupkg\_rels", "$pkgnupkg\package"
        remove-item -LiteralPath [Content_Types].xml

        #search the cache for any necessary files
        #get the content of chocolateyinstall.ps1
        #find the exe files listed in url
        #search for the exe files in cache

        #get the content of the file
        #find only items that contain an '='
        #build a table of variables listed so that we may call upon them
        $test = Get-Content -path $pkginstall | Where-Object {$_.Contains("=")}
        if (($test).count -gt 0) {
            Write-Host "Test is TRUE"
            $chocohash = Get-Content -path $pkginstall | Where-Object {$_.Contains("=")} | ConvertFrom-StringData

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

            #Lookup file in lib
            #copy it to package directory
            if((Get-ChildItem $pkglib -Include *.msi,*.exe,*.ignore -Recurse).count -gt 0) {
                foreach($i in (Get-ChildItem $pkglib -Include *.msi,*.exe,*.ignore -Recurse)) {
                    Write-Host "Copying $i from $i.fullname" -Foregroundcolor "Yellow"
                    cp $i.fullname "$pkgnupkg\tools"
                }
            }
            else {Write-Host "No files found in lib/root package directory; continuing" -ForegroundColor "Yellow"}

            #Lookup file in cache
            #copy it to package directory
            foreach ($i in (Get-ChildItem $pkgcache -Recurse | where {! $_.PSIsContainer})) {
                Write-Host "Copying $i to $pkgnupkg\tools" -Foregroundcolor "Yellow"
                cp $i.fullname "$pkgnupkg\tools"
            }

            #Begin to re-wrap the package for local distribution
            <#
            inspect chocolateyInstall.ps1
             if web url dl, find and replace with new line
             if exe ,  find and replace with new line
             if zip,  find and replace with new line
            #>
            $webmatches = select-string -path $pkginstall -pattern "Install-ChocolateyPackage" -AllMatches
            $exematches = select-string -path $pkginstall -pattern "Install-ChocolateyInstallPackage" -AllMatches
            $zipmatches = select-string -path $pkginstall -pattern "Install-ChocolateyZipPackage" -AllMatches


            #There are ` marks throughout these replace strings, don't mess with them unless you understand substatution
            #The following is a REGEX stew, necessary for finding/replacing the myriad necessary flags to shape an internal package
            #Learn your REGEX and don't fiddle with ' ` " unless you know what's up

            if ($webmatches.matches.count -gt 0) {
                #ex. notpadplusplus
                Write-Host "Matched: $webmatches.Pattern"
                         
                $regexhash = @(
                    '(\$url32[ \t]+\=\s)(.*)'
                    '(\$url64[ \t ]+\=\s)(.*)'
                    '(\$checksum32[ \t]+\=\s)(.*)'
                    '(\$checksum64[ \t]+\=\s)(.*)'
                )
                
                $regexcounter = 0
                
                DO 
                {
                    write-host $regexhash[$regexcounter]
                    
                    
                    if(($regexhash[$regexcounter]) -match "url") {
                        $file = select-string -path $pkginstall -Pattern $regexhash[$regexcounter] | `
                            foreach {($_.Line).split("/") -replace ".$" | `
                            Select-Object -Last 1}
                        $file = "$pkgnupkg/tools/$file"

                    }
                    else{
                        $file = ''
                    }
                

                    (Get-Content $pkginstall) | `
                        foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                        set-content $pkginstall
                        #out-file $pkginstall
                    
                    $regexcounter++

                 }  while ($regexcounter -lt $regexhash.count)
                
            }


            elseif ($exematches.matches.count -gt 0) {
                #ex. 7zip
                Write-Host "Matched: $exematches.Pattern; nothing to do"
                
                
            }
            
            elseif ($zipmatches.Matches.Count -gt 0) {
                #ex. notpadplusplus.commandline
                Write-Host "Matched: $zipmatches.Pattern"
                $find = "Install-ChocolateyZipPackage `@packageArgs"
                $replace = "`$toolsDir   = `"`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)`"`n Install-ChocolateyZipPackage `'$pkg`' `"`$toolsdir\$file`" `"`$toolsdir`" "
                (Get-Content $pkginstall) | foreach {$_.replace($find,$replace)} | out-file $pkginstall
            }
            
            else {
                Write-Host "Stopping: Uncertain how to handle these instructions"
            }



                }
        else {
            Write-Host "No further file searching required; this is a virtual package"
        }



        #package the whole thing up!
        choco pack "$pkgnupkg\$pkg.nuspec" --out $pkgnupkg




    $counter++
} while ($counter -ne $pkgarray.count)



#choco uninstall $pkg -y


#when installing you need to specify the source of the nupkg file AS WELL as any directory to look for dependencies
#notepadplusplus has .install nupkg in C:\ProgramData\chocolatey\nupkg so that I add that
#I can also specify ProgramData\chocolatey\lib because that's another function potential
#I can also look into add nupkg as a source but for now I'll manuall specify it
#use single quotes and semi colons with the source field

#choco install $pkg -source '$pkgnupkg;C:\ProgramData\chocolatey\nupkg' -dv -y
