#!rsc by Vados
# RouterOS script: AM-setup
# Script comment: Script for setup routeros scrypt system
# Copyright (c) 2005-2026 Vados <vados@vados.ru>
#
#
# requires RouterOS, version=7.19
# requires device-mode, fetch
#
# :local ScriptName [ :jobname ];
# Additional commands:
#
# For scripts:
#:global NewScript "script_name"; 
#:global GlobalScriptsUrl "https://ros.vados.ru/";
#/system/script/add name=$NewScript owner=$NewScript source=([/tool/fetch check-certificate=yes-without-crl ($GlobalScriptsUrl . $ScriptAdd . ".rsc") output=user as-value ]->"data");
#:global NewScript (a);
#:global ScriptInstallUpdate; $ScriptInstallUpdate;
#
# For run from terminal:
#/system/script/add name=AM-setup owner=AM-Setup source=([/tool/fetch check-certificate=yes-without-crl "https://ros.vados.ru/AM-setup.rsc" output=user as-value ]->"data");
#
#:foreach Script in=[ /system/script/find where source~"^#!rsc by Vados" ] do={
#  if ($ScriptUpdatesCRLF = true) do={
#   /system/script/set source=[ :tocrlf [ get $Script source ] ] $Script;
#  } else={
#   /system/script/set source=[ :tolf [ get $Script source ] ] $Script;
#  }
#}
# /import verbose=no $ScriptName
:global SetupScript [ :jobname ];
:global RemoveMe;
:global InitSetup true;
:global tmpfs true;

{
  :local RmMe [:tobool $1];

  :global GlobalScriptsUrl;
  :global SetupScript;
  :global RemoveMe;
  :global InitSetup;
  :global tmpfs;
    
  :local CertCommonName "Root YE";
  :local CertFileName "Root-YE.pem";
  :local CertFingerprint "e14ffcad5b0025731006caa43a121a22d8e9700f4fb9cf852f02a708aa5d5666";

  :if ($SetupScript = false) do={
    :global SetupScript "AM-setup";
  }
  :if ($RemoveMe != false) do={
    :set RemoveMe true;
  }

  :log warning ("\n\$GlobalScriptsUrl = " . $GlobalScriptsUrl);
  
  :local CertSettings [ /certificate/settings/get ];
  :if (!((($CertSettings->"builtin-trust-anchors") = "trusted" || \
          ($CertSettings->"builtin-trust-store") ~ "fetch" || \
          ($CertSettings->"builtin-trust-store") = "all") && \
         [ :len [ /certificate/builtin/find where common-name=$CertCommonName ] ] > 0)) do={
    :put "Importing certificate...";
    
    /tool/fetch ($GlobalScriptsUrl . "certs/" . $CertFileName) dst-path=$CertFileName as-value;
    :delay 1s;
    /certificate/import file-name=$CertFileName passphrase="";
    :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] != 1) do={
      :error "Something is wrong with your certificates!";
    };
    :delay 1s;
  };
  :put "Thr tmpfs variable is true. Checking for tmpfs/scripts directory...";
  :if ($tmpfs = true && [/file find name="tmpfs/scripts"] != "") do={
    :log debug ($0 . "Directory tmpfs/scripts exsist.");
    :return $true;
  } else={
    :log error ($0 . "Directory tmpfs/scripts does not exsist. Remove global variable tmpfs!");
    :global tmpfs (a);
    return false;
}
  :put "Renaming AM-GlobalConfig, if exists...";
  :local ConfOldName ("AM-GlobalConfig-" . [ /system/clock/get date ] . [ /system/clock/get time ] . ".rsc");
  /system/script/set name=$ConfOldName [ find where name="AM-GlobalConfig" ];
  :foreach Script in={ "AM-GlobalConfig"; "AM-GlobalFunc" } do={
    :put "Installing $Script...";
    /system/script/remove [ find where name=$Script ];
    /system/script/add name=$Script owner=$Script source=([ /tool/fetch check-certificate=yes-without-crl url=($GlobalScriptsUrl . $Script . ".rsc")  output=user as-value ]->"data");
    
    /system/script run $Script;
    :delay 2s;
  };

  :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] > 0) do={
    :put "Renaming certificate by its common-name...";
    :global CertificateNameByCN;
    $CertificateNameByCN $CertFingerprint;
  };

  :if ($RemoveMe = true) do={
    :put "Add Scheduler for remove this script...";
    :local OnEvent (":delay 30s;\n" . "/system/script/remove [ find where name=\"$SetupScript\" ];\n" . \
    ":delay 2s;\n" . "/system/scheduler/remove [ find where name=\"_RemoveSetup\" ];\n" . \
    ":delay 2s;\n" . ":global RemoveMe (a);\n");
    :local Comment "_RemoveSetup tmp scheduler for remove setup script.";
    /system/scheduler/add name="_RemoveSetup" comment=$Comment start-time=startup interval=30s on-event=$OnEvent;
      :log warning ($0 . "\nI've done everything, and now I'm tired... I'm leaving.\nThere will be an error below, this is normal.");
    }
    :delay 1;
    :put "Loading configuration and functions...";
    :do {      
      :global ScriptInstallUpdate; $ScriptInstallUpdate;
      :put "Normal removing temporary global environment variables.";
      :global SetupScript (a);
      :global InitSetup (a);
      :global RemoveMe (a);
    } on-error={
      :local ErrorMsg "Loading configuration and functions error!";
      :log error ($0 . $ErrorMsg . :error);
      :error $ErrorMsg;
    }
}
