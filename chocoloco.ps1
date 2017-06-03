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

<#
    googlechrome
    notepadplusplus
    adobereader
    firefox
x    7zip
    vlc
    ccleaner
    sysinternals
    filezilla
    putty
    procexp
x    curl
    pdfcreator
    malwarebytes
    atom
    virtualbox
    paint.net
    python2
    cutepdf
    itunes
    vim
    python
    windirstat
    irfanview
    flashplayerppapi #google chrome flash
    flashplayernpapi #firefox flash
    cdburnerxp
    puppet
    fiddler4
    greenshot
    vagrant
    baretail
    googleearthpro
    imagemagick.app
    docker
    ffmpeg
    crystaldiskinfo
    virtualclonedrive
    rdcman
x    f.lux
x    rufus
    handbrake
    vmwarevsphereclient
    kodi
#>


#Variables
$mainpkg = "greenshot"
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
        if((Test-Path $pkginstall) -eq $True) {
            Select-String -Path $pkginstall -Pattern $p -AllMatches | ForEach-Object { $chocohash.add($_.Matches.Groups[2].value,$_.matches.groups[3].value) }    
        }
        elseif($pkg -contains ".install") {
            Write-Host "This package does not possess a chocolateyinstall.ps1 file and it's a .install package; BAD BAD BAD!" -BackgroundColor Black -ForegroundColor Red
        }
        else {
            Write-Host "This package does not possess a chocolateyinstall.ps1 file; proceeding!" -BackgroundColor Black -ForegroundColor DarkGreen
        }
        
      

        #for all the files identified in the url string, search for file in lib and cache
        foreach($a in ($chocohash.keys | where {$_ -like "*url*" } ) ) {
            
            $file = ($chocohash.$a).split("/") -replace ".$" | `
                Select-Object -Last 1
            $file
            Get-ChildItem -Path $pkgcache -Filter $file* -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
            Get-ChildItem -Path $pkglib\tools -Filter $file* -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
            Get-ChildItem -Path $pkgnupkg\tools
        }

        #for all the files identified in the uln string, search for file in lib and cache
        foreach($a in ($chocohash.keys | where {$_ -like "*file*" } ) ) {
            
            $file = ($chocohash.$a).split("\") -replace ".$" | `
                Select-Object -Last 1
            
            #uln's can be either literal or implied. if literal locate the file and copy it. if implied then attempt to copy from lib and cache
            if ( Test-Path $file -IsValid ) {
                
                Get-ChildItem -Path $pkgcache -Filter $file* -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
                Get-ChildItem -Path $pkglib -Filter $file* -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
                Get-ChildItem -Path $pkgnupkg\tools
            }
            else {
                
                Get-ChildItem -Path $pkgcache -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
                Get-ChildItem -Path $pkglib\tools -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }

            }
        }


        #Begin to re-wrap the package for local distribution
                
        #There are ` marks throughout these replace strings, don't mess with them unless you understand substatution
        #The following is a REGEX stew, necessary for finding/replacing the myriad necessary flags to shape an internal package
        #Learn your REGEX and don't fiddle with nothing unless you know what's going on
        # REGEX is about pattern recognition and it's best you see my pattern before making your own

                         
            $regexhash = @(
                '(\$\S*[fF]ile\S*[ \t]+\=[ \t])(.*)'
                '(\$url32[ \t]+\=[ \t])(.*)'
                '(\$url64[ \t ]+\=[ \t])(.*)'
                '(\$url[ \t ]+\=[ \t])(.*)'
                '(\$checksum[ \t]+\=[ \t])(.*)'
                '(\$checksum32[ \t]+\=[ \t])(.*)'
                '(\$checksum64[ \t]+\=[ \t])(.*)'
                '(\$checksumtype[ \t]+\=[ \t])(.*)'
            )
                
            $regexcounter = 0
                
            DO 
            {
                if((Test-Path $pkginstall) -eq $True) {


                    write-host "Looking for the following patterns: $($regexhash[$regexcounter])" -ForegroundColor Magenta
                    
                    #if url is identified, then get the file name at the end of the url    
                
                    if(($regexhash[$regexcounter]) -match "url") {
                
                        $file = select-string -path $pkginstall -Pattern $regexhash[$regexcounter] | `
                            foreach {($_.Line).split("/") -replace ".$" | `
                            Select-Object -Last 1}
                
                        $file = "$pkgnupkg\tools\$file"
                        Write-Host "Matched: $file" -BackgroundColor DarkGreen
                        if((Test-Path $pkginstall) -eq $True) {
                                    (Get-Content $pkginstall) | `
                                        foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                                        set-content $pkginstall
                                }
                    }
                
                    #else if file is identified, get the file name at the end of the line
                    elseif(($regexhash[$regexcounter]) -match "[Ff]ile" ) {
                 
                            # $SOMETHINGfileSOMETHING = blah blah blah installer.exe
                            # this is NOT EASY! The key to success is reading about LAZY QUANTIFIERS
                                #http://www.rexegg.com/regex-quantifiers.html
                
                            $filehash = @()
                            foreach ($i in select-string -path $pkginstall -Pattern $regexhash[$regexcounter]) {

                                ($i.matches.value) -match '(\S*(\\\S*.exe.)) | (\S*.exe.)'
                                $file = $matches[0]
                                $filehash += $file

                            }

                            if ($filehash.Count -eq 1 ) {
                                $file = $filehash[0]
                                if((Test-Path $pkginstall) -eq $True) {
                                    (Get-Content $pkginstall) | `
                                        foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                                        set-content $pkginstall
                                }
                            
                            }
                            elseif ($filehash.count -eq 0 ) {
                                Write-Host "No exe pattern could be identified; proceed with caution" -BackgroundColor Black -ForegroundColor Green
                            }
                            
                            else {

                                foreach($i in $filehash) {

                                    (Get-Content $pkginstall) | `
                                        foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                                        set-content $pkginstall
                                }

                            }
                    
                    }
                
                    elseif(($regexhash[$regexcounter]) -match "checksum" ) {
                        $file = ''
                        if((Test-Path $pkginstall) -eq $True) {
                        (Get-Content $pkginstall) | `
                            foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                            set-content $pkginstall

                    }
                    else{
                        Write-Host "No pattern could be identified; proceeding with caution" -BackgroundColor Black -ForegroundColor Green
                    }
                
                    if((Test-Path $pkginstall) -eq $True) {
                        (Get-Content $pkginstall) | `
                            foreach {$_ -replace $regexhash[$regexcounter],"`${1} '$file'"} | `
                            set-content $pkginstall
                    }
                    else{
                        Write-Host "This package had no work to be done, it lacked a chocolateyinstall.ps1 file" -BackgroundColor Black -ForegroundColor Green
                    }
                
                }
                }
                else {Write-Host "This package had no work to be done, it lacked a chocolateyinstall.ps1 file" -BackgroundColor Black -ForegroundColor Green }
                
                    
                $regexcounter++

            }  while ($regexcounter -lt $regexhash.count)


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
#choco install $pkg -source 'C:\ProgramData\chocolatey\nupkg' -dv -y

