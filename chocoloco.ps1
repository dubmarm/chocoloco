#REFERENCE SITE: https://chocolatey.org/docs/how-to-recompile-packages
<#
x    googlechrome - url and url64bin in pkgargs
x    notepadplusplus - url and url64bin in pkgargs
x    adobereader
x    -----adobereader-update (adobereader must be installed first or else adobe throws a 1643 error)
x    firefox
x    7zip
x    vlc
    ccleaner
x    sysinternals
x    filezilla
?    putty - putty portable is throwing errors, possible $var leak
x    procexp
x    curl
    pdfcreator
    malwarebytes
x    atom
?    virtualbox - Install-ChocolateyPackage with a url that did not parse
?    paint.net - .Net4.61 - choco does not like the validexitcodes (not in key=value format) : line 294 : $pkghash += convertfrom-stringdata -stringdata $pkgargs[$pkgcounter] Install was still a success. Too lazy atm
                    - $pkgargs is a regex of chocolateyinstall.ps1. It's looking for blah = .... and it's doing it with a single line approach. Have to write a IF blah = ... then do normal, IF blah = @ (... then do multiline until )
    python2
    cutepdf
x    itunes
x    vim
    python
x    windirstat
x    irfanview - added autohotkey.portable chocolatey-uninstall.extension to line 227 : if ($i.id -ne "chocolatey-core.extension","autohotkey.portable","chocolatey-uninstall.extension") {
?    flashplayerppapi #google chrome flash error 1603
?    flashplayernpapi #firefox flash error 1603
?    cdburnerxp - error 1603
    puppet
x    fiddler4
?    greenshot - might need cache cleared and lib and nupkg
    vagrant
x    baretail
    googleearthpro
?    imagemagick.app
    docker
x    ffmpeg
x    crystaldiskinfo
    virtualclonedrive
    rdcman
    f.lux
    rufus
    handbrake
    vmwarevsphereclient
    kodi
    youtube-dl

choco install $pkg -source 'C:\ProgramData\chocolatey\nupkg' -dv -Y -force
#>

import-module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
import-module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1

#Variables
$mainhash = @(
"putty"
#"virtualbox"
#"paint.net"
#"flashplayerppapi"
#"flashplayernpapi"
#"cdburnerxp"
#"fiddler4"
#"greenshot"
#"imagemagick.app"
)

foreach($i in $mainhash){

$mainpkg = $i
$mainpkglib = "C:\ProgramData\chocolatey\lib\$mainpkg"
$mainpkgcache = "C:\ProgramData\chocolatey\cache\$mainpkg"

function Get-HttpExe($key, $file) {            
    Write-Host "ULN exists in http(s) address, updating outerhash"
    
    #store the finding in hashtoalter
    $hashtoalter.add($key,("$toolsdir\" + $file))

    Get-Install "$file"
}

function Get-FileExe($key, $file) {

    Write-Host "FILE key exists, searching for the file in cache and lib"
                    
    Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse
                    
    #store the finding in hashtoalter
    #$hashtoalter.add($key,("$toolsdir\" + $file))

    Get-Install "$file"

}

function Get-FileZip($key, $file) {
    Write-Host "ULN missing, searching for .zip | .7z"
    #find file, file will be the .ignore
    $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter '*.zip*', '*.7z*' -Recurse).Name
    
    #store the finding in hashtoalter
    #$hashtoalter.add($key,("$toolsdir\" + $file))

    Get-Install "$file"
}

function Get-Ignore($key) {
    
    #find file, file will be the .ignore
    (Get-ChildItem -Path $pkgcache,$pkglib -Filter '*.ignore' -Recurse) | foreach-object `
    {
            
            $file = $_ -replace '.ignore',''
            Write-Host "ULN is missing in http(s) address, searching for .ignore instead"

            #store the finding in hashtoalter
            $hashtoalter.add($key,("$toolsdir\" + $file))

            Get-Install "$file"
    }

}

function Get-Install ($file) {
    Write-Host "File is: $file"
    Get-ChildItem -Path $pkgcache -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
    Get-ChildItem -Path $pkglib\tools -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName $pkgnupkg\tools -Force }
    Get-ChildItem -Path $pkgnupkg\tools -Filter "*$file*"
}

#f*** windows and it's stupid PS regex, .Net regex B.S.
#.replace () = string but -replace = regex bull crap
# and don't get me started on interpolation with variables
# omg the following lines of code can be done with python is 3 lines!
function Set-HashToAlter($hashtoalter, $pkginstall) {
        
        $hashtoalter
                
        foreach ($i in $hashtoalter.GetEnumerator()) {
                
            $i
            $a = $i.value
            $i = $i.key
            $str = (get-content $pkginstall -RAW)




            #if the variable starts with $, then we need to escape it in the regex
            
            if($i -match "^\$")
            {
                Write-Host "$i has a pre-pended $"
                #if last character of $str is { then search multiline for the next $var
                if($str -match "(?mi)(^\$i)([.| \t]+=[ \t])(.*{)")
                {
                    Write-Host "$i is a multiline value replace" -ForegroundColor Yellow
                    ($str) -replace "(?smi)(^\$i)([ t]=[ \t])(.*?)(^\$)","`${1}`${2}""$a""`n$" | set-content $pkginstall
                }

                else
                {
                    write-host "$i is a single line replace" -ForegroundColor Yellow
                    ($str) -replace "(\$i)([.| \t]+=[ \t]).*","`${1}`${2}""$a"""  | set-content $pkginstall 
                }
            }
            #else it's a string
            else
            {
                Write-Host "$i does not contain a pre-pended $" -ForegroundColor Yellow
                #if($str -match "(?mi)(^$i)([.| \t]+=[ \t])(.*{)")
                #{
                #    Write-Host "$i is a multiline value replace" -ForegroundColor Yellow
                #    ($str) -replace "(?smi)(^$i)([ t]=[ \t])(.*?)(^\$)","`${1}`${2}""$a""`n$" | set-content $pkginstall
                #}

                #else
                #{
                    write-host "$i is a single line replace" -ForegroundColor Yellow
                    ($str) -replace "($i)([.| \t]+=[ \t]).*","`${1}`${2}""$a"""  | set-content $pkginstall 
                #}  
                
            }
        }

    Remove-Checksum
}

function Remove-Checksum() {
    
 #    '(.+file.+=[ \t])(.*)'
 #    '(.+url.+=[ \t])(.*)'
 #    '(.+checksum.+=[ \t])(.*)'

       (Get-Content $pkginstall -Raw) | `
       foreach {$_ -replace '(.+checksum.+=[ \t])(.*)',"`${1}''"} | `
       foreach {$_ -replace '(-checksum.*?[ \t].*?[\s]+)',""} | `
       set-content $pkginstall 
}


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
else { Write-Host "cacheLocation is already set to 'C:\ProgramData\chocolatey\cache'; moving on" -foreground Yellow }

#install the package traditionally
choco install $mainpkg -y

#build an array of all dependencies
$pkgarray = @($mainpkg)

[xml]$nuspec = (Get-Content "$mainpkglib\*.nuspec")
if ($nuspec.package.metadata.dependencies.dependency) {
    Write-Host "We found some dependencies; standby"
    
    foreach($i in ($nuspec.package.metadata.dependencies.dependency)) {
        
        if ($i.id -eq "chocolatey-core.extension" -or $i.id -eq 'autohotkey.portable' -or $i.id -eq 'chocolatey-uninstall.extension') {
            Write-Host "Not adding the following dependency to list: " $i.id -ForegroundColor Magenta
        }
        else {$pkgarray += $i.id}
    }

    $pkg = ($nuspec.package.metadata.dependencies.dependency).id
}

Write-Host "There are $($pkgarray.count) item(s) to package"
$pkgarray

#for each package listed in pkgarray
#find any install files that may be stored in lib or cache
$counter = 0

do 
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

    if(Test-Path $pkginstall){
            #parser array setup for PackageArgs @{} within file
            $content = get-content -Path $pkginstall | Out-String
            $pkgargs = ([regex] '(?is)(?<=\$packageArgs[ \t]+\=[ \t]@{).*?(?=})').matches($content)
            $pkgargs = $pkgargs.value -split "`r`n"
            $pkgargs = $pkgargs -replace '\\','\\'

            $pkghash = @{}
            $pkgcounter = 0
            $pkgcount = ($pkgargs.count)

            #parser array setup for $var definitions within file
            $content = get-content -Path $pkginstall | Out-string
            $outervar = [regex]::Matches($content,'(\$\S*[ \t]+\=[ \t])(.*)')
            $outervar = $outervar.value -split "`r`n"
            $outervar = $outervar -replace '\\','\\'
            $outerhash = @{}
            $outercounter = 0
    
            #alter array used as final reference array for all changes to be made to chocolateyinstall.ps1
            $hashtoalter = @{}

                do{
                    $pkghash += ConvertFrom-StringData -StringData $pkgargs[$pkgcounter]
                    $pkgcounter++
                } while ($pkgcounter -ne $pkgcount)


                do {
                    $outerhash += ConvertFrom-StringData -StringData $outervar[$outercounter]
                    $outercounter++
                } while ($outercounter -ne $outervar.count)
            
            if($outerhash.count -gt 0 -or $pkghash.count -gt 0){
                #assign the value of toolsdir
                if ((select-string $pkginstall -pattern '\$toolspath =').count -gt 0) 
                                        {
                    $toolsdir = '$toolspath'
                }
                elseif ((select-string $pkginstall -pattern '\$toolsdir =').count -gt 0)
                                        {
                    $toolsdir = '$toolsdir'
                }
                else
                {
                    #set $toolsdir variable for script, as well as prepend $header string to chocolateyinstall.ps1 since it lacks $toolsdir definition
                    $toolsdir = '$toolsdir'
                    $header = '$toolsdir = Split-Path $MyInvocation.MyCommand.Definition' 

                    $filecontent = (Get-Content $pkginstall)
                    $filecontent[0] = "{0}`r`n{1}" -f $header, $filecontent[0]
                    $filecontent | set-content "$pkginstall"

                }


                #if $pkginstall contains Install-ChocolateyPackage, then it's a url reachout for an exe or msi. We need this file
                if (( (get-content $pkginstall) | %{$_ -match 'Install-ChocolateyPackage' -or $_ -match 'Get-ChocolateyWebFile' -or $_ -match 'Install-ChocolateyZipPackage'}) -contains $true) {
            
                    $outerhash.keys | where {$_ -match 'url'} | foreach {
                
                        $key = $_ -replace "`n"
            
                        #if the url.key has a http(s) string in it's value, then perform the following logic to find the exe
                        if($outerhash.get_item($key) -match 'http://' -or $outerhash.get_item($key) -match 'https://') {
                        
                            $file = ($outerhash.get_item($key) -split "/" -replace ".$" | Select-Object -Last 1)
                            Write-Host "Working with $key and $file"
                            #if the value of key.url is a uln, then get me the last value of / delimiter, see if it exists
                            if((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name){ Get-HttpExe $key $file }

                            else { Get-Ignore $key }
            
                        }
                        else { Get-Ignore $key}
                    }
                    $pkghash.keys | where {$_ -match 'url'} | foreach {
            
                        $key = $_ -replace "`n"
                
                        #if the url.key has a http(s) string in it's value, then perform the following logic to find the exe
                        if($pkghash.get_item($key) -match 'http://' -or $pkghash.get_item($key) -match 'https://') {
            
                            $file = ($pkghash.get_item($key) -split "/" -replace ".$" | Select-Object -Last 1)

                            #if the value of key.url is a uln, then get me the last value of / delimiter, see if it exists
                            if((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name){ Get-HttpExe $key $file }

                            else { Get-Ignore $key }
            
                        }
                        else { Get-Ignore $key }
                    }
                }  
    
                #else if $pkginstall contains Install-ChocolateyInstallPackage, then it's a file that needs to be installed
                elseif (( (get-content $pkginstall) | %{$_ -match 'Install-ChocolateyInstallPackage'}) -contains $true) {
            
                    #select any outerhash that contains file but does not contain type
                    $outerhash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$'} | foreach {
                
                    $key = $_ -replace "`n"

                    #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                    if($_.value -match "$toolsdir") {
                
                        $file = ($_.value -split "\" -replace ".$" | Select-Object -Last 1)
                
                        #test to see if the file exists in the working tools directory, if so great
                        if((Test-Path '$pkgnupkg\tools\$file') -eq $True) { Write-Host "The file appears properly mapped in configuration" }
                
                        #else search for the file, if it finds it great
                        elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True) 
                        {
                            Get-FileExe $key $file
                            #store the finding in hashtoalter
                            #$hashtoalter.add($key,("$toolsdir\" + $file))
                        }
                    
                        else { Get-Ignore $key }
                
                    }

                    #if the value of key.uln is a uln, then get me the last value of \ delimiter, see if it exists
                    elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){
                
                        $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                        Get-FileExe $key $file
                        #store the finding in hashtoalter
                        $hashtoalter.add($key,("$toolsdir\" + $file))

                    }    
           

                    #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                    else { Get-Ignore $key }
                }
                    
                    $pkghash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$'} | foreach {

                        #if pkghash.value = outerhash.key THEN leave it alone
                                    <#
                                    foreach($i in $pkghash.keys){
                                        if($outerhash.containskey($pkghash.get_item($i)))
                                        {
                                            write-host "outerhash contains $i"
                                        }
                                        else
                                        {
                                            write-host "outerhash DOES NOT contain $i"
                                        }
                                    }
                                    #>
                        $key = $_ -replace "`n"
                        Write-host "Working with $_ and $pkghash.get_item($key)"
                        #foreach($i in $pkghash.keys)
                        #{
                            if($outerhash.containskey($pkghash.get_item($key)))
                            {
                            Write-Host "PackageArgs contains the key $i with value $pkghash.get_item($i), this value references outerhash.key; leaving the reference alone"
                        }
                            else
                            {
                            #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                            if($_.value -match "$toolsdir") {
                
                                $file = ($_.value -split "\" -replace ".$" | Select-Object -Last 1)
                
                                #test to see if the file exists in the working tools directory, if so great
                                if((Test-Path '$pkgnupkg\tools\$file') -eq $True) { Write-Host "The file appears properly mapped in configuration" }
                
                                #else search for the file, if it finds it great
                                elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True)
                                { Get-FileExe $key $file 
                                    #store the finding in hashtoalter
                                    #$hashtoalter.add($key,("$toolsdir\" + $file))
                                }
                    
                                else { Get-Ignore $key }
                
                            }

                            #if the value of key.uln is a uln, then get me the last value of \ delimiter, see if it exists
                            elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){
                
                                $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                                Get-FileExe $key $file
                                #store the finding in hashtoalter
                                $hashtoalter.add($key,("$toolsdir\" + $file))

                            }
                            #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                            else { Get-Ignore $key }
                        }
                        #}
                    }  
                }
                
                #else if $pkginstall contains install-chocolateyzippackage, then it's a zip file that needs to be installed
                elseif (( (get-content $pkginstall) | %{$_ -match 'Get-ChocolateyUnzip'}) -contains $true) {
            
                    $file = ($_.value -split "\" -replace ".$" | Select-Object -Last 1)
            
                    $outerhash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$'} | foreach {
                
                        $key = $_ -replace "`n"

                        #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                        if($_.value -match "$toolsdir") {
                     
                            #test to see if the file exists in the working tools directory, if so great
                            if((Test-Path '$pkgnupkg\tools\$file') -eq $True) { Write-Host "The file appears properly mapped in configuration" }
                
                            #else search for the file, if it finds it great
                            elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True) {
                    
                                Write-Host "ZIP key exists, searching for the file in cache and lib"
                                Get-FileExe $key $file
                                #store the finding in hashtoalter
                                #$hashtoalter.add($key,("$toolsdir\" + $file))

                            }
                            else { 
                    
                                Write-Host "ZIP key exists but unable to locate the parsed file value, searching for .zip | .7z file"
                                Get-FileZip $key $file
                            }
                
                        }

                    #if the value of key.uln is a uln, then get me the last value of \ delimiter, see if it exists
                    elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){
                        $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                        Write-Host "ZIP Exists, updating outerhash"
                        Get-FileExe $key $file

                    }    
           

                    #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                    else {
            
                        #find file, file will be the .ignore
                        $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter '*.zip*', '*.7z*' -Recurse).Name
                        Write-Host "ULN missing, searching for .zip | .7z"
                        Get-FileExe $key $file
                        #store the finding in hashtoalter
                        $hashtoalter.add($key,("$toolsdir\" + $file))

                    }
                }
                        
                    
                    $key = $_ -replace "`n"
                    #select any pkghash that contains file but does not contain type
                    $pkghash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$'} | foreach {
                
                        $key = $_ -replace "`n"
                
                        Write-host "Working with $key and $pkghash.get_item($key)"
                        #if pkghash.value = outerhash.key THEN leave it alone
                                    <#
                                    foreach($i in $pkghash.keys){
                                        if($outerhash.containskey($pkghash.get_item($i)))
                                        {
                                            write-host "outerhash contains $i"
                                        }
                                        else
                                        {
                                            write-host "outerhash DOES NOT contain $i"
                                        }
                                    }
                                    #>
                        #foreach($i in $pkghash.keys){
                            if($outerhash.containskey($pkghash.get_item($key))){
                            Write-Host "PackageArgs contains the key $i with value $pkghash.get_item($i), this value references outerhash.key; leaving the reference alone"
                        }

                            else{
                            #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                            if($_.value -match "$toolsdir") {
                     
                                #test to see if the file exists in the working tools directory, if so great
                                if((Test-Path '$pkgnupkg\tools\$file') -eq $True) { Write-Host "The file appears properly mapped in configuration" }
                
                                #else search for the file, if it finds it great
                                elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True) {
                    
                                    Write-Host "ZIP key exists, searching for the file in cache and lib"
                                    Get-FileExe $key $file
                                    #store the finding in hashtoalter
                                    #$hashtoalter.add($key,("$toolsdir\" + $file))

                                }
                                else { 
                    
                                    Write-Host "ZIP key exists but unable to locate the parsed file value, searching for .zip | .7z file"
                                    Get-FileZip $key $file
                                }
                
                            }

                            #if the value of key.uln is a uln, then get me the last value of \ delimiter, see if it exists
                            elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){
                                $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                                Write-Host "ZIP Exists, updating outerhash"
                                Get-FileExe $key $file
                                #store the finding in hashtoalter
                                $hashtoalter.add($key,("$toolsdir\" + $file))

                            }    
           

                            #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                            else {
            
                                #find file, file will be the .ignore
                                $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter '*.zip*', '*.7z*' -Recurse).Name
                                Write-Host "ULN missing, searching for .zip | .7z"
                                Get-FileExe $key $file

                            }
                        }
                        #}
                    }
                }
    
                else {Write-Host "You may be hosed, not sure how to parse this file" -BackgroundColor Black -ForegroundColor Red}

                Set-HashToAlter $hashtoalter $pkginstall
        }

            else{Write-Host "$pkg has a chocolateyinstall.ps1 file but does not posses any variables to populate `$outerhash or `$pkghash"}
    }
    
    else{Write-Host "$pkg does not posses a chocolateyinstall.ps1 file"}
    
    #package the whole thing up!
    choco pack "$pkgnupkg\$pkg.nuspec" --out $pkgnupkg

    $counter++

} while ($counter -ne $pkgarray.count)

#when installing you need to specify the source of the nupkg file AS WELL as any directory to look for dependencies
#notepadplusplus has .install nupkg in C:\ProgramData\chocolatey\nupkg so that I add that
#I can also specify ProgramData\chocolatey\lib because that's another function potential
#I can also look into add nupkg as a source but for now I'll manuall specify it
#use single quotes and semi colons with the source field


#choco install $pkg -source 'C:\ProgramData\chocolatey\nupkg' -dv -Y -force


}