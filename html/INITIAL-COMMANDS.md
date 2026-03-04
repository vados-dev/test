Initial commands
================

[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)

[⬅️ Go back to main README](README.md)

> ⚠️ **Warning**: These commands are intended for initial setup. If you are
> not aware of the procedure please follow
> [the long way in detail](README.md#the-long-way-in-detail).

Run the complete base installation:

    {
      :local BaseUrl "https://rsc.eworm.de/main/";
      :local CertCommonName "Root YE";
      :local CertFileName "Root-YE.pem";
      :local CertFingerprint "e14ffcad5b0025731006caa43a121a22d8e9700f4fb9cf852f02a708aa5d5666";

      :local CertSettings [ /certificate/settings/get ];
      :if (!((($CertSettings->"builtin-trust-anchors") = "trusted" || \
              ($CertSettings->"builtin-trust-store") ~ "fetch" || \
              ($CertSettings->"builtin-trust-store") = "all") && \
             [ :len [ /certificate/builtin/find where common-name=$CertCommonName ] ] > 0)) do={
        :put "Importing certificate...";
        /tool/fetch ($BaseUrl . "certs/" . $CertFileName) dst-path=$CertFileName as-value;
        :delay 1s;
        /certificate/import file-name=$CertFileName passphrase="";
        :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] != 1) do={
          :error "Something is wrong with your certificates!";
        };
        :delay 1s;
      };
      :put "Renaming global-config-overlay, if exists...";
      /system/script/set name=("global-config-overlay-" . [ /system/clock/get date ] . "-" . [ /system/clock/get time ]) [ find where name="global-config-overlay" ];
      :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={
        :put "Installing $Script...";
        /system/script/remove [ find where name=$Script ];
        /system/script/add name=$Script owner=$Script source=([ /tool/fetch check-certificate=yes-without-crl ($BaseUrl . $Script . ".rsc") output=user as-value ]->"data");
      };
      :put "Loading configuration and functions...";
      /system/script { run global-config; run global-functions; };
      :if ([ :len [ /certificate/find where fingerprint=$CertFingerprint ] ] > 0) do={
        :put "Renaming certificate by its common-name...";
        :global CertificateNameByCN;
        $CertificateNameByCN $CertFingerprint;
      };
    };

Then continue setup with
[scheduled automatic updates](README.md#scheduled-automatic-updates) or
[editing configuration](README.md#editing-configuration).

## Fix existing installation

The [initial commands](#initial-commands) above allow to fix an existing
installation in case it ever breaks. If `global-config-overlay` did exist
before it is renamed with a date and time suffix (like
`global-config-overlay-2024-01-25-09:33:12`). Make sure to restore the
configuration overlay if required.

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
