# nightreign-dns-fix
Script for updating DNS server for Elden Ring Nightreign

[Download link](https://github.com/htmlgod/nightreign-dns-fix/archive/refs/heads/main.zip)

> [!CAUTION]
> Back-up `hosts` file before running script

## How to use

From powershell (with admin rights)

```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
./ern-update-dns.ps1
```

or launch `.bat` file.

## How it works

1. Checks Elden Ring Nightreign dns server ip-addresses:
```
nslookup cl-prod-app-steam.fromsoftware-game.net
```
2. Checks addresses for availability
```
curl -k https://<IP>:10901 -m 2
```
3. Add record in hosts file with *live* IP-address