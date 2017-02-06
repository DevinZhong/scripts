# shadowsocks

## shadowsocks-libev_server.sh
### Required
- Linux distribution with Systemd supported

### Feature
- enable TCP fast open
- enable udprelay mode
- start the server on boot
- use chacha20 as encryption

### How to use
```bash
su - root
wget https://raw.githubusercontent.com/DevinZhong/scripts/master/shadowsocks/shadowsocks-libev_server.sh
chmod +x shadowsocks-libev_server.sh
./shadowsocks-libev_server.sh

# recommend
reboot
```