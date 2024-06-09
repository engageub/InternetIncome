# :computer:	Internet Income :money_with_wings:	(Multi-Proxy, Multi-IP, Multi-VPN Support) :european_castle:	

<img src="https://i.ibb.co/DKbwPN1/imgonline-com-ua-twotoone-2ck-Xl1-JPvw2t-D1.jpg" width="100%" height="300"/>

* Disclaimer: This branch is for advanced users. 


This script lets you earn income by sharing your internet bandwidth. The income is passive and you don't have to do anything after the setup but keep getting payouts to your account.
The main advantage of this script is the use of multiple proxies through docker containers. 
This script has been tested in linux amd64, arm64 or aarch64 platforms. 
Your income depends on the number of proxies used and the location of proxy. If you use all the apps mentioned, you can earn about $50 per month or more from 1 IP depending on the location of the proxy.

## 💰	Register with the following links:
### <ins>[Click here to Sign Up now](https://github.com/engageub/InternetIncome/wiki/Registration-Links)</ins> 

## :judge: Comparison of different apps based on proxy type 
### <ins>[Click here to view comparison of apps](https://github.com/engageub/InternetIncome/wiki/Comparison-of-different-apps-based-on-proxy-type)</ins> 



## :house_with_garden:	Prerequisites 	
You need to have docker installed in linux machine. If you don't have already, run the following command.  

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
### Install docker on Linux
The script detects automatically and provides instructions to install any dependencies. 

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
### Install Docker on Windows
Follow this [tutorial](https://www.youtube.com/watch?v=2ezNqqaSjq8) till 7.30 minutes where docker runs on ubuntu and then follow the next steps below to download the code.
  
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)  
### Want to try docker for free without installation?
If you like to use Docker directly for free, you can use [Play with Docker](https://labs.play-with-docker.com/). It resets every 4 hours. Please use the [tunproxy](https://github.com/engageub/InternetIncome/tree/tunproxy) branch to test it using proxies.
## :point_down:	What next:question:	
Download the code and edit the configuration file properties.conf with your account details.  
If you don't have GUI access but have terminal access, use the following commands to download the code.
### Download the code
```
wget -O test.zip https://github.com/engageub/InternetIncome/archive/refs/heads/test.zip
sudo apt-get install unzip
unzip -o test.zip
cd InternetIncome-test
```
* Please edit the "properties.conf" file using the following instructions and save the changes.  
* If you are using proxies, please set the "USE_PROXIES" value to "true". 
* When setting your email, password, or token, always place them between single quotes ('') to consider special characters. 
* If you do not wish to use a particular application, leave the default value as it is, and the script will not run for that application.
### Update configuration and save
```
vi properties.conf
```

## :thinking:	How to use residential proxies:question:	

If you wish to use direct connection, you may skip this section and move on to running the script.
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

## :runner: Run the script
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you:money_mouth_face:	.
### Start the process
```
sudo bash internetIncome.sh --start
```
## :stop_sign: Stop and Delete containers
To stop and delete all the containers started with the script. Run the following command.
### Stop process and delete data
```
sudo bash internetIncome.sh --delete
```
## :grey_question: FAQ
### :thinking:	Can I use without proxies:question:		
**Yes**:exclamation: You can use the script with direct internet connection by setting the variable USE_DIRECT_CONNECTION to true in properties.conf file.
### :thinking: How to use multiple accounts:question:		
For multiple users to use the same host, simply create different folders and download the script in each folder and set the configuration. It is recommended not to create multilple accounts for yourself. 
### :thinking: How to auto update containers:question:
To auto update all containers on the host, run the following command.
```
sudo docker run --detach --name watchtower --restart always --volume /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower
```
### :thinking: Why are some of the containers for the same application offline:question:
If your proxies are working properly, ensure that your CPU usage remains below 80% and that you have enough available RAM. Otherwise, high CPU usage or insufficient RAM could cause the issue you are experiencing.
### :thinking: Why is Mysterium node not working:question:
It is crucial to understand that the Mysterium node operates differently from other applications, as it necessitates the enabling of UDP (User Datagram Protocol). This protocol is essential for the proper functioning of the Mysterium node. In the case of utilizing SOCKS5 proxies, it is imperative to confirm with your provider whether UDP is enabled for your specific SOCKS5 proxy. When utilizing a direct internet connection, it is imperative to ensure that your firewall is configured to allow UDP traffic.

### :thinking: Where is Mysterium data stored:question:
The data pertaining to your Mysterium keys is stored in the designated "mysterium-data" folder, located in the same directory as the script. It is crucial to note that the script does not remove or delete this folder, as it contains your private keys. Losing these keys would necessitate the payment for a new Mysterium node.
Therefore, it is imperative to exercise caution and ensure the safety and security of the "mysterium-data" folder, as it contains sensitive and valuable information. By taking appropriate measures to preserve and back up this data, you can mitigate the risk of potential loss and subsequent financial implications.
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
