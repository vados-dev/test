
#:local runningVer [:find [/system/resource/get version] "("];

:local runningChannel;
:local runningVersion;
:local ParseCustom;

:set ParseCustom do={
  :local Str [ :tostr $1 ];
  :local Start [:find [ $Str ] [$2]];
  :local End [ :tostr $3 ];
  :local Num [ :tonum $4 ];
  :local Return;

  :if ($Num = false) do={
:set Num [0];
}
:log warning [$Num];
:log warning ("'" . [$End . "'"];
  :local rest [:pick $Str ($Start+$Num) [:len $Str]]; 
  :if ($End = false) do={
  :set Return [:pick $Str $Num $Start];
  } else={
  :set End [:find $rest $End];
  :set Return [:pick $rest 0 $End];
  }
:return $Return;
}
  
:set runningChannel [$ParseCustom [/system/resource/get version] "(" ")" 1];
:log warning [$runningChannel];
:set runningVersion [$ParseCustom [/system/resource/get version] [:tostr " "]];
:log warning [$runningVersion];



#  :if ([:len $open] = 0) do={
#    :log error "$SMP Could not extract installed OS channel from version string: `$runningOsAndChannel`.";
#    :error "$SMP error, check logs";
#  }
#  :local rest [:pick $runningOsAndChannel ($open+1) [:len $runningOsAndChannel]];
#  :local close [:find $rest ")"];
#  :local channel [:pick $rest 0 $close];
#  :return $channel;
#}
#
#:log warning ("Waiting for one minute before continuing to the final step.");
#:delay 1m;

:local ipAddrDefault "https://ipv4.mikrotik.ovh/";
:local ipAddrFallback "https://api.ipify.org/";
:local publicIpAddress "not-detected";
:global getPubIp;
:set publicIpAddress [ $getPibIp $ipAddrDefault ];

:set getPubIp do={
    :local ipAddr $1;
    :local PubIpAddress "not-detected";
    :do {
#mode=https
      :set PubIpAddress ([/tool fetch https-method="get" mode="https" url=$ipAddrFallback output=user as-value]->"data");
:delay 5;
     } on-error={
     :log error ($error);
     :return false;
     }
      :log warning ("/nAddress = " . $Address);
      :set PubIpAddress ([:pick $Address 0 15]);
      :return $PubIpAddress;
:log warning ("ipAddr is " . $ipAddr);
}
:log warning ("ipAddrDefault is " . $ipAddrDefault);
:log warning ("ipAddrFallback is " . $ipAddrFallback);
:set publicIpAddress [ $getPubIp $ipAddrDefault ];
:log warning ("Public Ip Address is " . $publicIpAddress);

:local result true;
:do {
tool fetch url="https://1.1.1.1/dns-query\?name=mikrotik.ca%26type=A" output=file dst-path=mikrotik.ca.crt.pem http-header-field=accept:application/dns-json;
} on-error={:set result false}
# output=file dst-path=result \
:if ([$result] != false) do={
:log warning "TRUE";
/certificate/import name=mikrotik.ca.crt.pem file-name=mikrotik.ca.crt.pem passphrase="";
#  /ip dns set servers="" use-doh-server=https://1.1.1.1/dns-query verify-doh-cert=yes
} else={
:log warning "FALSE";
#  /ip dns set allow-remote-requests=yes servers=8.8.8.8 use-doh-server=https://dns.google/dns-query verify-doh-cert=no
}


:set Grep do={
  :local Input  ([ :tostr $1 ] . "\n");
  :local Pattern [ :tostr $2 ];
  :if ([ :typeof [ :find $Input $Pattern ] ] = "nil") do={:return []}
  :do {
    :local Line [ :pick $Input 0 [ :find $Input "\n" ] ];
    :if ([ :typeof [ :find $Line $Pattern ] ] = "num") do={:return $Line}
    :set Input [ :pick $Input ([ :find $Input "\n" ] + 1) [ :len $Input ] ];
  } while=([ :len $Input ] > 0);
  :return [];
}

#:foreach Script in=[ /system/script/find where source~"^#!rsc by Vados" ] do={
#:foreach Script in=[ /system/script/find where name="Amster-Backup-UpdateEmail" ] do={
#}

:set UpdateComments do={
  :global Grep;
  :local NewComment;

  :foreach Script in=[ /system/script/find where source~"^#!rsc by Vados" ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Source ($ScriptVal->"source");
    :local CommentLine [ $Grep $Source ("\23 Script comment: ") ];
    :if ([ :len $CommentLine ] = 0) do{
      $LogPrint warning $0 ("The search in script '" . $ScriptVal->"name" . "' for comment in script body, is not found result Ignoring!");
    } else={
        :set NewComment [ :pick $CommentLine ([ :find $CommentLine ":"] + 2) [ :len $CommentLine] ];
        /system/script/set comment=$NewComment $Script;
        $LogPrint warning $0 ("New comment (" . $NewComment . ") for script '" . $ScriptVal->"name" . "' has been added!");
    }
  }
}  
#  :set NewComment [ :pick $CommentLine ([ :find $CommentLine ":"] + 2) [ :len $CommentLine] ];
#:log warning ("\n\$NewComment = " . $NewComment);
#:log warning ("\n\$CommentLine = " . ([:find $CommentLine ":"] + 2));
}

#:local Input [ :typeof [ :find ([ :tostr $scriptSrc ] . "\n") "\23# Script comment:" ]];
:set Input [ :len [ :pick $Input ([ :find $Input ":" ] + 1) ([ :find $Input "\n" ] - 1) ] ];
#:log warning ("\n\$NewComment = " .$Input);
#:return $Input;

:set UpdateComments do={
  :local Line [ :pick $Input 0 [ :find $Input "\n" ] ];
  :local Line [ :pick $Input 0 [ :find $Input "\n" ] ];
      

      $LogPrint warning $0 ("\n\$commenFindStr: " . $commentFindStr);
      :if ($commentFindStr = "nil") do={
      $LogPrint warning $0 ("The search in new script '" . $ScriptVal->"name" . "' for comment in script body, is not found result Ignoring!");
      } else={
      $Ne
      $LogPrint warning $0 ("New comment (" . $NewComment . ") for script '" . $ScriptVal->"name" . "' has been added!");
      }

      :local CheckComment  ({});
      :set CheckComment ([ $ParseComments [ $Grep $SourceNew ("\23 Script comment: ") ] ]);
       :log warning ("Comment is: " . [ :tostr $CheckComment ]);
       :if ([ :tostr $CheckComment ] = false) do={
        :log warning ("The search in new script '" . $ScriptVal->"name" . "' for comment in script body, is not found result Ignoring!");
        :error false;
       } else={
        :set $NewComment [ :tostr $CheckComment ];
       }
   

:set ParseComments do={
  :local CommSrc ([ :tostr $1 ]);
  :if ([ :typeof $CommSrc ] != "array") do={:set CommSrc [ :tostr $1 ]}
  :local Result ({});
  :foreach ScrComment in=[ :toarray $CommSrc ] do={
    :if ([ :find $ScrComment ":" ]) do={
        :local Key [ :pick $ScrComment 0 [ :find $ScrComment ":" ] ];
        :local Value [ :pick $ScrComment ([ :find $ScrComment ":" ] + 2) [ :len $ScrComment ] ];
#    :log warning ("/n/$Key = " . $Key . " /$KeyValue = " . $KeyValue . " /$Value = " . $Value); 
      :set Result [ :pick $ScrComment ([ :find $ScrComment ":" ] + 1) [ :len $ScrComment ] ];
      } else={:set $Result false}
  }
  :return $Result;
}

# test1.rsc
#
#

:global ParseKeys;
:global ParsedScript;
:global UpdExist;
:global LogPrint;

:set UpdExist do={
:global ParseKeys;
:global LogPrint;

:foreach Script in=[ /system/script/find where source~"^#!rsc by Vados" ] do={
:local ScriptVal [ /system/script/get $Script ];

:set ParsedScript [ $ParseKeys ($ScriptVal->"SetRun") ];
:local scriptName ($ScriptVal->"name");
:local scriptSrc ($ScriptVal->"source");

:local getComment [ :pick $scriptSrc 2 13];

$LogPrint info $0 ("\n\$scriptName = ". $scriptName);
$LogPrint error $0 ("\n\$getComment = ". $getComment);
}
}

$UpdExist;

:set ParseKeys do={
  :local Source $1;
  :if ([ :pick $Source 0 1 ] = "{") do={
    :do {
      :return [ :deserialize from=json $Source ];
    } on-error={ }
  }
  :if ([ :typeof $Source ] != "array") do={:set Source [ :tostr $1 ]}
  :local Result ({});
  :foreach KeyValue in=[ :toarray $Source ] do={
    :if ([ :find $KeyValue "=" ]) do={
      :local Key [ :pick $KeyValue 0 [ :find $KeyValue "=" ] ];
      :local Value [ :pick $KeyValue ([ :find $KeyValue "=" ] + 1) [ :len $KeyValue ] ];
      :if ($Value="true") do={ :set Value true; }
      :if ($Value="false") do={ :set Value false; }
      :set ($Result->$Key) $Value;
    } else={
     :set ($Result->$KeyValue) true;
   }
  }
  :return $Result;
}
