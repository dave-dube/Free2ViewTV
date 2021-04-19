# https://www.itprotoday.com/powershell/powershell-basics-arrays-and-hash-tables
<#
Dave Dubé
ce script permet de prendre le fichier M3U original de Geonsey qui a fait FREE2VIEWTV, et faire :
    - Remplacement des infos sur des channel (Ex: Pour mettre le bon EPGID pour que ca match avec mon EPG file)
        - Remplir le fichier Free2ViewTV-modificationlist.txt avec la liste des ChannelInfos+ChannelURL (dans la même structure que le fichier original de Geonsey)
    - Supprimer une liste de channel qu'on ne voudrais pas
        - Remplir le fichier Free2ViewTV-deletionlist.txt avec la liste des ChannelURL uniquement (Pas besoin de la ligne "ChannelInfos")

étapes fait pas le script:
    1- Prend le fichier Free2ViewTV-2020-Remote.m3u
    2- remplace les lignes de "ChannelInfos" qui sont présent dans le fichier xxxmodificationlist.txt
    3- Ajoute la liste des channels qui sont dans le fichier xxxmodificatinolist.txt mais pas dnas le fichier original Free2ViewTV-2020-Remote.m3u
    4- retirer les channels qui sont inscrit dans le fichier xxxdeletionlist.txt
    5- sauvegarde le résultat dans le fichier Free2ViewTV-Dave.m3u
    6- Créer un fichier de ExecutionLog.txt pour logger les erreurs + anomalies rencontrés
    7- envoie par email le fichier ExecutionLog.txt pour fin de suivit.


Historique
Date        Description
2020-12-11  Ajout concept de Config.ini

#>
clear

# Read the Config file provided by the parameter
$fileconfig=$args[0]
# Set default value if parameter not provided
if(!$fileconfig) {
    $fileconfig = "E:\GitHub\pour update M3U et EPG pour tivimate\config.json"
}
# Read the Config file
$SettingsObject = Get-Content -Path $fileconfig | ConvertFrom-Json



## Variable Declaration
#$fileoriginal = "E:\GitHub\Free2ViewTV\Free2ViewTV-2020-Remote.m3u"
$fileoriginal = $SettingsObject.FileM3UOriginal
$filemodificationlist = $SettingsObject.FileModificationList
$filedeletionlist = $SettingsObject.FileDeletionList
$fileoutput = $SettingsObject.FileOutput
$filelog = $SettingsObject.FileLog
$regexURL = "^http"
$regexchannelinfoline = "^#EXTINF"
$resultfile =""
$hmodification = [ordered]@{}
$hmodificationprocessed = @{}
$hdeletion = @{}
$hdeletionprocessed = @{}
[int]$errorqty = 0


###########################
# FOR EMAIL CONFIGURATION
#$From = "hadavedube@gmail.com"
$From = $SettingsObject.EmailSender
$To = $SettingsObject.EmailRecipient
$Attachment = $filelog
$Subject = $SettingsObject.EmailSubject
$Body = $SettingsObject.EmailBody
$SMTPServer = $SettingsObject.EmailSMTPServer
$SMTPPort = $SettingsObject.EmailSMTPPort
$mailboxpassword = $SettingsObject.EmailAccountPW
###########################

$sendemail = $false
if($SMTPServer -ne ""){
    $sendemail = $true    
}

$debug = $true

# 0- we delete the previous LOG file
Remove-Item $filelog

function myerrortrap{
    param($errorlevel, $info)

    $global:errorqty++
    $ErrorMessage = $_.Exception.Message
    if($ErrorMessage -ne $null) {
        $mydatetime = Get-Date -Format "yyyy/MM/dd HH:mm" 
        "[" + $mydatetime + "] " + "[" +$errorlevel + "] " + $info + "`r`n" + $ErrorMessage + "`r`n" | Out-File $filelog -Append
    }
}

# 1- Build the hash table for channel to customize
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


# 2- Build the Hash table for Channel to remove
if ($debug) {
    Write-Host "****************************************************"
    Write-Host "***** BUILD THE HASH TABLE FOR DELETIONS TO DO *****"
    Write-Host "****************************************************"
}
foreach($line in Get-Content $filedeletionlist) {
    # we add the custom channel into the hash table
    $Hdeletion.Add($line, "to delete")
}

# 2- Process the Replacement actions
if ($debug) {
    Write-Host "*************************************"
    Write-Host "***** PROCESS THE MODIFICATIONS *****"
    Write-Host "*************************************"
}
$resultfile = ""
foreach($line in Get-Content $fileoriginal) {
    #Write-Host "ligne:"$line
    
    # check if we are reading the line containing the Channel URL or not (Its my "key" to find channel into all files)
    if($line -match $regexURL){
        # we are on the line containing the channel URL

        #Write-Host "ChannelInfo:"$channelinfos
        #Write-Host "ChannelURL:"$line
        #Write-Host
        # $resultfile = $resultfile + $channelinfos + "`r`n" + $line + "`r`n"

        # check if this channel must be overwritten by my customs infos
        $custominfo = $hmodification["$line"]
        if ($custominfo){
            # Channel URL has been found in my Custom Info File
            $infotouse = $custominfo
            if ($debug) {
                Write-Host "Trouvé"
                Write-Host "CustomInfo:"$custominfo
                Write-Host "URL:"$line
            }
            
            # add the channel into the HPROCESSED hash table to indicate that this channel has already been considered in the "merge process"
            Try{
                $hmodificationprocessed.Add($line, $custominfo)
            }
            Catch{
                myerrortrap -errorlevel "ERROR" -info "Ajout dans htable modificationprocessed"
                
            }

        }
        else{
            # Channel URL not found in my Custom info File.  So we keep the original value
            #if ($debug) {Write-Host "Non - Trouvé"}
            $infotouse = $channelinfos
        }

        # check if the channel is in the file for channel to remove
        $todelete = $hdeletion["$line"]
        if(!$todelete){
            # Channel not found into the filedeletion.. so channel must be kept
            $resultfile = $resultfile + $infotouse + "`r`n" + $line + "`r`n"
        }
        else{
            if ($debug) {Write-Host "Channel supprimé:"$line}
            # we save the channel in the HDELETIONPROCESSED to know this entry has been processed
            Try{
                $hdeletionprocessed.Add($line, "done")
            }
            Catch{
                myerrortrap -errorlevel "ERROR" -info "Ajout dans htable deletionprocessed"
                
            }
        }
        
    }
    else{
        # we are on the line listing channel's informations
        if($line -match $regexchannelinfoline){
            $channelinfos = $line
        }
        else {
            # we must simply transfer that line "as is" to the new file
            $resultfile = $resultfile + $line + "`r`n"
        }
        
    }
}


# 3- ADD custom URL that has not been processed yet.
# we must parse the H table to check which custom channel has not been processed yet.  And add them "as is" at the end of the file
if ($debug) {
    Write-Host "********************************************"
    Write-Host "***** ADD CUSTOM URL NOT PROCESSED YET *****"
    Write-Host "********************************************"
}
$hmodification.Keys | ForEach-Object {
    $custominfo = $hmodificationprocessed["$_"]
    if (!$custominfo){
        # we did not find the channell... so we add this channel 
        $resultfile = $resultfile + $hmodification[$_] + "`r`n" + $_ +  "`r`n"
    } 
} 


# 4- Add summary info at the end of the Executionlog file
"Qty of errors during Execution: " + $errorqty + "`r`n" | Out-File $filelog -Append

# 5- write summary results into the executionlog File
if ($debug) {
    Write-Host "****************************************************************************"
    Write-Host "***** DETECT CHANNEL REQUESTED TO BE DELETED, BUT NOT EXISTING ANYMORE *****"
    Write-Host "****************************************************************************"
}
$hdeletion.Keys | ForEach-Object {
    $hasbeendeleted = $hdeletionprocessed["$_"]
    if (!$hasbeendeleted){
        # we did not find this channel to delete.  So we log it
        "Channel deletion - this channel has not been found in the original file:" + "`r`n" + $_ | Out-File $filelog -Append
    } 
} 

# 6- write the file content into a physical file
if ($debug) {
    Write-Host "*************************"
    Write-Host "***** SAVE THE FILE *****"
    Write-Host "*************************"
}
#$resultfile | Out-File -Encoding UTF8NoBOM $fileoutput
# use this method to save the file to make sure will be UTF (wihoutbom)
[System.IO.File]::WriteAllLines($fileoutput, $resultfile)
$filelog.dispose


# 7- Send the ExecutionLog by email
if ($debug) {
    Write-Host "*************************"
    Write-Host "***** SEND EMAIL    *****"
    Write-Host "*************************"
}

if ($sendemail){
    Try {
        $msg = new-object Net.Mail.MailMessage 
        $SMTP = new-object Net.Mail.SmtpClient($SMTPServer) 
        $msg.From = $From
        $msg.To.add($To)
        $msg.Subject = $Subject
        $msg.Body = $Body
        $msg.Attachments.Add($Attachment)
        $SMTP.Port = 587
        $SMTP.EnableSsl = $true
        $SMTP.Credentials = New-Object System.Net.NetworkCredential("$from", "$mailboxpassword"); 
        $smtp.Send($msg)
        $smtp.Dispose()   # important to release handle on the executionLog file
        $msg.Dispose()    # important to release handle on the executionLog file
    }
    Catch{
        myerrortrap -errorlevel "ERROR" -info "Envoi du email"
        $smtp.Dispose()   # important to release handle on the executionLog file
        $msg.Dispose()    # important to release handle on the executionLog file
    }
}