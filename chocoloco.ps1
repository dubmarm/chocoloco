#REFERENCE SITE: https://chocolatey.org/docs/how-to-recompile-packages

# .ignore - how to handle multiple?
# mainpkg - get rid of it
# fix the remove-item logic

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
    "pdfcreator" #failed, it fails to choco install pdfcreator (not my problem but i should write a check for choco install complete)
    "paint.net"
    "gimp"
    "python2"
    "cutepdf"
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
x    "crystaldiskinfo"
x    "virtualclonedrive"
x    "f.lux"
x    "rufus"
    "vmwarevsphereclient"
x    "youtube-dl"
x    "winscp"
    "tightvnc" #1603 error
#>

import-module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
import-module C:\ProgramData\chocolatey\helpers\chocolateyProfile.psm1

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
    
    Write-Host "Starting the .ignore fish logic" -ForegroundColor Yellow -BackgroundColor Black
    
    $fishin = Get-ChildItem -Path $pkgcache\$pkg,$pkglib\$pkg -Recurse -File | where { `
        $_.extension -ne ".nupkg" `
        -and $_.extension -ne ".nuspec" `
        -and $_.extension -ne ".ignore" `
        -and $_.name -ne "$pkg.zip" `
        -and $_.name -ne "chocolateyInstall.ps1" `
        -and $_.name -ne "chocolateyUninstall.ps1" `
        -and $_.name -ne "chocolateyUninstall.ps1" `
        -and $_.name -ne "helpers.ps1" `
    }
    
    #i'm really fishing here; it's not my fault every package has to be special
    if( ( Get-ChildItem -Path $pkgcache\$pkg,$pkglib\$pkg -Filter '*.ignore' -Recurse).count -eq 1 )
    {
        Write-Host "Found a single .ignore file, searching for it's identical installer" -ForegroundColor Magenta -BackgroundColor Black

        (Get-ChildItem -Path $pkgcache\$pkg,$pkglib\$pkg -Filter '*.ignore' -Recurse) | foreach-object `
        {
             $path = $_.DirectoryName
             $file = $_ -replace '.ignore',''
             if ( Test-Path "$path\$file" )
             {
                 Write-Host "Installer Located" -ForegroundColor Magenta -BackgroundColor Black
                 $file.Name

                 #store the finding in hashtoalter
                 $hashtoalter.add($key,("$toolsdir\" + $file))

                 Get-Install "$file"
             }
             else
             {
                Write-Host "You're hosed, there is a .ignore file but no respective executable file. Can't continue" -ForegroundColor Red -BackgroundColor Black
             }
        }
    }
    elseif( ( Get-ChildItem -Path $pkgcache\$pkg,$pkglib\$pkg -Filter '*.ignore' -Recurse).count -gt 1 )
    {
        Write-Host "Found multiple .ignore files, going to try and find the main file"

        (Get-ChildItem -Path $pkgcache\$pkg,$pkglib\$pkg -Filter '*.ignore' -Recurse) | foreach-object `
        {
             $file = $_ -replace '.ignore',''
             if ( ( Get-Content $pkginstall ) -contains $file.Name )
             {
                 Write-Host "The .ignore file identified is mentioned in the chocolateyInstall.ps1 file, going to use this as the main file" -ForegroundColor Magenta -BackgroundColor Black
                 #store the finding in hashtoalter
                 $hashtoalter.add($key,("$toolsdir\" + $file))

                 Get-Install "$file"
             }
             elseif ( ( Get-Content $pkginstall ) -contains $pkg )
             {
                 Write-Host "The .ignore file identified is named similar to the package, going to use this as the main file" -ForegroundColor Magenta -BackgroundColor Black
                 #store the finding in hashtoalter
                 $hashtoalter.add($key,("$toolsdir\" + $file))

                 Get-Install "$file"
             }
             else
             {
                Write-Host "You're hosed, there is no .ignore file and no recognizable executable file. Can't continue" -ForegroundColor Red -BackgroundColor Black
             }
        }
    }
    elseif ( $fishin.count -eq 1)
    {
        $file = $fishin[0].Name

        Write-Host "Went fishin and found a single non-.ignore file, going to use this as the main file" -ForegroundColor Magenta -BackgroundColor Black
        #store the finding in hashtoalter
            $hashtoalter.add($key,("$toolsdir\" + $file))

            Get-Install "$file"
    }
    else
    {
    Write-Host "You're hosed, there is no .ignore file and multiple files returned from fishin'. Can't continue" -ForegroundColor Red -BackgroundColor Black
    }
}

function Get-Install ($file) {
    Write-Host "File is: $file"
    
    Get-ChildItem -Path $pkgcache -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName (Split-Path $pkginstall) -Force }
    Get-ChildItem -Path $pkglib -Filter "*$file*" -Recurse | ForEach-Object { cp $_.FullName (Split-Path $pkginstall) -Force }
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
    choco config set cacheLocation "C:\ProgramData\chocolatey\cache"
}
else { Write-Host "cacheLocation is already set to 'C:\ProgramData\chocolatey\cache'; moving on" -foreground Yellow }

#Variables
$mainhash = @(
"ffmpeg"
)

foreach($i in $mainhash){

    $mainpkg = $i
    $mainpkglib = "C:\ProgramData\chocolatey\lib\$mainpkg"
    $mainpkgcache = "C:\ProgramData\chocolatey\cache\$mainpkg"

    #some packages (itunes) have a Remove-Item that deletes the cache installers during chocolateyinstall.ps1. we need to remove that before continuing; see same comment below
    choco install $mainpkg -y --skippowershell -force -r

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

    do {

        Write-host "Working with $pkgarray["$counter"]" -ForegroundColor Yellow
    
        $pkg = $pkgarray["$counter"]

        $pkglib = "C:\ProgramData\chocolatey\lib\"#$pkg
        $pkgcache = "C:\ProgramData\chocolatey\cache\"#$pkg
        $pkgnupkg = "C:\ProgramData\chocolatey\nupkg\$pkg"

        #some packages (itunes) have a Remove-Item that deletes the cache installers during chocolateyinstall.ps1. we need to remove that before continuing
        if( (Get-ChildItem $pkglib\$pkg -Filter "chocolateyInstall.ps1" -Recurse).FullName -ne $null )
        {
                
            $script = (Get-ChildItem $pkglib\$pkg -Filter "chocolateyInstall.ps1" -Recurse).FullName
            $scriptcontent = (get-content $script -RAW)

            if ($scriptcontent -match "Remove-Item[ \t]")
            {
                Write-Host "chocolateyInstall.ps1 contains Remove-Item, removing that line so that nothing is deleted" -ForegroundColor Yellow
                ($scriptcontent) -replace "(Remove-Item[ \t].*)","" | Set-Content $script

                [xml]$nuspec = (Get-Content "$pkglib\$pkg\*.nuspec")
                $env:TEMP = "$pkgcache\$pkg"
                $env:ChocolateyPackageName = $nuspec.package.metadata.id
                $env:ChocolateyPackageTitle = $nuspec.package.metadata.title
                $env:ChocolateyPackageVersion = $nuspec.package.metadata.version
                $env:ChocolateyPackageFolder = "$pkglib\$pkg"


                #install the package traditionally
                . $script
            }
            elseif ($scriptcontent -match "^rm[ \t]")
            {
                Write-Host "chocolateyInstall.ps1 contains Remove-Item, removing that line so that nothing is deleted" -ForegroundColor Yellow
                ($scriptcontent) -replace "^rm[ \t]","" | Set-Content $script

                [xml]$nuspec = (Get-Content "$pkglib\$pkg\*.nuspec")
                $env:TEMP = "$pkgcache\$pkg"
                $env:ChocolateyPackageName = $nuspec.package.metadata.id
                $env:ChocolateyPackageTitle = $nuspec.package.metadata.title
                $env:ChocolateyPackageVersion = $nuspec.package.metadata.version
                $env:ChocolateyPackageFolder = "$pkglib\$pkg"


                #install the package traditionally
                . $script
            }
            else
            {
                choco install $pkg -y --force -r
            }
        }

    
    #create the local working directory where parsing and hosting will take place
    Copy-Item "$pkglib\$pkg" $pkgnupkg -recurse -force

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
        Write-Host "chocolateyInstall.ps1 cannot be found in " $pkgnupkg\$pkg " skipping parsing for this package" -ForegroundColor Red -BackgroundColor Black
        $pkginstall = $null
    }

    if( $pkginstall -ne $null )
    {
            #parser array setup for PackageArgs @{} within file
            $content = get-content -Path $pkginstall | Out-String
            $pkgargs = ([regex] '(?is)(?<=\$packageArgs[ \t]+\=[ \t]@{).*?(?=})').matches($content)
            $pkgargs = $pkgargs.value -split "`r`n"
            $pkgargs = $pkgargs -replace '\\','\\'

            $outervar = ([regex]::Matches($content,'(?mi)^(\$\S*[ \t]+\=[ \t])(.*)'))
            $outervar = $outervar.value -split "`r`n"
            $outervar = $outervar -replace '\\','\\'

            #sometimes packages have an embedded array in their variable definitions, we need to it in the variable definition
            $pkghash = @{}
            $pkgcounter = 0
            
            do{
                foreach ($i in $pkgargs)
                {
                    #if a variable contains "= @(" and does not contain = @() (same line)
                    if( $i -match ".*=[ \t]@\(" -and $i -notmatch "\b.*=[ \t]@\(\b")
                        {
                            $i = ( [regex]"(?si)\$i.*)" ).matches($pkgargs)
                            $pkghash += ConvertFrom-StringData -StringData $i.value
                            $pkgcounter++
                        }
                    #if a variable contains "= @{" and does not contain = @{} (same line)
                    elseif( $i -match ".*=[ \t]@\{" -and $i -notmatch "\b.*=[ \t]@\{\b" )
                        {
                            $i = ( [regex]"(?si)\$i.*}" ).matches($pkgargs)
                            $pkghash += ConvertFrom-StringData -StringData $i.value
                            $pkgcounter++
                        }
                    #if a variable does NOT contain "="
                    elseif( $i -notmatch ".*=.*" )
                        {
                            $pkgcounter++
                        }
                    #then it's a normal $var = $val
                    else
                        {
                            $pkghash += ConvertFrom-StringData -StringData $i
                            $pkgcounter++
                        }
                }
            } while ($pkgcounter -ne $pkgargs.count)

            #parser array setup for $var definitions within file
            $outerhash = @{}
            $outercounter = 0

            do{
                foreach ($i in $outervar)
                {
                    $outerhash += ConvertFrom-StringData -StringData $i
                    $outercounter++
                }
            } while ($outercounter -ne $outervar.count)


            #alter array used as final reference array for all changes to be made to chocolateyinstall.ps1
            $hashtoalter = @{}

            
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
                                    Write-Host "The url key could not parse the http(s) value for a filename, searching for .ignore file instead" -ForegroundColor Red -BackgroundColor Black
                                    Get-Ignore $key
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
                                    Write-Host "The url key could not parse the toolsdir value for a filename, searching for .ignore file instead" -ForegroundColor Red -BackgroundColor Black
                                    Get-Ignore $key
                                }

                        }
                        
                        else
                        {
                            Write-Host "The url key could not parse the value for a filename, searching for .ignore file instead" -ForegroundColor Red -BackgroundColor Black
                            Get-Ignore $key
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
                                    Write-Host "the pkghash url key could not locate the filename listed in the http(s) key" -ForegroundColor Red -BackgroundColor Black
                                    Get-Ignore $key
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

                                else 
                                {
                                    Get-Ignore $key 
                                }
                                                    
                        }

                        else
                        {
                            Write-Host "the pkghash url key could not locate the filename listed in the toolsdir key, searching for .ignore instead"
                            Get-Ignore $key
                        }
                    }
                  

                #select any outerhash that contains file but does not contain type or args
                $outerhash.keys | where {$_ -match 'file'} | where {$_ -match ('^(?!.*[Tt]ype).*$') -and $_ -match ('^(?!.*[Aa]rgs).*$')} | foreach {
                
                    Write-Host "outerhash contains a file key"
                    
                    $key = $_ -replace "`n"
                    $file = $outerhash.get_item($key)
                    $file = $file -replace '"',""

                    Write-host "Working with $_ and " $outerhash.get_item($key)
           
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
                                Get-Install $key $file
                            }

                            else
                            {
                                Write-Host "the outerhash file key could not locate the filename listed in the toolsdir key, searching for .ignore instead"
                                Get-Ignore $key
                            }
                
                    }

                    #if the value of key.uln is a uln, then see if it exists
                    elseif((Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name){
                
                        Write-Host "outerhash contains a file key that has a static uln in the value, attempting to parse uln for file"
                        
                        $file = (Get-ChildItem -Path $pkgcache,$pkglib -Filter $file -Recurse).name
                        Get-Install $key $file
                        #store the finding in hashtoalter
                        $hashtoalter.add($key,("$toolsdir\" + $file))
                    }    
           

                    #else, attempt to find a .ignore in cache and lib and use that filename as the new url.value
                    else
                    {
                        Get-Ignore $key 
                    }
                }
                    
                #select any pkghash that contains file but does not contain type or args
                $pkghash.keys | where {$_ -match 'file'} | where {$_ -match '^(?!.*type).*$' -and $_ -match '^(?!.*args).*$'} | foreach {

                    Write-Host "pkghash contains a file key"

                    $key = $_ -replace "`n"
                    $file = $pkghash.get_item($key)
                    $file = $file -replace '"',""

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
                                        Get-Ignore $key
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

                            else
                            {
                                Get-Ignore $key 
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



#choco uninstall $pkg -y
choco install $pkg -source 'C:\ProgramData\chocolatey\nupkg' -Y -force -r


}