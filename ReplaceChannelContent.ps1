## https://www.itprotoday.com/powershell/powershell-basics-arrays-and-hash-tables
clear
## Variable Declaration
$fileoriginal = "E:\GitHub\Free2ViewTV\Free2ViewTV-2020-Remote.m3u"
$filemodificationlist = "E:\GitHub\Free2ViewTV\Free2ViewTV-modificationlist.txt"
$filedeletionlist = "E:\GitHub\Free2ViewTV\Free2ViewTV-deletionlist.txt"
$fileoutput = "E:\GitHub\Free2ViewTV\Free2ViewTV-Dave.m3u"
$regexURL = "^http"
$regexchannelinfoline = "^#EXTINF"
$resultfile =""
$hmodification = @{}
$hprocessed = @{}
$hdeletion = @{}
$debug = $true


## 1- Build the hash table for channel to customize
if ($debug) {
    Write-Host "********************************************************"
    Write-Host "***** BUILD THE HASH TABLE FOR MODIFICATIONS TO DO *****"
    Write-Host "********************************************************"
}
foreach($line in Get-Content $filemodificationlist) {
    if($line -match $regexURL){
        if ($debug) {
            Write-Host "ChannelInfo:"$channelinfos
            Write-Host "ChannelURL:"$line
            Write-Host
        }
        ## we add the custom channel into the hash table
        $hmodification.Add($line, $channelinfos)
    }
    else{
        $channelinfos = $line
    }
}


## 2- Build the Hash table for Channel to remove
if ($debug) {
    Write-Host "****************************************************"
    Write-Host "***** BUILD THE HASH TABLE FOR DELETIONS TO DO *****"
    Write-Host "****************************************************"
}
foreach($line in Get-Content $filedeletionlist) {
    ## we add the custom channel into the hash table
    $Hdeletion.Add($line, "to delete")
}

## 2- Process the Replacement actions
if ($debug) {
    Write-Host "*************************************"
    Write-Host "***** PROCESS THE MODIFICATIONS *****"
    Write-Host "*************************************"
}
$resultfile = ""
foreach($line in Get-Content $fileoriginal) {
    ##Write-Host "ligne:"$line
    
    ## check if we are reading the line containing the Channel URL or not (Its my "key" to find channel into all files)
    if($line -match $regexURL){
        ## we are on the line containing the channel URL

        ##Write-Host "ChannelInfo:"$channelinfos
        ##Write-Host "ChannelURL:"$line
        ##Write-Host
        ## $resultfile = $resultfile + $channelinfos + "`r`n" + $line + "`r`n"

        ## check if this channel must be overwritten by my customs infos
        $custominfo = $hmodification["$line"]
        if ($custominfo){
            ## Channel URL has been found in my Custom Info File
            $infotouse = $custominfo
            if ($debug) {
                Write-Host "Trouvé"
                Write-Host "CustomInfo:"$custominfo
                Write-Host "URL:"$line
            }
            ## add the channel into the HPROCESSED hash table to indicate that this channel has already been considered in the "merge process"
            $hprocessed.Add($line, $custominfo)

        }
        else{
            ## Channel URL not found in my Custom info File.  So we keep the original value
            ##if ($debug) {Write-Host "Non - Trouvé"}
            $infotouse = $channelinfos
        }

        ## check if the channel is in the file for channel to remove
        $todelete = $hdeletion["$line"]
        if(!$todelete){
            ## Channel not found into the filedeletion.. so channel must be kept
            $resultfile = $resultfile + $infotouse + "`r`n" + $line + "`r`n"
        }
        else{
            if ($debug) {Write-Host "Channel supprimé:"$line}
        }
        
    }
    else{
        ## we are on the line listing channel's informations
        if($line -match $regexchannelinfoline){
            $channelinfos = $line
        }
        else {
            ## we must simply transfer that line "as is" to the new file
            $resultfile = $resultfile + $line + "`r`n"
        }
        
    }
}


## 3- ADD custom URL that has not been processed yet.
## we must parse the H table to check which custom channel has not been processed yet.  And add them "as is" at the end of the file
if ($debug) {
    Write-Host "********************************************"
    Write-Host "***** ADD CUSTOM URL NOT PROCESSED YET *****"
    Write-Host "********************************************"
}
$hmodification.Keys | ForEach-Object {
    $custominfo = $hprocessed["$_"]
    if (!$custominfo){
        ## we did not find the channell... so we add this channel 
        $resultfile = $resultfile + $hmodification[$_] + "`r`n" + $_ +  "`r`n"
    } 
} 




## 4- write the file content into a physical file
if ($debug) {
    Write-Host "*************************"
    Write-Host "***** SAVE THE FILE *****"
    Write-Host "*************************"
}
##$resultfile | Out-File -Encoding UTF8NoBOM $fileoutput
## use this method to save the file to make sure will be UTF (wihoutbom)
[System.IO.File]::WriteAllLines($fileoutput, $resultfile)