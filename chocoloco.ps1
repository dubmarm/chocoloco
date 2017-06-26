#REFERENCE SITE: https://chocolatey.org/docs/how-to-recompile-packages
<#
    "googlechrome"
    "notepadplusplus"
    "adobereader"
    "adobereader-update" #(adobereader must be installed first or else adobe throws a 1643 error)
    "firefox"
    "spark"
    "7zip"
    "vlc"
    "sysinternals"
    "filezilla"
    "putty"
?    "pdfcreator" #failed, it fails to choco install pdfcreator (not my problem but i should write a check for choco install complete)
x    "paint.net"
x    "gimp"
    "python2"
x    "cutepdf"
    "itunes"
    "windirstat"
    "irfanview"
    "flashplayerppapi"
    "flashplayerplugin"
    "flashplayeractivex"
    "adobeshockwaveplayer"
    "cdburnerxp"
    "fiddler4"
    "greenshot"
    "googleearthpro"
    "imagemagick.app"
    "ffmpeg"
    "crystaldiskinfo"
    "virtualclonedrive"
    "f.lux"
    "rufus"
    "vmwarevsphereclient"
    "youtube-dl"
    "winscp"
    "tightvnc"
#>

import-module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
import-module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1

#Variables
$mainhash = @(
    "adobereader"
    "adobereader-update"
    "spark"
    "7zip"
    "vlc"
    "sysinternals"
    "filezilla"
    "putty"
)

foreach($i in $mainhash){

$mainpkg = $i
$mainpkglib = "C:\ProgramData\chocolatey\lib\$mainpkg"
$mainpkgcache = "C:\ProgramData\chocolatey\cache\$mainpkg"

function Get-HttpExe($key, $file) {            
    Write-Host "ULN exists in http(s) address, updating outerhash"
    
    #store the finding in hashtoalter
    $hashtoalter.add($key,("$toolsdir\" + $file))

    Get-Install $file
}

function Get-FileExe($key, $file) {

    Write-Host "FILE key exists, searching for the file in cache and lib"            
    Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse
    Get-FileZip "$key" "$file"

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
    
    Get-ChildItem -Path $pkgcache -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName (Split-Path $pkginstall) -Force }
    Get-ChildItem -Path $pkglib -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName (Split-Path $pkginstall) -Force }
<#
    Get-ChildItem -Path $pkglib\tools -Recurse | ForEach-Object {
        if(! (Test-Path $pkgnupkg\tools\$_ ) ){
            cp $_.FullName (Split-Path $pkginstall) -Force 
         }
    }
#>
    Get-ChildItem -Path $pkgnupkg -Filter "*$file*" -Recurse
}

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
            else
            {
                Write-Host "$i does not contain a pre-pended $" -ForegroundColor Yellow
                write-host "$i is a single line replace" -ForegroundColor Yellow
                ($str) -replace "($i)([.| \t]+=[ \t]).*","`${1}`${2}""$a"""  | set-content $pkginstall 
            }
        }

    Remove-Checksum
}

function Remove-Checksum() {
    
 #    '(.+file.+=[ \t])(.*)'
 #    '(.+url.+=[ \t])(.*)'
 #    '(.+checksum.+=[ \t])(.*)'

       (Get-Content $pkginstall -Raw) | `
       foreach {$_ -replace '(.+checksum.+=[ \t])(.*)',""} | `
       foreach {$_ -replace '(-checksum.+?(?=[-|\n]))',""} | `
       #set-content "C:\ProgramData\chocolatey\nupkg\virtualbox\fuckwindows.txt"
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


#some packages (itunes) have a Remove-Item that deletes the cache installers during chocolateyinstall.ps1. we need to remove that before continuing
choco install $mainpkg -y --skippowershell
$script = (Get-ChildItem $mainpkglib -Filter chocolateyinstall.ps1 -Recurse).FullName
$scriptcontent = (get-content $script -RAW)

if ($scriptcontent -match "Remove-Item")
{
    ($scriptcontent) -replace "(Remove-Item.*)","" | Set-Content $script

    [xml]$nuspec = (Get-Content "$mainpkglib\*.nuspec")
    $env:TEMP = $mainpkgcache
    $env:ChocolateyPackageName = $nuspec.package.metadata.id
    $env:ChocolateyPackageTitle = $nuspec.package.metadata.title
    $env:ChocolateyPackageVersion = $nuspec.package.metadata.version
    $env:ChocolateyPackageFolder = $mainpkglib


    #install the package traditionally
    . $script
}
else
{
    choco install $mainpkg -y --force
}

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

    #unzip the nupkg file
    cp "$pkglib\*.nupkg" "$pkglib\$pkg.zip"
    if(! (Test-Path $pkgnupkg))
    {
            New-Item -ItemType Directory -Force -Path $pkgnupkg
    }
        
    expand-archive -path "$pkglib\$pkg.zip" -destinationpath $pkgnupkg -force

    #remove un-needed, soon to be recreated elements
    remove-item -Recurse "$pkgnupkg\_rels", "$pkgnupkg\package"
    remove-item -LiteralPath [Content_Types].xml

    if(Test-Path "$pkgnupkg\tools\chocolateyInstall.ps1")
    {
        $pkginstall = "$pkgnupkg\tools\chocolateyInstall.ps1"
    }
    elseif(Test-Path "$pkgnupkg\chocolateyInstall.ps1")
    {
        $pkginstall = "$pkgnupkg\chocolateyInstall.ps1"
    }
    else
    {
        Write-Host "Game Over Man, chocolateyInstall cannot be found in " $pkgnupkg -ForegroundColor Red -BackgroundColor Black
    }

    if(Test-Path $pkginstall)
    {
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

            $outervar = ([regex]::Matches($content,'(?mi)^(\$\S*[ \t]+\=[ \t])(.*)'))
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


                #Crush your enemies. See them driven before you. Hear the lamentations of their women
                Write-Host "What is best in life?.....The parsing of my chocolatey!" -ForegroundColor Green -BackgroundColor Black
                    
                #select any outerhash that contains url
                $outerhash.keys | where {$_ -match 'url'} | foreach {
                        
                        Write-Host "outerhash contains a url key"
                        $key = $_ -replace "`n"
            
                        #if the url.key has a http(s) string in it's value, then perform the following logic to find the exe
                        if($outerhash.get_item($key) -match 'http://' -or $outerhash.get_item($key) -match 'https://') {
                            
                            Write-Host "outerhash url key has an http(s) value, attempting to parse http for file"
                            
                            if( ($outerhash.get_item($key) -split "/" | Select-Object -Last 1).length -gt 1 )
                            {
                                $file = ($outerhash.get_item($key) -split "/" -replace ".$" | Select-Object -Last 1)
                            }
                            else
                            {
                                $file = ($outerhash.get_item($key) -split "/" | Select-Object -Last 2 | Select-Object -First 1)
                            }


                            Write-Host "Working with $key and $file"
                            
                                #if the value of key.url is a uln, then see if it exists
                                if( (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name )
                                {
                                    Get-HttpExe $key $file
                                }

                                else
                                {
                                    Write-Host "The url key could not parse the http(s) value for a filename, searching for .ignore file instead"
                                    #Get-Ignore $key
                                }
            
                        }

                        #elseif the url.key has a $toolsdir\ pattern then work with that
                        elseif($outerhash.get_item($key) -match "$toolsdir"){
                        
                            Write-Host "outerhash url key has a toolsdir uln path, attempting to parse uln for file"
                            
                            if( ($outerhash.get_item($key) -split "\" | Select-Object -Last 1).length -gt 1 )
                            {
                                $file = ($outerhash.get_item($key) -split "\" -replace ".$" | Select-Object -Last 1)
                                $file
                            }
                            else
                            {
                                $file = ($outerhash.get_item($key) -split "\" | Select-Object -Last 2 | Select-Object -First 1)
                                $file
                            }
                
                                #test to see if the file exists in the working tools directory, if so great
                                if( (Test-Path '$pkgnupkg\tools\$file') -eq $True )
                                {
                                    Write-Host "The file appears properly mapped in configuration"
                                }
                
                                #else search for the file, if it finds it great
                                elseif( (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True )
                                {
                                    Get-FileExe $key $file
                                }

                                else
                                {
                                    Write-Host "The url key could not parse the toolsdir value for a filename, searching for .ignore file instead"
                                    #Get-Ignore $key
                                }

                        }
                        
                        else
                        {
                            Write-Host "The url key could not parse the value for a filename, searching for .ignore file instead"
                            #Get-Ignore $key
                        }
                    }

                #select any pkghash that contains url
                $pkghash.keys | where {$_ -match "url"} | foreach {
                        
                        Write-Host "pkghash contains a url key"
            
                        $key = $_ -replace "`n"
                        $key
                
                        #if the url.key has a http(s) string in it's value, then perform the following logic to find the exe
                        if($pkghash.get_item($key) -match 'http://' -or $pkghash.get_item($key) -match 'https://') {
            
                            Write-Host "pkghash contains a url key with an http(s) value, attempting to parse http path for file"
                            
                            if( ($pkghash.get_item($key) -split "/" | Select-Object -Last 1).length -gt 1 )
                            {
                                $file = ($pkghash.get_item($key) -split "/" -replace ".$" | Select-Object -Last 1)
                                $file
                            }
                            else
                            {
                                $file = ($pkghash.get_item($key) -split "/" | Select-Object -Last 2 | Select-Object -First 1)
                                $file
                            }


                                #if the value of key.url is a uln, then get me the last value of / delimiter, see if it exists
                                if( ( Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name )
                                {
                                    Write-Host "the pkghash url key was located"
                                    Get-HttpExe $key $file
                                }
                                else
                                {
                                    Write-Host "the pkghash url key could not locate the filename listed in the http(s) key"
                                    #Get-Ignore $key
                                }
            
                        }
                        
                        #elseif the url.key has a $toolsdir\ pattern then work with that
                        elseif($pkghash.get_item($key) -match "$toolsdir"){
                        
                            Write-Host "pkghash contains a url key with a uln value, attempting to parse uln path for file"
                            
                            if( ($pkghash.get_item($key) -split "\" | Select-Object -Last 1).length -gt 1 )
                            {
                                $file = ($pkghash.get_item($key) -split "\" -replace ".$" | Select-Object -Last 1)
                                $file
                            } else
                            {
                                $file = ($pkghash.get_item($key) -split "\" | Select-Object -Last 2 | Select-Object -First 1)
                                $file
                            }
                
                                #test to see if the file exists in the working tools directory, if so great
                                if( (Test-Path '$pkgnupkg\tools\$file') -eq $True )
                                {
                                    Write-Host "The file appears properly mapped in configuration"
                                }
                
                                #else search for the file, if it finds it great
                                elseif( (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True )
                                {
                                    Get-FileExe $key $file
                                }

                                else { #Get-Ignore $key 
                                }
                                                    
                        }

                        else
                        {
                            Write-Host "the pkghash url key could not locate the filename listed in the toolsdir key, searching for .ignore instead"
                            #Get-Ignore $key
                        }
                    }
                  

                #select any outerhash that contains file but does not contain type or args
                $outerhash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$','^(?!.*args).*$'} | foreach {
                
                    Write-Host "outerhash contains a file key"
                    
                    $key = $_ -replace "`n"

                    Write-host "Working with $_ and " $pkghash.get_item($key)

                    #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                    if( $outerhash.get_item($key) -match "$toolsdir" ) {
                
                        Write-Host "outerhash contains a file key that has toolsdir in the value, attempting to parse toolsdir for file"
                        
                        if( ($outerhash.get_item($key) -split "\" | Select-Object -Last 1).length -gt 1 )
                        {
                            $file = ($outerhash.get_item($key) -split "\" -replace ".$" | Select-Object -Last 1)
                            $file
                        }
                        else
                        {
                            $file = ($outerhash.get_item($key) -split "\" | Select-Object -Last 2 | Select-Object -First 1)
                            $file
                        }
                
                            #test to see if the file exists in the working tools directory, if so great
                            if( (Test-Path '$pkgnupkg\tools\$file') -eq $True )
                            {
                                Write-Host "The file appears properly mapped in configuration"
                            }
                
                            #else search for the file, if it finds it great
                            elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True) 
                            {
                                Get-FileExe $key $file
                            }

                            else
                            {
                                Write-Host "the outerhash file key could not locate the filename listed in the toolsdir key, searching for .ignore instead"
                                #Get-Ignore $key
                            }
                
                    }

                    #if the value of key.uln is a uln, then see if it exists
                    elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){
                
                        Write-Host "outerhash contains a file key that has a static uln in the value, attempting to parse uln for file"
                        
                        $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                        Get-FileExe $key $file
                        #store the finding in hashtoalter
                        $hashtoalter.add($key,("$toolsdir\" + $file))
                    }    
           

                    #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                    else { #Get-Ignore $key 
                    }
                }
                    
                #select any pkghash that contains file but does not contain type or args
                $pkghash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$','^(?!.*args).*$'} | foreach {

                        Write-Host "pkghash contains a file key"

                        $key = $_ -replace "`n"
                        
                        Write-host "Working with $_ and " $pkghash.get_item($key)
                            
                        if($outerhash.containskey($pkghash.get_item($key)))
                        {
                            Write-Host "PackageArgs contains the key $i with value $pkghash.get_item($i), this value references outerhash.key; leaving the reference alone"
                        }
                        else
                        {
                            #if the file.key has $toolsdir\file string in it's value, then perform the following logic
                            if($pkghash.get_item($key) -match "$toolsdir") {
                
                                Write-Host "pkghash contains a file key that has toolsdir in the value, attempting to parse toolsdir for file"
                                
                                if( ($pkghash.get_item($key) -split "\" | Select-Object -Last 1).length -gt 1 )
                                {
                                    $file = ($pkghash.get_item($key) -split "\" -replace ".$" | Select-Object -Last 1)
                                    $file
                                }
                                else
                                {
                                    $file = ($pkghash.get_item($key) -split "\" | Select-Object -Last 2 | Select-Object -First 1)
                                    $file
                                }
                
                                    #test to see if the file exists in the working tools directory, if so great
                                    if( (Test-Path '$pkgnupkg\tools\$file') -eq $True )
                                    {
                                        Write-Host "The file appears properly mapped in configuration"
                                    }
                
                                    #else search for the file, if it finds it great
                                    elseif( (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse) -eq $True )
                                    {
                                        Get-FileExe $key $file 
                                    }
                    
                                    else
                                    {
                                        Write-Host "the pkghash file key could not locate the filename listed in the toolsdir key, searching for .ignore instead"
                                        #Get-Ignore $key
                                    }
                
                            }

                            #if the value of key.uln is a uln, then get me the last value of \ delimiter, see if it exists
                            elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter '$file' -Recurse).name){

                                Write-Host "pkghash contains a file key that has a static uln in the value, attempting to parse uln for file"

                                $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                                Get-FileExe $key $file
                                #store the finding in hashtoalter
                                $hashtoalter.add($key,("$toolsdir\" + $file))

                            }

                            else { #Get-Ignore $key 
                            }
                        }
                }  

                Set-HashToAlter $hashtoalter $pkginstall
        }
        
        else{Write-Host "$pkg has a chocolateyinstall.ps1 file but does not posses any variables to populate `$outerhash or `$pkghash"}
    }
    else
    {
        Write-Host "$pkg does not posses a chocolateyinstall.ps1 file" -ForegroundColor Red -BackgroundColor Black
    }

    #package the whole thing up!
    choco pack "$pkgnupkg\$pkg.nuspec" --out $pkgnupkg

    $counter++

} while ($counter -ne $pkgarray.count)



choco uninstall $pkg -y
choco install $pkg -source 'C:\ProgramData\chocolatey\nupkg' -Y -force


}