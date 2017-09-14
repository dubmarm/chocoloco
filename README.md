# chocoloco

This script is a sad sad attempt at skirting the paid-ware fee of chocolatey. With this script I see if I can download a package, strip it, and repackage it.

I should have just paid the fee...

Currently with the script you populate $mainhash = @() with chocolatey packages you wish to install. The script will download the package from chocolatey, then parse the chocolateyInstall.ps1 file to localize it. This allows a server to become a HOST for these packages. When a client wishes to install a package the install will point to the hosted file ('choco install vlc -s $HOSTDIR').

What this accomplishes is a centralized and localized repository. Clients do not have to go out to the web for installers, saving bandwidth with a download once and disribute many model (great when you're at Palmer Station with 2Mbps Downlink). It's also great because now 3rd Party applications can be handled like a Linux Repo, the way life should be.

NOTE: this script is not perfect, it will spit out errors that aren't true. Or it may fail to install the package. Having knowledge of chocolatey will help you troubleshoot my code. Hopefully I can clean this up more but at the end of the day, it is very difficult parsing a file that holds little consistency between applications (they are all unique).

The following chocolatey packages are tested regularly:
    "googlechrome"
    
    "notepadplusplus"
    
    "adobereader"
    
    "adobereader-update"
    
    "firefox"
    
    "spark"
    
    "7zip"
    
    "vlc"
    
    "sysinternals"
    
    "filezilla"
    
    "putty"
    
    "pdfcreator"
    
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
    
    "crystaldiskinfo"
    
    "virtualclonedrive"
    
    "f.lux"
    
    "rufus"
    
    "vmwarevsphereclient"
    
    "youtube-dl"
    
    "winscp"
