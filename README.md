# :computer:	Internet Cash :money_with_wings:	(Multiproxy Support):european_castle:	
Internet Cash: Earn passive income with internet (Proxies Supported)

This script lets you earn income by sharing your internet bandwidth. The income is passive and you don't have to do anything after the setup but keep getting payouts to your account.
The main advantage of this script is the use of multiple proxies through docker containers. 
This script has been tested in linux amd64, arm64 or aarch64 platforms. 
Your income depends on the number of proxies used and the location of proxy.

## :moneybag:	Register with the following links::moneybag:	

1. [EarnApp](https://earnapp.com/i/YVI34SG)  
2. [PacketStream](https://packetstream.io/?psr=4tHH)  
3. [Honeygain](https://r.honeygain.me/UBEADA3E30)  
4. [IPRoyal](https://iproyal.com/pawns?r=170182)  
5. [Peer2Profit](https://peer2profit.com/r/163956712261b9cf129932a)  
6. [ProxyRack](https://peer.proxyrack.com/ref/tqkgvytmszxtxafo30miq2dbeeauuopmmup0eklx)  
7. [Repocket](https://link.repocket.co/pV1G)  
8. [Traffmonetizer](https://traffmonetizer.com/?aff=4211)  
9. [ProxyLite](https://proxylite.ru/?r=AXLDPNX5)  

## :judge: Comparision of different apps based on proxy type :judge:	

| App Name | Residential/Home ISP | Datacenter/Hosting/VPS |Limit per Account|Devices per IP|
|  :--- |  :---: |  :---: | :---: | :---: |
| [EarnApp](https://earnapp.com/i/YVI34SG)  | :heavy_check_mark:	  | :x: | 15|1|
| [PacketStream](https://packetstream.io/?psr=4tHH)  | :heavy_check_mark:	  | :x: |No limit|1|
| [Honeygain](https://r.honeygain.me/UBEADA3E30) | :heavy_check_mark:	  | :x: |10|1|
| [IPRoyal](https://iproyal.com/pawns?r=170182)  | :heavy_check_mark:	  | :x: |No limit|1|
| [Peer2Profit](https://peer2profit.com/r/163956712261b9cf129932a)  | :heavy_check_mark:	  | :heavy_check_mark:	 | No limit|No limit|
| [ProxyRack](https://peer.proxyrack.com/ref/tqkgvytmszxtxafo30miq2dbeeauuopmmup0eklx)  | :heavy_check_mark:	  | :heavy_check_mark: |500|1|
| [Repocket](https://link.repocket.co/pV1G)  | :heavy_check_mark:	  | :heavy_check_mark: |No limit|2|
| [Traffmonetizer](https://traffmonetizer.com/?aff=4211) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|No limit|
| [ProxyLite](https://proxylite.ru/?r=AXLDPNX5) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1|

* The comparision mentioned above was updated on 30-04-2023 and may subject to change later.
## :house_with_garden:	Prerequisites :house_with_garden:	
You need to have docker installed in linux machine. If you don't have already, run the following command.
```
sudo apt-get install docker.io
```
If you are using arm64 or aarch64 linux OS, you also need to install [binfmt](https://hub.docker.com/r/tonistiigi/binfmt) emulator to support amd64 images on your pc or you may also run the following command.
```
sudo apt-get install qemu binfmt-support qemu-user-static
```

## :point_down:	What next:question:	 :point_down:	
Download the code and edit the configuration file properties.conf with your account details.
If you do not wish to use any particular app just leave the default value as it is and the script will not run for those apps.
After setting the values and saving the file, give permissions to the script using the following command. 

```
sudo chmod 777 income.sh
```

## :thinking:	How to use residential proxies:question:	

You need to set the value of variable USE_PROXIES to true in properties.conf file.
Then, create a file name proxies.txt in the same folder you have income.sh file.
Add your proxies in each line in the format protocol://user:pass@ip:port or protocol://ip:port
Example proxies.txt file below. Use your own proxies. 
```
socks5://username:password@12.4.5.2:7874
http://username:passwword@1.23.5.2:7878
socks5://15.4.5.2:7875
http://13.23.5.2:7872
```

## :thinking:	Can I use without proxies:question:		

Yes. You can use the script with direct internet connection by setting the variable USE_PROXIES to false in properties.conf file.


## Final Step: :runner:Running the script:runner:
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you:money_mouth_face:	.
```
sudo ./income.sh --start
```
## :stop_sign:Stopping and deleting all containers:stop_sign:	
To stop and delete all the containers started with the script. Run the following command.
```
sudo ./income.sh --delete
```

## :warning:Disclaimer:warning:	
This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose.  
The author shall not  be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.  
