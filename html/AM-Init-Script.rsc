#!rsc by Vados
# RouterOS script: AM-Init
# Script comment: Initial Script for setup routeros scrypt system
# Copyright (c) 2005-2026 Vados <vados@vados.ru>
#
#
# requires RouterOS, version=7.19
# requires device-mode, fetch
#
# Additional commands:
# /system/script/set source=[ :tocrlf [ get $ScriptName source ] ] $ScriptName;
#
#:global GlobalEnvRemove true; /system/script {run Amster-GlobalEnvRemove; };
#:delay 1s;
#:global ReloadGlobal true; 

:global GlobalScriptsUrl "https://ros.vados.ru/";
:global defOwner "vados";
:global InitFirstRun;

:set InitFirstRun do={
    :global GlobalScriptsUrl;
    :global defOwner;
    #:global ParseKeyValueStore;
    #:local AmUpdCRLF true;
    #:local IfThenElse;
    #:set IfThenElse do={:if ([ :tostr $1 ] = "true" || [ :tobool $1 ] = true) do={:return $2}; :return $3}
    #/certificate/settings/set builtin-trust-store=fetch;
    #/tool/fetch "$scriptsUrl/certs/Root-YE.pem" dst-path="root-ye.pem";
    #/certificate/import file-name="root-ye.pem" passphrase="";
    # For basic verification we rename the certificate and print it by fingerprint. Make sure exactly this one certificate ("Root-YE") is shown.
    #/certificate/set name="Root-YE" [ find where common-name="Root YE" ];
    #/certificate/print proplist=name,fingerprint where fingerprint="e14ffcad5b0025731006caa43a121a22d8e9700f4fb9cf852f02a708aa5d5666";
    #:log info "\nGlobalScriptsUrl = $GlobalScriptsUrl";
    :local Scripts {
        "Amster-GlobalConfig"
        "Amster-GlobalFunc";
#        "Amster-SFTP-backup"
#        "Amster-BkpEmail-and-upd";
    };
#    /system/script/set owner=($ScriptVal->"name") \
#    source=[ $IfThenElse ($ScriptUpdatesCRLF = true) $SourceCRLF $SourceNew ] $Script;
    :foreach Script in=$Scripts do={
        :put "Installing $Script...";
        /system/script/remove [ find where name=$Script ];
        /system/script/add name=$Script owner=$defOwner source=([ /tool/fetch ("$GlobalScriptsUrl" . $Script . ".rsc") output=user as-value ]->"data");
        /system/script/set source=[ :tocrlf [ get $Script source ] ] $Script;
    };
    /system/script { run Amster-GlobalConfig; run Amster-GlobalFunc; }
}
:global InitUpdRun;
:set InitUpdRun do={
    #:local UpdScript [ :tostr $1 ];
    #:global ParseKeyValueStore;
    :global GlobalScriptsUrl;
    :global defOwner;
    :local Scripts {
#        "Amster-GlobalConfig"
#        "Amster-GlobalFunc"
#        "Amster-GlobalRemove"
        "Amster-backup-SFTP"
        "Amster-SFTP-backup"
        "Amster-BkpEmail-and-upd"
        "Amster-TG-Bot"
        "Amster-TG-Notification";
        };
    :foreach Script in=$Scripts do={
        :put "updating $Script...";
        /system/script/remove [ find where name=$Script ];
        /system/script/add name=$Script owner=$defOwner source=([ /tool/fetch ("$GlobalScriptsUrl" . $Script . ".rsc") output=user as-value ]->"data");
        /system/script/set source=[ :tocrlf [ get $Script source ] ] $Script;
    };
#    /system/script/add name=$Script owner=$AmOwner source=([ /tool/fetch check-certificate=yes-without-crl ("$GlobalScriptsUrl" . $Script . ".rsc") output=user as-value ]->"data"); };
}

$InitFirstRun;
#$InitUpdRun;

#$setUpdExist;
#:global setUpdExist;
#:global ParseKeyValueStore;
#:set setUpdExist do={
#:do {
#:global ParseKeyValueStore;
#  :foreach Script in=[ /system/script/find where source~"^#!rsc by Vados\r?\n#comment=*" ] do={
#    :local ScriptVal [ /system/script/get $Script ];
#    :local ScriptInfo [ $ParseKeyValueStore ($ScriptVal->"#comment") ];
#    :local scriptName ($ScriptVal->"name");
#:log warning ("\n\$scriptName = ". $scriptName);
#: log warning ("\n\$ScriptInfo = ". $ScriptInfo);
#  }
#} on-error={}
#}
#$name;$owner;$policy;$dont-require-permissions;$last-started;$run-count;$source;$invalid;$comment;$.id;$.nextid;$.dead;$.about;
#;(evl / (evl /docommand=;(evl / (evl /foreachcounter=$Script;do=;(evl / (evl /localname=$ScriptVal;value=(evl (evl /system/script/getnumber=$Script))) (evl /localname=$ScriptInfo;value=(evl (<%% $ParseKeyValueStore (> $ParseKeyValueStore);(-> $ScriptVal comment)))) (evl /localname=$scriptName) (evl /setname=$scriptName;value=(-> #$ScriptVal name)) (evl /log/errormessage=(. 
# $ ScriptInfo =  $ScriptInfo)));in=(evl (evl /system/script/findwhere=$name;$owner;$policy;$dont-require-permissions;$last-started;$run-count;$source;$invalid;$comment;$.id;$.nextid;$.dead;$.about;(~ $source (. ^#!rsc by Vados 
# ? 
#));5))));on-error=;(evl /)))
