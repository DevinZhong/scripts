# shadowsocks

## shadowsocks-libev_debian.sh
### Feature
- enable TCP fast open
- enable udprelay mode
- enable onetime authentication
- start the server on boot
- use chacha20 as encryption

### How to use
```bash
su - root
wget https://raw.githubusercontent.com/DevinZhong/scripts/master/shadowsocks/shadowsocks-libev_debian.sh
bash shadowsocks-libev_debian.sh

# recommend
reboot
```