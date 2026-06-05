# MITRE ATT&CK Coverage Matrix

| Tactic / Technique | Detection Rules |
|-------------------|-----------------|
| **credential_access** | LSASS Memory Dump via Comsvcs.dll |
| **t1003** | LSASS Memory Dump via Comsvcs.dll |
| **command_and_control** | Malicious File Download via Bitsadmin |
| **t1105** | Malicious File Download via Bitsadmin |
| **persistence** | Local User Account Creation via Net.exe, Scheduled Task Creation via Schtasks |
| **t1136** | Local User Account Creation via Net.exe |
| **discovery** | Suspicious System Owner/User Discovery |
| **t1033** | Suspicious System Owner/User Discovery |
| **privilege_escalation** | RDP Session Hijacking via Tscon |
| **lateral_movement** | RDP Session Hijacking via Tscon |
| **t1574** | RDP Session Hijacking via Tscon |
| **execution** | Scheduled Task Creation via Schtasks, WMI Process Call Create, Suspicious PowerShell Encoded Command Execution |
| **t1053** | Scheduled Task Creation via Schtasks |
| **t1047** | WMI Process Call Create |
| **defense_evasion** | Regsvr32 Execution from Remote Server, Clearing Windows Event Logs via Wevtutil |
| **t1218** | Regsvr32 Execution from Remote Server |
| **t1059** | Suspicious PowerShell Encoded Command Execution |
| **t1070** | Clearing Windows Event Logs via Wevtutil |
