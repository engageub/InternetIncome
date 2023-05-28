# :computer:	Internet Income :money_with_wings:	(Multiproxy Support) :european_castle:	

<img src="https://i.ibb.co/DKbwPN1/imgonline-com-ua-twotoone-2ck-Xl1-JPvw2t-D1.jpg" width="100%" height="300"/>

This script lets you earn income by sharing your internet bandwidth. The income is passive and you don't have to do anything after the setup but keep getting payouts to your account.
The main advantage of this script is the use of multiple proxies through docker containers. 
This script has been tested in linux amd64, arm64 or aarch64 platforms. 
Your income depends on the number of proxies used and the location of proxy. If you use all the apps mentioned, you can earn about $50 per month or more from 1 IP depending on the location of the proxy.

## :moneybag:	Register with the following links:

1. [EarnApp](https://t.co/k0w7jqLfxq)  
2. [PacketStream](https://t.co/FtklOxS7QN)  
3. [Honeygain](https://t.co/Xo1FwoUJx1)  
4. [IPRoyal](https://iproyal.com/pawns?r=170182)  
5. [Peer2Profit](https://peer2profit.com/r/163956712261b9cf129932a)  
6. [ProxyRack](https://peer.proxyrack.com/ref/tqkgvytmszxtxafo30miq2dbeeauuopmmup0eklx)  
7. [Repocket](https://link.repocket.co/pV1G)  
8. [Traffmonetizer](https://traffmonetizer.com/?aff=4211)  
9. [ProxyLite](https://proxylite.ru/?r=AXLDPNX5)  
10. [BitPing](https://app.bitping.com/?r=drPpp600)
11. [Ebesucher](https://www.ebesucher.com/?ref=engageub) (Private autosurf with cookies accepted. Good earnings but consumes more CPU and memory)
12. [Mysterium](https://mystnodes.com/) (Payment of $1 or ~0.22 MYST is required during setup for every node)
13. [GagaNode](https://dashboard.gaganode.com/register?referral_code=kpcnjdxaizdmifk) (Updated soon)
14. [Spider Income](https://income.spider.dev/r/engagf7jws) (Not Supported)
15. [Traffic Earn](https://trafficearn.com/r?r=Mzgy) (Not Supported)
16. [Salad](https://salad.com/) (Use code WM5ZHG for a 2x earning rate bonus!) (Not Supported)
17. [CryptoProxy](https://cryptoproxy.page.link/3J4ASzZ2tf58M77dA) (Mobile device)
18. [PacketShare](https://www.packetshare.io/) (Not Supported)
19. [Speedshare](https://speedshare.app/?ref=ec09fd2d21790b90af37) (Not Supported)
20. [Meson Network](https://dashboard.meson.network/register) (Updated soon)
21. [Cash Raven](https://cashraven.io/) (Mobile device)

* Not Supported are the apps which are not available in docker environment, you may use them in windows.
## :judge: Comparison of different apps based on proxy type 

| App Name | Residential/Home ISP | Datacenter/Hosting/VPS |Limit per Account|Devices per IP|
|  :--- |  :---: |  :---: | :---: | :---: |
| [EarnApp](https://t.co/k0w7jqLfxq)  | :heavy_check_mark:	  | :x: | 15|1|
| [PacketStream](https://t.co/FtklOxS7QN)  | :heavy_check_mark:	  | :x: |No limit|1|
| [Honeygain](https://t.co/Xo1FwoUJx1) | :heavy_check_mark:	  | :x: |10|1|
| [IPRoyal](https://iproyal.com/pawns?r=170182)  | :heavy_check_mark:	  | :x: |No limit|1|
| [Ebesucher](https://www.ebesucher.com/?ref=engageub)  | :heavy_check_mark:	  | :x: |No limit|1|
| [Peer2Profit](https://peer2profit.com/r/163956712261b9cf129932a)  | :heavy_check_mark:	  | :heavy_check_mark:	 | No limit|No limit|
| [ProxyRack](https://peer.proxyrack.com/ref/tqkgvytmszxtxafo30miq2dbeeauuopmmup0eklx)  | :heavy_check_mark:	  | :heavy_check_mark: |500|1|
| [Repocket](https://link.repocket.co/pV1G)  | :heavy_check_mark:	  | :heavy_check_mark: |No limit|2|
| [Traffmonetizer](https://traffmonetizer.com/?aff=4211) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|No limit|
| [ProxyLite](https://proxylite.ru/?r=AXLDPNX5) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1|
| [BitPing](https://app.bitping.com/?r=drPpp600) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1|
| [Mysterium](https://mystnodes.com/) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1|
| [GagaNode](https://dashboard.gaganode.com/register?referral_code=kpcnjdxaizdmifk) | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1|

* The comparison mentioned above was updated on 30-04-2023 and may be subject to change later.
* No Limit indicates the website has not mentioned any specifics about it and multiproxies were working. Try to use 1 device per IP if possible.

## :house_with_garden:	Prerequisites 	
You need to have docker installed in linux machine. If you don't have already, run the following command.  

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
### Install docker on Linux
```
sudo apt-get update
sudo apt-get -y install docker.io
```
If you are using arm or aarch linux OS, you also need to install [binfmt](https://hub.docker.com/r/tonistiigi/binfmt) emulator to support amd64 images on your pc.
### For ARM or AARCH Architectures
```
sudo docker run --privileged --rm tonistiigi/binfmt --install all
sudo apt-get install qemu binfmt-support qemu-user-static
```

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
### Install Docker on Windows
Follow this [tutorial](https://www.youtube.com/watch?v=2ezNqqaSjq8) till 7.30 minutes where docker runs on ubuntu and then follow the next steps below to download the code.
  
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)  
### Want to try docker for free without installation?
If you like to use docker directly for free, you can use [Play with Docker](https://labs.play-with-docker.com/). It resets every 4 hours. 
## :point_down:	What next:question:	
Download the code and edit the configuration file properties.conf with your account details.  
If you don't have GUI access but have terminal access, use the following commands to download the code.
### Download the code
```
wget https://github.com/engageub/InternetIncome/archive/refs/heads/main.zip
sudo apt-get install unzip
unzip main.zip
cd InternetIncome-main
```
* Please edit the "properties.conf" file using the following instructions and save the changes.  
* If you are using proxies, please set the "USE_PROXIES" value to "true". 
* When setting your email, password, or token, always use double quotes ("") due to special characters. 
* If you do not wish to use a particular application, leave the default value as it is, and the script will not run for that application.
### Update configuration and save
```
vi properties.conf
```
## :runner: Run the script
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you:money_mouth_face:	.
### Start the process
```
sudo bash internetIncome.sh --start
```
## :stop_sign: Stop and Delete containers
To stop and delete all the containers started with the script. Run the following command.  Note that for earnapp, proxyrack, traffmonetizer and mysterium the data is not deleted and same ids will be used on delete and start, since it is required to do manual setup each time you start. Delete them or use a different folder to download the script if you want to change the node ids.
### Stop and delete containers
Note that back up of device Ids and node Ids are present in the same folder of the script. 
```
sudo bash internetIncome.sh --delete
```
## :grey_question: FAQ
### :thinking:	How to use residential proxies:question:	
If you wish to use proxies, you need to set the value of variable USE_PROXIES to true in properties.conf file.
Then, create a file name proxies.txt in the same folder you have internetIncome.sh file.
Add your proxies in each line in the format protocol://user:pass@ip:port or protocol://ip:port
Example proxies.txt file below. Use your own proxies. 
### Proxy list example format
```
socks5://username:password@12.4.5.2:7874
http://username:password@1.23.5.2:7878
socks5://15.4.5.2:7875
http://13.23.5.2:7872
```
### :thinking:	Can I use without proxies:question:		
**Yes**:exclamation: You can use the script with direct internet connection by setting the variable USE_PROXIES to false in properties.conf file. This is the default configuration when you download the script. 
### :thinking: How to use multiple accounts:question:		
For multiple users to use the same host, simply create different folders and download the script in each folder and set the configuration. It is recommended not to create multilple accounts for yourself. 
### :thinking: How to auto update containers:question:
To auto update all containers on the host, run the following command.
```
sudo docker run --detach --name watchtower --restart always --volume /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower
```
### :thinking: Why are some of the containers for the same application offline:question:
If your proxies are working properly, ensure that your CPU usage remains below 80% and that you have enough available RAM. Otherwise, high CPU usage or insufficient RAM could cause the issue you are experiencing. In addition to this, the application website may also be throttling the requests either due to multiple authentication requests in a short span of time or the request may be timing out etc. For example in case of iproyals pawns website this happens very frequently when multiple devices are added. Giving a delay between startup of instances is not always a solution for this, since it worked without any delay sometimes. Restarting the instance multiple times always worked. This is something intermittent and related to the application that is being used. You will need to restart containers manually for those instances where proxies are offline.
### :thinking: Why is Mysterium node not working:question:
It is crucial to understand that the Mysterium node operates differently from other applications, as it necessitates the enabling of UDP (User Datagram Protocol). This protocol is essential for the proper functioning of the Mysterium node. In the case of utilizing SOCKS5 proxies, it is imperative to confirm with your provider whether UDP is enabled for your specific SOCKS5 proxy. When utilizing a direct internet connection, it is imperative to ensure that your firewall is configured to allow UDP traffic.

### :thinking: Where is Mysterium data stored:question:
The data pertaining to your Mysterium keys is stored in the designated "mysterium-data" folder, located in the same directory as the script. It is crucial to note that the script does not remove or delete this folder, as it contains your private keys. Losing these keys would necessitate the payment for a new Mysterium node.
Therefore, it is imperative to exercise caution and ensure the safety and security of the "mysterium-data" folder, as it contains sensitive and valuable information. By taking appropriate measures to preserve and back up this data, you can mitigate the risk of potential loss and subsequent financial implications.

### :thinking: Where are earnapp node urls stored and how to restore them:question:
The UUID or node IDs are required to identify your unique nodes in earnapp dashboard. These nodes are stored in earnapp.txt file and are not deleted. The same node Ids will be used when you start the application again. You do not need to delete existing nodes in dashboard and add them again when you use --delete option.  If you already have an existing node and would like to use it via the script you may add them in earnapp.txt file in the same format as the existing file.

### :thinking: How to replace proxies for already running containers:question:
If you wish to use change proxies for already running container due to bad proxies or proxies being offline, update them in proxies.txt and remove your old proxies. Make sure you have the same number of proxies as you had earlier in proxies.txt file. Then run the following command.
```
sudo bash updateProxies.sh
```

## :card_index: License:
* This product is available for free and may be freely copied and distributed in its original form. 
* However, it is prohibited to distribute modified copies of the product. 
* Personal modifications are allowed for personal use only.

## :warning: Disclaimer
This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose.  
The author shall not  be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.  
