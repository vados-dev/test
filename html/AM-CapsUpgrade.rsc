#!rsc by Vados
# RouterOS script: AM-CapsUpgrade
# Script comment: 
#
#
# requires RouterOS, version=7.19
# requires device-mode, fetch, scheduler
:local ExitOK false;
:onerror Err {
  :global GlobalConfReady; :global GlobalFuncReady;
  :retry { :if ($GlobalConfReady != true || $GlobalFuncReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  # Helper function to log and put messages
  :global LogPrint;
  :local logput do={:log info $1; :put $1}
  :local installed [/system/package get routeros version];
  # Initiate Upgrade on outdated cAPs (old CAPs Manager)
  :if ([/system/package/find where name="wireless" disabled=no]) do={
    :put message="Old wireless driver detected";
      [:parse "/caps-man/remote-cap
        :local outdatedcaps [find where version!=$installed];
        :foreach i in=\$outdatedcaps do={
          \$logput (\"[INFO] Initiate Upgrade on \" . [get value-name=identity \$i]);
          upgrade numbers=\$i;
          :delay 120s;
          }
       "]
    }
  # Initiate Upgrade on outdated cAPs (new CAPs Manager)
  /interface/wifi/capsman/remote-cap/;
  :local outdatedWifiCaps [find where version!=$installed];
  :foreach i in=$outdatedWifiCaps do={
    $LogPrint info $ScriptName ("[INFO] Initiate Upgrade on " . [get value-name=identity $i]);
    upgrade numbers=$i;
    :delay 120s
    }
 }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}