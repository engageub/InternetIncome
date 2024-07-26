# 💻 Internet Income 💸 (Multiproxy Support) ⚽	

<img src="https://i.ibb.co/DKbwPN1/imgonline-com-ua-twotoone-2ck-Xl1-JPvw2t-D1.jpg" width="100%" height="300"/>

This script lets you earn income by sharing your internet bandwidth. The income is passive and you don't have to do anything after the setup but keep getting payouts to your account.
The main advantage of this script is the use of multiple proxies through docker containers. 
Your income depends on the number of proxies used and the location of proxy. If you use all the apps mentioned, you can earn about $50 per month or more from 1 IP depending on the location of the proxy.
Please read the legal terms or FAQ section of the respective apps if you have any queries on the type of traffic sent. 
Advanced users, use [test] branch.

## 💰	Register with the following links:
(Affiliate Links) ⚽⚽⚽
| App Name | Residential/Home ISP | Datacenter/Hosting/VPS |Limit per Account|Devices per IP| Payment|
|  :--- |  :---: |  :---: | :---: | :---: | :---: |
| ⚽⚽⚽[EarnApp] [(https://earnapp.com/i/JAegLixz))  | :heavy_check_mark:	  | :x: | 15|1| Paypal, Gift Card |
| ⚽⚽[PacketStream] https://packetstream.io/?psr=6Ic6 | :heavy_check_mark:	  | :x: |No limit|1| Paypal |
| ⚽⚽⚽[Honeygain] https://r.honeygain.me/MADDYB570E | :heavy_check_mark:	  | :x: |10|1| Crypto, Paypal |
| ⚽⚽[IPRoyal] https://pawns.app/?r=4640575 | :heavy_check_mark:	  | :x: |No limit|1|Crypto, Paypal|
| ⚽⚽[Adnade] https://adnade.net/?ref=dylaaann | :heavy_check_mark:	  | :x: |No limit|1|Crypto, Paypal| 
| ⚽⚽⚽[Bytelixir] https://bytelixir.com/r/WCCLWVKNOAF6 | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1| Crypto |
| ⚽⚽[Salad] CODE 2x Earnings: Join me on Salad and use code TU1QW7 for a 2x earning rate bonus! https://salad.com | :heavy_check_mark:	  | :heavy_check_mark: |No limit|1| Paypal |


*


## :house_with_garden:	Prerequisites 	
Run the following commands to install or update docker.

Ubuntu 20.04 is recommended. 

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
If you like to use docker directly for free, you can use [Play with Docker](https://labs.play-with-docker.com/). It resets every 4 hours. Please use [tunproxy](https://github.com/engageub/InternetIncome/tree/tunproxy) branch to test it using proxies.
## 👇	Next steps❓	
Download the code and edit the configuration file properties.conf with your account details.  
If you don't have GUI access but have terminal access, use the following commands to download the code.
### Download the code
```
wget -O main.zip https://github.com/engageub/InternetIncome/archive/refs/heads/main.zip
sudo apt-get install unzip
unzip -o main.zip
cd InternetIncome-main
```
* Please edit the "properties.conf" file using the following instructions and save the changes.  
* If you are using proxies, please set "USE_PROXIES" value to "true". 
* When setting your email, password, or token, always use double quotes ("") due to special characters. 
* If you do not wish to use a particular application, leave the default value as it is, and the script will not run for that application.
### Update configuration and save
```
vi properties.conf
```
## :runner: Run the script
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you :money_mouth_face:	.
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
### Delete backup files and folders
To delete the backup files and folders created by the script, use the following command.
```
sudo bash internetIncome.sh --deleteBackup
```


## :grey_question: FAQ
### 🤔	How to use residential proxies❓	
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
For any other proxy format, please [click here]


### 🤔	Can I use without proxies❓		
**Yes**:exclamation: You can use the script with direct internet connection by setting the variable USE_PROXIES to false in properties.conf file. This is the default configuration when you download the script. 
### 🤔 How to use multiple accounts❓		
For multiple users to use the same host, simply create different folders and download the script in each folder and set the configuration. It is recommended not to create multilple accounts for yourself. 
### 🤔 How to auto update containers❓
To auto update all containers on the host, run the following command.
```
sudo docker run --detach --name watchtower --restart always --volume /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower
```
### 🤔 How to clean up all docker containers on the host❓
Please run the following command to delete all the running and stale containers on your host. The commands also delete stale docker images.
```
sudo docker container ls -a | awk '{print $1}' | xargs sudo docker rm -f
sudo docker system prune -f -a
```
### 🤔 Why are some of the containers for the same application offline❓
If your proxies are working properly, ensure that your CPU usage remains below 80% and that you have enough available RAM. Otherwise, high CPU usage or insufficient RAM could cause the issue you are experiencing. In addition to this, the application website may also be throttling the requests either due to multiple authentication requests in a short span of time or the request may be timing out etc. 
Your DNS requests may also be throttled on the host. Set the value of USE_DNS_OVER_HTTPS to true in properties.conf to see if this resolves the issue. If you are using socks5 proxies that support DNS requests, set the value of USE_SOCKS5_DNS to true. 

If your VPS IP is not accessible globally, please run the following command to get the corresponsing url.
```
ssh -R 80:127.0.0.1:2000 serveo.net
```
In the above command 2000 represents the port number of your localhost or 127.0.0.1. For each browser instance, there is a separate port number. Please change the port number accordingly. You will receive an url after running the above command which can be accessed globally. 

### 🤔 Where are earnapp node urls stored and how to restore them❓
The UUID or node IDs are required to identify your unique nodes in earnapp dashboard. These nodes are stored in earnapp.txt file and are not deleted. The same node Ids will be used when you start the application again. You do not need to delete existing nodes in dashboard and add them again when you use --delete option.  If you already have an existing node and would like to use it via the script you may add them in earnapp.txt file in the same format as the existing file.

### 🤔 How to replace proxies for already running containers❓
If you wish to use change proxies for already running container due to bad proxies or proxies being offline, update them in proxies.txt and remove your old proxies. Make sure you have the same number of proxies as you had earlier in proxies.txt file. Then run the following command.
```
sudo bash updateProxies.sh
```

## 📇 License:
* This product is available for free and may be freely copied and distributed in its original form. 
* However, it is prohibited to distribute modified copies of the product. 
* Personal modifications are allowed for personal use only.

## :warning: Disclaimer
This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose.  
The author shall not  be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.  
This script is a for educational purposes only; and not intended to be used to actually earn Income from these apps. Rather, provide educational scripts that users can LEARN from.
