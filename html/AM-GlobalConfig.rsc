#!rsc by Vados
# RouterOS script: AM-GlobalConfig
# Script comment: Global Config Script
# Copyright (c) 2007-2026 Vados <vados@vados.ru>
#
#
# Warning: Dont touch this line!
:global GlobalConfReady false;
#   \/    start edit
#
# Global Url For Amster scripts to fetch
# most be defined in Amster-Init-Script
:global GlobalScriptsUrl "https://ros.vados.ru/";
:global ScriptsUrlSuffix "";
:global CheckSumsVerify true;

:global ScriptUpdatesCRLF true;
:global CommentsInScripts true;

# Debug output:
:global PrintDebug true; #false;

# Debug output for specific script:
:set ($PrintDebugOverride->"AM-GlobalFunc") true;

# Debug logs
# Other actions (disk, email, remote or support) can be used as well.
# I do not recommend using echo - use debug output instead (https://rsc.eworm.de/main/DEBUG.html#debug-output).
#/system/logging/add topics=script,debug action=memory;

:global MikrotikUpgradeUrl "https://upgrade.mikrotik.com/routeros";
:global Domain "WORKGROUP";

:global EmailGeneralTo "vados@vados.ru"; #:global EmailGeneralCc "";

# $ScriptInstallUpdate mod/notification-telegram
:global TelegramTokenId "8390868324:AAG3_d1hfVR2M6pGAgDK6ZvhOe4J97nyopw";
:global TelegramChatId "-1003631309063"; #"454403445";
# Use this to send notifications to a specific topic in group.
#:global TelegramThreadId "30";
# Using telegram-chat you have to define trusted chat ids (not group ids!)
# or user names. Groups allow to chat with devices simultaneously.
:global TelegramChatIdsTrusted {
  "454403445"
  "-1003631309063"
  "-5124482807"
  "1087968824";
};
#  "-5294757340";

:global TelegramChatGroups "(all)";
#:global TelegramChatGroups "(all|home|office)";

:global NotificationFunctions {
  "email"
  "telegram";
};
# Toggle this to disable symbols in notifications.
:global NotificationsWithSymbols true;
:global TerminalColorOutput true;

:global DetectIpAddrDefault "https://ipv4.mikrotik.ovh/";
:global DetectIpAddrFallback "https://api.ipify.org/";

## Update channel. Possible values: stable, long-term, testing, development
:global updateChannel "stable";

# Script BackupAndUpdate mode, possible values: backup,
# updateOnce - Update once as "osnotify" and back "osnotify" mode (in terminal run :set OSUpdateMode updateOnce; $OSUpdateMode;).  
# osupdate - Update if available and creates backups before/after update (ignores `forceBackup`)
#               Set `forceBackup` to true to always create backups, even without updates
# osnotify - Set `forceBackup` to always create backups on every run
:global DevInfoIncludeIP true;
:global BackupAndUpdateMode "osnotify"

:global forceBackup true;
:global BackupPassword "Peskar55";

# SFTP Backup Variables
:global BackupRandomDelay 0;
:global BackupUploadUrl "sftp://amster.vados.ru/upload/";
:global BackupUploadUser $Identity;
:global BackupUploadPass "root.mnuc.backuper";

:global BackupSendBinary true;
:global BackupSendExport true;
:global BackupSendGlobalConfig true;
:global BackupSendScripts true;

# Remove local file after uploading if no errors
:global BackupRmLocal true;

# Local Backups Root Directory 
:global BackupLocalRoot "tmpfs";

# Encrypt Backup
:global BackupEncrypt true;

# Sensitive information in Backups
:global BackupSens true;

# User Export
:global BackupUser true;

# License Export (not for CHR, will silently skip)
:global BackupLicense false;

# SSH Keys
:global BackupSshKeys true;

# Certificate Export
:global BackupCerts true;

# Certificate Password
:global BackupCertsPasswd "";

# User-Manager Export
:global BackupUserMan false;

# The Dude Export
:global BackupDude false;

# User Files to export, comma-separated string or array of strings
# User Files are not removed on backup
# Any directory paths will be removed (/ -> _) on remote file
# Nonpresent files are silently skipped
:global BackupUserList "autosupout.rif,autosupout.old.rif";

# load functions and any custom scripts
#                    [ /system/script/find where name="global-config-overlay" ], \
#                    [ /system/script/find where name~"^global-config-overlay\\.d/." ]
#
#:foreach Script in=([ /system/script/find where name="Amster-TGglobalVars" ], [ /system/script/find where name="Amster-TGglobalFunc" ]) do={
#  :onerror Err {
#     /system/script/run $Script;
#     } do={
#       :log error ("Loading configuration from configs and functions" . [ /system/script/get $Script name ] . " failed: " . $Err);
#  }
#}
#:log info "\ndevMode = $devMode";
#:log info "\ndevRunning = $devRunning";
:foreach Script in=[ /system/script/find where source~"^#!rsc by Vados GlobalRUN\r?\n" ] do={
  :onerror Err {
    /system/script/run $Script;
       } do={
       :log error ("Run script " . [ /system/script/get $Script name ] . " width marker \" GlobalRUN\" failed: " . $Err);
  }
}

# signal we are ready
:set GlobalConfReady true;
:while ($GlobalConfReady != true) do={:delay 500ms};
