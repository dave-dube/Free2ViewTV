##################################################################
############################# Downlaod all EPG
Invoke-WebRequest -Uri "https://is.gd/dd_f2vtv_epg" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\DavePerso.xml"
Invoke-WebRequest -Uri "https://i.mjh.nz/PlutoTV/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\Pluto.xml"
# Canadian EPG (this will be expanded later this summer to support additional channels!)
Invoke-WebRequest -Uri "https://od.lk/s/MzJfMTQyMzI0MTJf/CAN_EPG1.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\CanadianEPG.xml"
# PBS (Geo-USA) ** (updated 7/20/21)
Invoke-WebRequest -Uri "https://i.mjh.nz/PBS/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\PBSUSA.xml"
# Selected USA Over-The-Air channels
Invoke-WebRequest -Uri "https://od.lk/s/MzJfMTQyMzI0MTVf/KCK_66101.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\USAOTA.xml"
# Additional USA Over-The-Air channels
Invoke-WebRequest -Uri "https://od.lk/s/MzJfMTQyMzI0MTZf/NYC_10001_OTA.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\USAOTA2.xml"
# Plex ** [as of 8/01]
Invoke-WebRequest -Uri "https://i.mjh.nz/Plex/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\Plex.xml"
# Stirr EPG ** (updated 7/20/21)
Invoke-WebRequest -Uri "https://i.mjh.nz/Stirr/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\Stirr.xml"
# WatchYour.TV (also courtesy of @Smacca in our Discord community)
Invoke-WebRequest -Uri "https://rb.gy/kyh87b" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\WatchYour.xml"
# Samsung TV Plus ** (updated 7/20/21)
Invoke-WebRequest -Uri "https://i.mjh.nz/SamsungTVPlus/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\SamsungTVPlus.xml"
# Pluto TV ** (updated 7/20/21)
Invoke-WebRequest -Uri "https://i.mjh.nz/PlutoTV/all.xml" -OutFile "E:\GitHub\Free2ViewTV\EPG\TempDownload\PlutoTV.xml"
##################################################################


##################################################################
################################# Merge des différents fichier EPG
$xmldoc = new-object xml
$rootnode = $xmldoc.createelement("stuff")
$xmldoc.appendchild($rootnode)
$finalxml = $null
$files = gci "E:\GitHub\Free2ViewTV\EPG\TempDownload\" 

foreach ($file in $files) {
    [xml]$xmlstuff = gc $file.fullname
    $innerel = $xmlstuff.selectnodes("/*/*")

    foreach ($inone in $innerel) {
        $inone = $xmldoc.importnode($inone, $true)
        $rootnode.appendchild($inone)
    }
}
# create and set xmlwritersettings
$xws = new-object system.xml.XmlWriterSettings
$xws.Indent = $true
$xws.indentchars = "`t"
$xtw = [system.xml.XmlWriter]::create("e:\GitHub\Free2ViewTV\EPG\MergedEPG_DD.xml", $xws)
$xmldoc.WriteContentTo($xtw)
$xtw.flush()
$xtw.dispose()
##################################################################
