 # MDTLab - MDT infrastructure as code


### What is this repository for? ###

  * Build MDT infrastructure as code, to eliminate all the traditional IT operation work, like backup, etc. 
  * Shorten the time it takes to apply Windows updates.  
    Building Windows reference image from DVD would take long time due to the accumulated Windows Updates, especially for Windows 7. I was courious about how long it really takes, and found it took more than a week for a decent laptop. This script using Microsoft official roll up updates, made it just a few hours. 
  * Automate the Windows Reference Images automatically.  
    From time to time, you will have to rebuild the reference image, it's a standard procedure which I have scripted most parts with this script. 
  

### How do I get set up? ###
  * You have clone this repo on a Windows, which will be turn into MDT server. 
  * You have to have Hyper-V somewhere, and you need permission to create VM and load your boot image there. 
    You can also load the boot image to your WDS server, but it not as convenient as Hyper-V.
  * You need all the windows ISO, and installation packages of MDT, ADK.... 
  * Modify the vairiable part of each script to suite your environment, for example path to the Windows ISO, roll up update packages...
  * The scripts, one by one, will install MDT, create Deplyment share, and fully config it; create VM, and boot it up; the MDT procedure will automatically run and upload the reference image to this MDT server; the VM can be destroyed.  
  Watch the following video:  
  [![Demo PowerShell scripts to Build Base Image with MDT](http://img.youtube.com/vi/VCdjVIk81uQ/hqdefault.jpg)](https://youtu.be/VCdjVIk81uQ "Demo PowerShell scripts to Build Base Image with MDT")
  * Create Deployment Share to deploy reference image can be automated as partially shown here. However, there are component more specific to each environment, like drivers and applications. You will have to customize them to suite your own environment.  
  Watch the following video:   
  [![Demo PowerShell scripts to Deploy Base Image with MDT](http://img.youtube.com/vi/89oQDXtOYjU/hqdefault.jpg)](https://youtu.be/89oQDXtOYjU "Demo PowerShell scripts to Deploy Base Image with MDT")

### Suggestions ###
  * The process takes a lot of disk I/O and SSD is suggested, especially on the Hyper-V host. 
  * Tools like CMTrace64.exe, Toolsx64.cab and Toolsx86.cab are enhancement, and optional. You can downloaded them online. 

### To Do List ###

  * It's not fully automated, I will continue the work later when I have time.


### Who do I talk to? ###

  * victor.ma@gmail.com
