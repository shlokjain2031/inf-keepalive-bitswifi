I just found that to remain logged in at all times you just need to keep hitting the keepalive window. It resets the time you have remaining. 

Special credits to chrome developer tools and eyesight lol

# How to use
download `bits_keepalive.sh' and run it in the background so you just start it once and stop thinking about it. Even autostarts if you shutdown.

```
git clone https://github.com/shlokjain2031/inf-keepalive-bitswifi.git
cd inf-keepalive-bitswifi
```

Note: autostart is only available for macOS right now. There is a patch for Linux in the branch linux-autostart but someone will need to test it for me to merge it into main

macOS
--------------

```bash
chmod +x bits_keepalive.sh
nohup ./bits_keepalive.sh --install > bits_keepalive.log 2>&1 &
```

Linux
--------------
```bash
chmod +x bits_keepalive.sh
nohup ./bits_keepalive.sh > bits_keepalive.log 2>&1 &
```

Windows (Git Bash / WSL)
-----------------------
sorry u guys don't have bash by default

Run the script inside Git Bash or WSL and use the shell’s background operator so it keeps running even after you close the terminal:

```bash
chmod +x bits_keepalive.sh
./bits_keepalive.sh > bits_keepalive.log 2>&1 &
```

