#!rsc by Vados
# RouterOS function-collection
# CustomBackups Functions 

:global DoLocalBackup;

:set DoLocalBackup do={
#:foreach BakScript in=([ /system/script/find where name~"*" ]) do={ import file=Scripts/$BakScript}; 
tool e-mail export show-sensitive file=export/email.rsc;
system scheduler export file=export/scheduler.rsc;
system script export show-sensitive file=export/script.rsc;
certificate export file=export/certificate_settings.rsc;
ip firewall nat export file=export/nat.rsc;
ip firewall filter export file=export/filter.rsc;
ip firewall address-list export file=export/address-list.rsc;
ip route export file=export/route.rsc;
ip dhcp-server network export file=export/network.rsc;
interface ethernet export file=export/ethernet.rsc;
ip pool export file=export/pool.rsc;
ip dns export file=export/dns.rsc;
}

