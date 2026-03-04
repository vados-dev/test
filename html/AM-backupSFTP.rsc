#!rsc by Vados
# RouterOS script: AM-backupSFTP
# Script comment: Create and upload backup and config file
# Copyright (c) 2005-2026 Vados <vados@vados.ru>
#
#
# provides: backup-script, order=50
# requires RouterOS, version=7.17
# requires device-mode, fetch
:local ExitOK false;
:onerror Err {
  :global GlobalConfReady; :global GlobalFuncReady;
  :retry { :if ($GlobalConfReady != true || $GlobalFuncReady != true) \
      do={ :error ("Global configs or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Domain;
  :global DeviceInfo;
  :global IfThenElse;
  :global Identity;
  :global checkRunJob;
  :global CleanName;
  :global FormatLine;
  :global HumanReadableNum;
  :global LogPrint;
  :global RandomDelay;
  :global MkDir;
  :global RmDir;
  :global RmFile;
  :global MiniDateTimeStamp;
  :global OSVersion;
  :global devBoardName;
  :global WaitForFile;

  :global BackupUploadUrl;
  :global BackupUploadPass;
  :global BackupUploadUser;
  :global BackupSendBinary;
  :global BackupSendExport;
  :global BackupSendGlobalConfig;
  :global BackupSendScripts;
  :global PackagesUpdateBackupFailure;
  :global BackupRmLocal;
  :global BackupLocalRoot;
  :global BackupEncrypt;
  :global BackupPassword;
  :global BackupRandomDelay;
  
  :global BackupSens;
  :global BackupGeneral;
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

  :if ($BackupSendBinary != true && $BackupSendExport != true) do={
    $LogPrint error $ScriptName ("Configured to send neither backup nor config export.");
    :set ExitOK true; :error false;
  }

  :if ([ $checkRunJob $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

  # filename based on identity
  :local dateTimeStampFix [$MiniDateTimeStamp];
  :local DirName ($Identity . "-" . $dateTimeStampFix);
  #:local DirName ($BackupLocalRoot . "/" $ScriptName);
  :local FilePref [ $CleanName ($Identity . "-") ];
  :if ($BackupLocalRoot = "") do={
    $LogPrint warning $ScriptName ("\n\$BackupLocalRoot is not set! I set \$BackupRmLocal to true!" . $Err);
    :set $BackupRmLocal true;
    $LogPrint debug $ScriptName ("\n\$DirName = " . $DirName);
  } else={
    :set $DirName ($BackupLocalRoot . "/" . $DirName);
    $LogPrint debug $ScriptName ("\n\$DirName = " . $DirName);
  }
  :local FileName "undefined";
  :local FilePath "undefined";
  :local expScript "undefined";
  :local BackupFile "none";
  :local ExportFile "none";
  :local ConfigFile "none";
  :local ExportScript "none";
  :local Failed 0;

  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $ScriptName ("Failed creating directory!");
    :set ExitOK true;
    :error false;
  }
  # binary backup
  :if ($BackupSendBinary = true) do={
    :set FileName [ $CleanName ($FilePref . "BinaryBackup") ];
    :set FilePath ($DirName . "/" . $FileName);
    if ($BackupEncrypt = true) do={
       /system/backup/save encryption=aes-sha256 name=$FilePath password=$BackupPassword;
    } else={
       /system/backup/save dont-encrypt=yes name=$FilePath;
    }
      $WaitForFile ($FilePath . ".backup");
      :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".backup") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".backup");
      :set BackupFile [ /file/get ($FilePath . ".backup") ];
      :set ($BackupFile->"name") ($FileName . ".backup");
    } do={
      $LogPrint error $ScriptName ("\nUploading backup file " . $FileName . ".backup failed: " . $Err);
      :set BackupFile "failed";
      :set Failed 1;
    }
    :if ($BackupRmLocal = true) do={$RmFile ($FilePath . ".backup")}
    :set FileName "undefined";
    :set FilePath "undefined";
  }

  # create configuration export
  :if ($BackupSendExport = true) do={
    :set FileName [ $CleanName ($FilePref . "Export") ];
    :set FilePath ($DirName . "/" . $FileName);
    if ($BackupSens = true) do={
    /export terse hide-sensitive file=$FilePath;
    } else={
    /export terse show-sensitive file=$FilePath;
    }
    $WaitForFile ($FilePath . ".rsc");
    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".rsc") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".rsc");
      :set ExportFile [ /file/get ($FilePath . ".rsc") ];
      :set ($ExportFile->"name") ($FileName . ".rsc");
    } do={
      $LogPrint error $ScriptName ("Uploading configuration export failed: " . $Err);
      :set ExportFile "failed";
      :set Failed 1;
    }
    :if ($BackupRmLocal = true) do={$RmFile ($FilePath . ".rsc")}
    :set FileName "undefined";
    :set FilePath "undefined";
  }

  # Amster-GlobalConfig
  :if ($BackupSendGlobalConfig = true) do={
    # Do *NOT* use '/file/add ...' here, as it is limited to 4095 bytes!
    :set FileName [ $CleanName ($FilePref . "GlobalConfig") ];
    :set FilePath ($DirName . "/" . $FileName);
    :execute script={ :put [ /system/script/get Amster-GlobalConfig source ]; } \
        file=($FilePath . ".conf\00");
    $WaitForFile ($FilePath . ".conf");
    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".conf") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".conf");
      :set ConfigFile [ /file/get ($FilePath . ".conf") ];
      :set ($ConfigFile->"name") ($FileName . ".conf");
    } do={
      $LogPrint error $ScriptName ("Uploading Amster-GlobalConfig failed: " . $Err);
      :set ConfigFile "failed";
      :set Failed 1;
    }
    :if ($BackupRmLocal = true) do={$RmFile ($FilePath . ".conf")}
    :set FileName "undefined";
    :set FilePath "undefined";
  }

  # Export Scripts  
  :if ($BackupSendScripts = true) do={
    :foreach expScript in=([ /system/script/find where name~"Amster-GlobalConf*" ]) do={
    # Do *NOT* use '/file/add ...' here, as it is limited to 4095 bytes!
    :set FileName [ $CleanName ($FilePref . [ /system/script/get $expScript name ]) ];
    :set FilePath ($DirName . "/" . $FileName . ".rsc\00");
    :execute script={ :put [ /system/script/get $FileName source ]; } \
        file=($FilePath . ".rsc\00");
    $WaitForFile ($FilePath . ".rsc");
    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".rsc") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".rsc");
      :set ExportScript [ /file/get ($FilePath . ".rsc") ];
      :set ($ExportScript->"name") ($FileName . ".rsc");
    } do={
      $LogPrint error $ScriptName ("Uploading " . $ExportScript . " failed!" . $Err);
      :set ExportScript "failed";
      :set Failed 1;
    }
    :if ($BackupRmLocal = true) do={$RmFile ($FilePath . ".rsc")}
    :set FileName "undefined";
    :set FilePath "undefined";
    :set ExportScript "undefined";
    }
  }

  :local FileInfo do={
    :local Name $1;
    :local File $2;
    :global FormatLine;
    :global HumanReadableNum;
    :global IfThenElse;
    :return \
      [ $IfThenElse ([ :typeof $File ] = "array") \
        ($Name . ":\n" . [ $FormatLine "    name" ($File->"name") ] . "\n" . \
          [ $FormatLine "    size" ([ $HumanReadableNum ($File->"size") 1024 ] . "B") ]) \
        [ $FormatLine $Name $File ] ];
  }
  $SendNotification2 ({ origin=$ScriptName; \
    subject=[ $IfThenElse ($Failed > 0) \
      ([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Backup & Config upload with failure") \
      ([ $SymbolForNotification "floppy-disk,arrow-up" ] . "Backup & Config upload") ]; \
    message=("Backup and config export upload for " . $Identity . ".\n\n" . \
      [ $DeviceInfo ] . "\n\n" . \
      [ $FileInfo "Backup file" $BackupFile ] . "\n" . \
      [ $FileInfo "Export file" $ExportFile ] . "\n" . \
      [ $FileInfo "Config file" $ConfigFile ]); silent=true });
  :if ($Failed = 1) do={
    :set PackagesUpdateBackupFailure true;
  }
  :if ($BackupRmLocal = true) do={$RmDir $DirName}
} do={:global ExitError; $ExitError $ExitOK [ :jobname ] $Err}
