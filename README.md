# cf-dns-update
Simple Bash script to update Cloudflare DNS record based on current interface local IP address.

## How to use it as service

```
[Unit]
Description=Update DNS Script

[Service]
Type=oneshot
ExecStart=/bin/bash /path/to/your/script.sh

[Install]
WantedBy=multi-user.target
```
```
sudo systemctl enable --now update_dns.service
```

## Add auto restart every day

```
crontab -e
```
```
0 3 * * * systemctl restart update_dns.service
```
