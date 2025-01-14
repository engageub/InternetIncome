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

### <ins>[Click here to view Browser Extension Based Apps](https://github.com/engageub/InternetIncome/wiki/Browser-Extension-Based-Apps)</ins> 


## :house_with_garden:	Prerequisites 	
You need to have docker installed in linux machine. If you don't have already, run the following command.  

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
### Install docker on Linux
The script automatically detects and provides instructions to install any dependencies.

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
## :runner: Run the script
After you have followed all the mentioned above steps just run the following command to start and check your income flow to you:money_mouth_face:	.
### Start the process
```
sudo bash internetIncome.sh --start
```
## :stop_sign: Stop and Delete containers
To stop and delete all the containers started with the script. Run the following command.  Note that for Earnapp, Proxyrack, Traffmonetizer, and mysterium the data is not deleted and the same IDs will be used on delete and start since it is required to do a manual setup each time you start. Delete them or use a different folder to download the script if you want to change the node IDs.
### Delete containers
Note that the backup of device IDs and node IDs are present in the same folder of the script. 
```
sudo bash internetIncome.sh --delete
```
### Delete backup files and folders
To delete the backup files and folders created by the script, use the following command.
```
sudo bash internetIncome.sh --deleteBackup
```
## :grey_question: FAQ
### <ins>[Click here to view Frequently Asked Questions](https://github.com/engageub/InternetIncome/wiki/Frequently-Asked-Questions)</ins> 

## :card_index: License:
* This product is available for free and may be freely copied and distributed in its original form. 
* However, it is prohibited to distribute modified copies of the product. 
* Personal modifications are allowed for personal use only.

## :warning: Disclaimer
This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose.  
The author shall not  be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.  
