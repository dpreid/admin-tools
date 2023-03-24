# Retrofit new Jump host to existing experiments

## Background

Jump has been updated to allow large file transfers. We want to migrate from `relay@v0.2.3/shellhost` on the experiments, to `jump@v0.3.0/host`, running in both in parallel for now.

We need to do this manually (hopefully the last manual task we will need to do on the experiments, because the new update should allow us to work with ansible now)

Copying in a script to do the task is probably the least manual work.

Develop the script on pend35 as follows (note that spinners might already have go)

```
sudo su
cd sources
wget https://golang.org/dl/go1.20.1.linux-armv6l.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.1.linux-armv6l.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
source /etc/profile
git clone https://github.com/practable/jump.git
cd jump/scripts/build
./build.sh
cd ../../cmd/jump
cp jump /usr/local/bin
cd ../../../
cat > getid.sh <<'EOF'
#!/bin/sh  
idfilter='https://relay-access.practable.io/session/(\w*)-data' 
access=$(cat /etc/practable/data.access) 
[[ $access =~ $idfilter ]] 
id="${BASH_REMATCH[1]}" 
echo $id 
EOF
chmod +x ./getid.sh
./getid.sh
export PRACTABLE_ID=$(./getid.sh)
cd /etc/practable
export SECRET_FILES=https://static.practable.io
wget $SECRET_FILES/jump.access.$PRACTABLE_ID -O jump.access
wget $SECRET_FILES/jump.token.$PRACTABLE_ID -O jump.token
cd /etc/systemd/system

cat > jump.service <<'EOF'
[Unit]
Description=github.com/practable/jump host
After=network.target

[Service]
LimitNOFILE=99999
Environment=JUMP_CLIENT_LOCAL_PORT=22
Environment=JUMP_CLIENT_RELAY_SESSION=$(cat /etc/practable/jump.access)
Environment=JUMP_CLIENT_DEVELOPMENT=true
Environment=JUMP_CLIENT_TOKEN=$(cat /etc/practable/jump.token)

Type=simple
Restart=always
ExecStart=/usr/local/bin/jump host

PermissionsStartOnly=true
ExecStartPre=/bin/mkdir -p /var/log/jump
ExecStartPre=/bin/chown syslog:adm /var/log/jump
ExecStartPre=/bin/chmod 755 /var/log/jump
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=jump

[Install]
WantedBy=multi-user.target
EOF
systemctl enable jump.service
systemctl start jump.service
```

Now we need to get some files on the system.

If we copy them in by hand, then they are secure.
If we place them somewhere obfuscated, that is not listed publically, we are probably ok ...

we can get the id of the experiment automatically from the data.access file
https://relay-access.practable.io/session/pend35-data



idfilter='https://relay-access.practable.io/session/(\w*)-data'
access=$(cat /etc/practable/data.access)
[[ $access =~ $idfilter ]]
id="${BASH_REMATCH[0]}"
echo $id