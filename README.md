# InternetCash
Internet Cash: Earn income with internet (Proxies Supported)

This script lets you earn income by sharing your internet bandwidth. The main advantage of this script is the use of multiple proxies in docker. 
This script has been tested in linux amd64 and arm64 platforms. 

## Register with the following links

## Prerequisites 
You need to have docker installed in linux machine. If you don't have already, run the following command.
```
sudo apt-get install docker.io
```
## What next?
Download the script name internetIncome.sh and edit the script using vi or notepad.

Set the values in the user configuration section of the script.
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
