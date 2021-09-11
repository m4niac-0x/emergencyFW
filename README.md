# emergencyFW  
A stupid bash script to quickly inject massive IPTABLES rules.  

```
# ./emergencyFW.sh {action} {format} {target}
{action} = block / unblock
{format} = ipaddr, iprange or country
{target} = 192.168.x.x, 192.168.1.0/24 or fr/us/en/ca/...
```
