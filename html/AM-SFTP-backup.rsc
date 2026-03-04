#!rsc by Vados
# RouterOS script: AM-SFTP-backup
# Script comment: BackUp via /tool fetch SFTP
# Copyright (c) 2005-2026 Vados <vados@vados.ru>
#
#
#
# requires RouterOS, version=7.21
# requires device-mode, fetch, scheduler
#
# Based on:
# https://forum.mikrotik.com/viewtopic.php?t=159432
# https://forum.mikrotik.com/viewtopic.php?p=858564#p858564
#
### Info Log Action
# $stage (string) selects action text
# $msg (string) additional message, usually the backup stage or filename
# $error (bool) (optional) creates error log instead of info if 'true'
:local ExitOK false;
:onerror Err {
  :global GlobalConfReady; :global GlobalFuncReady;
  :retry { :if ($GlobalConfReady != true || $GlobalFuncReady != true) \
      do={ :error ("Global configs or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

:global Identity;
:global checkRunJob;
:global LogPrint;
:global RandomDelay;
:global MkDir;
:global RmDir;
:global RmFile;
:global FileGet;
:global WaitForFile;
:global MiniDateTimeStamp;
:global OSVersion;
:global devBoardName;
:global BackupRandomDelay;
:global BackupUploadUrl;
:global BackupUploadUser;
:global BackupUploadPass;
:global BackupRmLocal;
:global BackupSendBinary;
:global BackupLocalRoot;
:global BackupEncrypt;
:global BackupPassword;
:global BackupSens;
:global BackupSendGlobalConfig;
:global BackupUser;
:global BackupLicense;
:global BackupSshKeys;
:global BackupCerts;
:global BackupCertsPasswd;
:global BackupUserMan;
:global BackupDude;
:global BackupUserList;
:global SendTelegram;
:global SendNotification;
### End Configuration
  
  :if ([ :len [ /system/scheduler/find where name="BackupEveryDaySFTP" ] ] = 0) do={
    $LogPrint warning $ScriptName ("SystemScheduler NOT SET!");
    /system/scheduler/add name=$ScriptName on-event="/system/script { run $ScriptName; }" comment="Backup Every Day on SFTP" interval=1w policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon; start-time=startup; 
  }

  :if ([ $checkRunJob $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

:local dateTimeStampFix [$MiniDateTimeStamp];
:local bkpDirName ($Identity . "-" . $dateTimeStampFix);
:local BkpPath;
:local FilePref ($Identity . "-");

:if ($BackupLocalRoot = "") do={
    $LogPrint warning $ScriptName ("\n\$BackupLocalRoot is not set! I set \$BackupRmLocal to true!" . $Err);
    :set $BackupRmLocal true;
:do {
$MkDir ($bkpDirName);
:set BkpPath $bkpDirName;
   } on-error={$LogPrint error $ScriptName ("ERROR Create Directory $BkpPath" . $Err);}
} else={
:do {
$MkDir ($BackupLocalRoot . "/" . $bkpDirName);
:set BkpPath ($BackupLocalRoot . "/" . $bkpDirName);
   } on-error={$LogPrint error $ScriptName ("ERROR Create Directories $BkpPath" . $Err);}
}
:local locFilePref ($BkpPath . "/" . $FilePref);

$LogPrint warning $ScriptName ("\$locFilePref = $locFilePref" . $Err);

:local remFilePref ($FilePref . $dateTimeStampFix . "-");
#($bkpDirName . "/" . $BkpFilePrefix);
#:if ($SFTPpath != "") do={
#  :set remFilePref ($SFTPpath . "/" . $remFilePref);
#} else={:set remFilePref ("/" . $remFilePref)}

$LogPrint warning $ScriptName ("\$remFilePref = $remFilePref");

### Process local filename to create remote filename
### Return array for file array
## Strips path separator '/' from local file name and replaces with '_'
# 'lfile' (string) the local filename
# 'lpref' (string) the local prefix to strip from start of lfile (if present)
# 'rpref' (string) remote prefix to prepend to remote filename
# 'clear' (bool) whether to delete local file after uploading
:local dofnames do={
  :local rfile "";
  :local rfilef "";
  # Strip Local Prefix if present
  if ([:find $lfile $lpref -1] = 0) do={
    :set rfile [:pick $lfile [:len $lpref] [:len $lfile]];
  } else={
    :set rfile $lfile;
  }
  $LogPrint warning $ScriptName ("\n\$rfile = $rfile");
  # Convert / to _
  :for i from=0 to=([:len $rfile] - 1) do={
    :local char [:pick $rfile $i];
    :if ($char = "/") do={
      :set $char "_";
    }
    :set rfilef ($rfilef . $char);
    $LogPrint warning $ScriptName ("\n\$rfilef = " . $rfilef);
    $LogPrint warning $ScriptName ("\n\$char = " . $char);
  }
  # Prepend Remote Prefix
  :set rfile ($rpref . $rfilef);
  $LogPrint warning $ScriptName ("\n\$rfile = " . $rfile);
  $LogPrint warning $ScriptName ("\n\$rpref = " . $rpref);
  $LogPrint warning $ScriptName ("\n\$rfilef = " . $rfilef);
  $LogPrint warning $ScriptName ("\n\$lfile = " . $lfile);
  $LogPrint warning $ScriptName ("\n\$clear = " . $clear);
  # Return array
  :return {lfile=$lfile; rfile=$rfile; clear=$clear};
}

### Delete Local File(s)
# $lfile (string) local file to be deleted
:local dodelete do={
  :global BackupRmLocal;
  :global RmFile;
  :global LogPrint;
  if ($BackupRmLocal = true) do={
    :do {
      $RmFile $lfile;
    } on-error={
      $LogPrint error $ScriptName ("Error remove file " . $lfile . "." . $Err);
    }
#  if ([:len [/file find where name="$lfile"]] > 0) do={
#    /file remove [find where name="$lfile"];
  }
}

:local filesa [:toarray ""];
:local cfilename "";
:local lfilename "";
:local rfilename "";

### Binary Backup
if ($BackupSendBinary = true) do={
  :set cfilename ($locFilePref . "backup");
  :set lfilename ($cfilename . ".backup");
  if ($BackupEncrypt = false) do={
    :do {
      /system backup save dont-encrypt=yes name=$cfilename;
    } on-error={$LogPrint error $ScriptName ("Binary backup save " .$cfilename . " dont-encrypted failed" . $Err);}
  } else={
    :do {
      /system backup save encryption=aes-sha256 name=$cfilename password=$BackupPassword;
    } on-error={$LogPrint error $ScriptName ("Binary backup save " .$cfilename . " encrypted failed" . $Err);}
  }
  :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfilename lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
}

### Generic Export
if ($BackupSendGlobalConfig = true) do={
  :set cfilename ($locFilePref . "export");
  :set lfilename ($cfilename . ".rsc");
  if (($OSVersion = "6" and $BackupSens = true) or ($OSVersion = "7" and $BackupSens = false)) do={
    :do {
      /export compact file=$cfilename;
    } on-error={$LogPrint error $ScriptName ("Export Global compact " .$cfilename . " failed" . $Err);}
  } else={
    if ($OSVersion = "6") do={
      $LogPrint info $ScriptName ("Start Global compact if OSVersion = 6 (hide-sensitive)");
      :do {
        /export compact hide-sensitive file=$cfilename;
      } on-error={$LogPrint error $ScriptName ("Export Global compact if OSVersion = 6 (hide-sensitive) " .$cfilename . " failed" . $Err);}
    } else={
      $LogPrint info $ScriptName ("Start Global compact");
      :do {
        if ($BackupSens = true) do={
        /export compact hide-sensitive file=$cfilename;
        } else={
          /export compact show-sensitive file=$cfilename;
        }
      } on-error={$LogPrint error $ScriptName ("Export Global compact (\$BackupSens = " . $BackupSens . ") " .$cfilename . " failed" . $Err);}
    }
  }
  :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfilename lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
}

### User Export
if ($BackupUser = true) do={
  :set cfilename ($locFilePref . "user");
  :set lfilename ($cfilename . ".rsc");
  if (($OSVersion = "6" and $BackupSens = true) or ($OSVersion = "7" and $BackupSens = false)) do={
    :do {
      /user export compact file=$cfilename;
      } on-error={$LogPrint error $ScriptName ("User Export " . $cfilename . " failed" . $Err);}
  } else={
    if ($OSVersion = "6") do={
      $LogPrint info $ScriptName ("User Export (hide-sensitive)" . $lfilename);
      :do {
        /user export compact hide-sensitive file=$cfilename;
      } on-error={$LogPrint error $ScriptName ("User Export (hide-sensitive) " .$cfilename . " failed" . $Err);}
    } else={
      $LogPrint info $ScriptName ("User Export (show-sensitive) " . $lfilename);
      :do {
        /user export compact show-sensitive file=$cfilename;
      } on-error={$LogPrint error $ScriptName ("User Export (show-sensitive) " .$cfilename . " failed" . $Err);}
    }
  }
  :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfilename lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
}

### License Export
if ($BackupLicense = true and $devBoardName != "CHR") do={
  :set lfilename ([/system license get software-id] . ".key");
  :set rfilename ($remFilePref . "license.key");
  :do {
    /system license output;
  } on-error={$LogPrint error $ScriptName ("Backup " . $lfilename . " failed" . $Err);}
  :set ($filesa->([:len $filesa])) {lfile=$lfilename; rfile=$rfilename; clear=$BackupRmLocal};
}

### SSH Keys
if ($BackupSshKeys = true) do={
  :set cfilename ($locFilePref . "host-key");
  :do {
    /ip ssh export-host-key key-file-prefix=$cfilename;
  } on-error={$LogPrint error $ScriptName ("Backup SSH Keys " . $cfilename . " failed" . $Err);}
  :foreach lfile in=[/file find where name~"^$cfilename"] do={
    :set ($filesa->([:len $filesa])) [$dofnames lfile=[/file get $lfile name] lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
  }
}

### Certificates
if ($BackupCerts = true) do={
  :foreach cert in=[/certificate find] do={
    :local certname [/certificate get $cert name];
    :local cfilename ($locFilePref . "cert-" . $certname);
    :do {
      /certificate export-certificate $cert file-name=$cfilename \
                                      type=pkcs12 export-passphrase=$BackupCertsPasswd;
    } on-error={$LogPrint error $ScriptName ("Backup Certificate " . $cfilename . " failed" . $Err);}
    :set ($filesa->([:len $filesa])) [$dofnames lfile=($cfilename . ".p12") lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
  }
}

# User-Manager
if ($BackupUserMan = true) do={
  :set cfilename ($locFilePref . "user-manager");
  :set lfilename ($cfilename . ".umb");
  :do {
    $dodelete lfile=$lfilename;
  } on-error={$LogPrint error $ScriptName ("User-Manager " . $lfilename . " clear failed" . $Err);}
  if ($OSVersion = "6") do={
    :do {
      /tool user-manager database save name=$cfilename;
    } on-error={$LogPrint error $ScriptName ("Backup User-Manager " . $cfilename . " failed" . $Err);}
  }
  if ($OSVersion = "7") do={
    :do {
      /user-manager database save name=$cfilename;
    } on-error={$LogPrint error $ScriptName ("Backup User-Manager " . $cfilename . " failed" . $Err);}
  }
  :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfilename lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
}

# The Dude
if ($BackupDude = true) do={
  :set lfilename ($locFilePref . "the-dude.db");
  :do {
    $dodelete lfile=$lfilename;
  } on-error={$LogPrint error $ScriptName ("Dude " . $lfilename . " clear failed" . $Err);}
  $dolog stage="create" msg=$logstage;
  :do {
    /dude export-db backup-file=$lfilename;
  } on-error={$LogPrint error $ScriptName ("Backup Dude " . $lfilename . " failed" . $Err);}
  :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfilename lpref=$locFilePref rpref=$remFilePref clear=$BackupRmLocal];
}

# User File List
if ([:len $BackupUserList] > 0) do={
  :foreach lfile in=[:toarray $BackupUserList] do={
    :set ($filesa->([:len $filesa])) [$dofnames lfile=$lfile lpref=$locFilePref rpref=$remFilePref clear=false];
  }
}

# Process Files Array
:local lfile "";
:local rfile "";
:local clear true;
/delay 10s;
:foreach a in=$filesa do={
  :set lfile ($a->"lfile");
  :set rfile ($a->"rfile");
  :set clear ($a->"clear");
  if ([:len [/file find where name="$lfile"]] > 0) do={
    $LogPrint info $ScriptName ("Upload " . $lfile . " AS " . $rfile);
    :do {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $rfile) \
          user=$BackupUploadUser password=$BackupUploadPass src-path=$lfile;
#      /tool fetch address=$SFTPsrv user=$SFTPusr password=$SFTPpasswd src-path=$lfile dst-path=$rfile upload=yes mode=sftp;
    } on-error={$LogPrint error $ScriptName ($rfile . $Err);}
    if ($clear = true) do={
      $LogPrint info $ScriptName ("Delete " . $lfile)
      :do {
        :if ($BackupRmLocal = true) do={$RmFile $lfile}
      } on-error={$LogPrint error $ScriptName ($lfile . $Err);}
    }
  }
}
:if (!$ExitError && $BackupRmLocal = true) do={$RmDir $BkpPath}
} do={:global ExitError; $ExitError $ExitOK [ :jobname ] $Err}
