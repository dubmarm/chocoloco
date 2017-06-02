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
$mainpkg = "notepadplusplus"
$pkg = ""
$mainpkgcache = "C:\ProgramData\chocolatey\cache"
$mainpkglib = "C:\ProgramData\chocolatey\lib\$mainpkg"
$mainpkgcache = "C:\ProgramData\chocolatey\cache\$mainpkg"
$mainpkgnupkg = "C:\ProgramData\chocolatey\nupkg\$mainpkg"
$mainpkginstall = "$pkgnupkg\tools\chocolateyInstall.ps1"


#downloads typically go to C:\Users\USERNAME\AppData\Local\Temp
#this location sucks, changing location to C:\ProgramData\chocolatey\cache
$cacheLocation = choco config get cacheLocation
if (($cacheLocation[1]) -ne "C:\ProgramData\chocolatey\cache") {
    Write-Host "Setting cacheLocation to 'C:\ProgramData\chocolatey\cache'" -foreground Yellow
    if ((Test-Path C:\ProgramData\chocolatey\cache) -eq $False) {
        Write-Host "Cache directory does not exist; creating cache directory" -foreground Yellow
        mkdir C:\ProgramData\chocolatey\cache
    }
    choco config set cacheLocation $mainpkgcache
}
else {
    Write-Host "cacheLocation is already set to 'C:\ProgramData\chocolatey\cache'; moving on" -foreground Yellow
}


#install the package traditionally
choco install $mainpkg -y


#build an array of all dependencies
$pkgarray = @($mainpkg)

[xml]$nuspec = (Get-Content "$mainpkglib\*.nuspec")


if ($nuspec.package.metadata.dependencies.dependency) {
    Write-Host "We found some dependencies; standby"
    
    foreach($i in ($nuspec.package.metadata.dependencies.dependency)) {
        
        if ($i.id -ne "chocolatey-core.extension") {
            $pkgarray += $i.id
        }
    }

    $pkg = ($nuspec.package.metadata.dependencies.dependency).id
}

Write-Host "There are $($pkgarray.count) item(s) to package"
$pkgarray


#for each package listed in pkgarray
#find any install files that may be stored in lib or cache
$counter = 0 
DO 
{
    Write-host "Working with $pkgarray["$counter"]" -ForegroundColor Yellow
    
    $pkg = $pkgarray["$counter"]
    
    $pkgcache = "C:\ProgramData\chocolatey\cache"
    $pkglib = "C:\ProgramData\chocolatey\lib\$pkg"
    $pkgcache = "C:\ProgramData\chocolatey\cache\$pkg"
    $pkgnupkg = "C:\ProgramData\chocolatey\nupkg\$pkg"
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
        #find only variable assignments '$var = '
        #build a table of variables listed so that we may call upon them
        

        #create hashtable of chocolateyinstall.ps1 variables
        $p = '(?<key>^\$([a-zA-Z]|\d)*[\s | \t]+\=[\s | \t]+)(?<value>.*)'
        $chocohash = @{}
        Select-String -Path $pkginstall -Pattern $p -AllMatches | ForEach-Object { $chocohash.add($_.Matches.Groups[2].value,$_.matches.groups[3].value) }
      

        #for all the files identified in the url string, search for file in lib and cache
        foreach($a in ($chocohash.keys | where {$_ -like "*url*" } ) ) {
            
            $file = ($chocohash.$a).split("/") -replace ".$" | `
                Select-Object -Last 1
            $file
            Get-ChildItem -Path $pkgcache -Filter $file -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools}
            Get-ChildItem -Path $pkglib -Filter $file -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools}
            Get-ChildItem -Path $pkgnupkg\tools
        }

        #for all the files identified in the uln string, search for file in lib and cache
        foreach($a in ($chocohash.keys | where {$_ -like "*file*" } ) ) {
            
            $file = ($chocohash.$a).split("\") -replace ".$" | `
                Select-Object -Last 1
            
            Get-ChildItem -Path $pkgcache -Filter $file -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools}
            Get-ChildItem -Path $pkglib -Filter $file -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools}
            Get-ChildItem -Path $pkgnupkg\tools
        }


        #Begin to re-wrap the package for local distribution

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
                
            #ex. notpadplusplus.commandline
            Write-Host "Matched: $zipmatches.Pattern"
                
            $find = "Install-ChocolateyZipPackage `@packageArgs"
            $replace = "`$toolsDir   = `"`$(Split-Path -parent `$MyInvocation.MyCommand.Definition)`"`n Install-ChocolateyZipPackage `'$pkg`' `"`$toolsdir\$file`" `"`$toolsdir`" "
                
            (Get-Content $pkginstall) | `
            foreach {$_.replace($find,$replace)} | `
            out-file $pkginstall
            
        }
            
        else {
            Write-Host "Stopping: Uncertain how to handle these instructions"
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
