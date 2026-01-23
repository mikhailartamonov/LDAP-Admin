# LDAP Admin for Linux

## What it is

Linux port of free Windows LDAP Admin (http://ldapadmin.org), client and administration tool for LDAP directory management.

## Status

Stable functions: 
- Browsing and editing of LDAP directories
- Recursive operations on directory trees (copy, move and delete)
- Schema browsing
- LDIF export and import
- Password management (supports crypt, md5, sha, sha-crypt, samba)
- Template support
- Binary attribute support
- LDAP SSL/TLS support
 

Untested functions: 
- Management of Posix Groups and Accounts
- Management of Samba Accounts
- Postfix MTA Support
 

Disabled functions: 
- Scripting


## Downloads
See [releases](../../releases)


## Requirements
- Lazarus, developed on version 4.4
- compiler FPC 3.2+, developed on version 3.2.2
- library libssl.so.1.1, libcrypto.so.1.1, for usign OpenSSL 1.1
- library libssl.so.3, libcrypto.so.3, for usign OpenSSL 3
- mORMot2 library
- Linux desktop


## How to localize
PLEASE DO NOT USE THE BUILT-IN FUNCTION IN THE MENU (.llf files)!
The recommended way to locate in linux is as follows, 
- create (if not exist) directory locale
- resourcestrings are compiled into .po files if you enable i18n in the Lazarus IDE. Go to Project > Project Options > i18n > Enable i18n
- copy file LdapAdmin.po to LdapAdmin.xx.po, where xx is two-letter language code
  (en for English, ru for Russian,  de for Germany , ...)
- translate string with Poedit, https://poedit.net/


## How to compile
- install Lazarus from binaries - http://wiki.freepascal.org/Installing_Lazarus
- git clone https://github.com/ibv/LDAP-Admin.git
- cd LDAP-Admin
- git submodule update --init --recursive   (If it's the first time you check-out a repo)
- git submodule update --recursive --remote
- in Lazarus IDE, menu - File -> Open -> "Source/LdapAdmin.lpi"
- in Lazarus IDE, menu - Run -> F9 (run) or Ctrl+F9 (compile) or Shift+F9 (link) or "/usr/bin/lazbuild /path/to/LdapAdmin.lpi"


## Further information

For more information about it, please visit:
> http://ivb.wz.cz/en/ldap.html
