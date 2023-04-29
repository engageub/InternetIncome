# InternetCash (Multiproxy Support)
Internet Cash: Earn income with internet (Proxies Supported)

This script lets you earn income by sharing your internet bandwidth. The main advantage of this script is the use of multiple proxies in docker. 
This script has been tested in linux amd64, arm64 or aarch64 platforms. 

## Register with the following links:

1. [EarnApp](https://earnapp.com/i/YVI34SG)  
2. [PacketStream](https://packetstream.io/?psr=4tHH)  
3. [Honeygain](https://r.honeygain.me/UBEADA3E30)  
4. [IPRoyal](https://iproyal.com/pawns?r=170182)  
5. [Peer2Profit](https://peer2profit.com/r/163956712261b9cf129932a)  
6. [ProxyRack](https://peer.proxyrack.com/ref/tqkgvytmszxtxafo30miq2dbeeauuopmmup0eklx)  
7. [Repocket](https://link.repocket.co/pV1G)  
8. [Traffmonetizer](https://traffmonetizer.com/?aff=4211)  
9. [ProxyLite](https://proxylite.ru/?r=AXLDPNX5)  

## Prerequisites 
You need to have docker installed in linux machine. If you don't have already, run the following command.
```
sudo apt-get install docker.io
```
If you are using arm64 or aarch64 linux OS, you also need to install [binfmt](https://hub.docker.com/r/tonistiigi/binfmt) emulator to support amd64 images on your pc or you may also run the following command.
```
sudo apt-get install qemu binfmt-support qemu-user-static
```

## What next?
Download the script name income.sh and edit the script using vi or notepad.

Set the values in the user configuration section of the script.
If you do not wish to use any particular app just leave the default value as it is and the script will not run for those apps.
After setting the values and saving the script, give permissions to the script using the following command. 

```
sudo chmod 777 income.sh
```

## How to use residential proxies?

You need to set the value of variable USE_PROXIES to true in income.sh script.
Then, create a file name proxies.txt in the same folder you have income.sh file.
Add your proxies in each line in the format protocol://user:pass@ip:port or protocol://ip:port
Example proxies.txt file below. Use your own proxies. 
```
socks5://username:password@12.4.5.2:7874
http://username:passwword@1.23.5.2:7878
socks5://15.4.5.2:7875
http://13.23.5.2:7872
```

## Can I use without proxies?

Yes. You can use the script with direct internet connection by setting the variable USE_PROXIES to false.


## Final Step: Running the script
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you.
```
sudo ./income.sh
```

## Disclaimer
This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose. 
The author shall not  be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.  
