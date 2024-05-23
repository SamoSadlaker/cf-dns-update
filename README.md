# cf-dns-update
Simple Bash script to update Cloudflare DNS record based on current interface local IP address.

## Install
Clone this repo and copy `.env.example` to `.env` and fill in your details.

## How to use it as service
Create file `/etc/systemd/system/dnsupdate.service`
```
[Unit]
Description=Update DNS Script
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/dnsupdate/cf-update.sh
StandardOutput=append:/var/log/dns_update.log
StandardError=append:/var/log/dns_update.log
EnvironmentFile=/opt/dnsupdate/.env

[Install]
WantedBy=multi-user.target
```
```
sudo systemctl enable --now dnsupdate.service
```

## Add auto restart every day

```
crontab -e
```
```
0 3 * * * systemctl restart dnsupdate.service
```

## Debugging and logs
```
sudo journalctl -u dnsupdate.service
```
Log file is located at `/var/log/dns_update.log`
