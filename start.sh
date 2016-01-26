#!/bin/bash
shopt -s nocasematch

function get_yes_no {
    [[ "$1" =~ true ]] && return 0
    [[ "$1" =~ yes ]] && return 0
    [ "$1" = 1 ] && return 0
    [[ "$1" =~ false ]] && return 1
    [[ "$1" =~ no ]] && return 1
    [ "$1" = 0 ] && return 1
    echo "Variable does not have predefined value (0/1, true/false, yes/no)" >&2
    exit 1
}

# recreating files in case of empty volumes attached
if rpm -V cobbler | grep -q missing; then
    yum reinstall -q -y cobbler
elif rpm -V cobbler-web | grep -q missing; then
   yum reinstall -q -y cobbler-web
elif rpm -V tftp-server | grep -q missing; then
   yum reinstall -q -y tftp-server
elif rpm -V dhcp | grep -q missing; then
   yum reinstall -q -y dhcp
fi


# General settings
if [ "$SERVER_ADDR" ]; then
    sed -i "s/^server: .*/server: $SERVER_ADDR/g" /etc/cobbler/settings
fi
if [ "$MANAGE_RSYNC" ]; then
    get_yes_no "$MANAGE_RSYNC" \
        && sed -i "s/^manage_rsync: .*/manage_rsync: 1/g" /etc/cobbler/settings \
        || sed -i "s/^manage_rsync: .*/manage_rsync: 0/g" /etc/cobbler/settings
fi
if [ "$CRYPTED_PASSWD_FILE" ]; then
    [ -f "$CRYPTED_PASSWD_FILE" ] && grep -qP '^\$1\$.{31}' "$CRYPTED_PASSWD_FILE" \
        sed -i "s#^default_password_crypted.*#default_password_crypted: \"$(cat "$pass_file")\"#g" /etc/cobbler/settings \
        || ( echo "Password file is either not mounted as volume or is not crypted" >&2; exit 1 )
fi


# TFTP
if [ "$MANAGE_TFTP" ]; then
    get_yes_no "$MANAGE_TFTP" \
        && sed -i "s/^manage_tftpd: .*/manage_tftpd: 1/g" /etc/cobbler/settings \
        || sed -i "s/^manage_tftpd: .*/manage_tftpd: 0/g" /etc/cobbler/settings
fi
if [ "$ENABLE_XINET_TFTP" ]; then
    get_yes_no "$ENABLE_XINET_TFTP" \
        && sed -ri "s/^([ \t]*disable[ \t]*=).*/\1 no" /etc/xinet.d/tftp \
        || sed -i "s/^([ \t]*disable[ \t]*=).*/\1 yes" /etc/xinet.d/tftp
fi
if [ "$PXE_ONCE" ]; then
    get_yes_no "$PXE_ONCE" \
        && sed -i "s/^pxe_just_once: .*/pxe_just_once: 1/g" /etc/cobbler/settings \
        || sed -i "s/^pxe_just_once: .*/pxe_just_once: 0/g" /etc/cobbler/settings
fi
if [ "$TFTP_SERVER_ADDR" ]; then
    sed -i "s/^next_server: .*/next_server: $SERVER_ADDR/g" /etc/cobbler/settings
fi


# DHCP
if [ "$MANAGE_DHCP" ]; then
    get_yes_no "$MANAGE_DHCP" \
        && sed -i "s/^manage_dhcp: .*/manage_dhcp: 1/g" /etc/cobbler/settings \
        || sed -i "s/^manage_dhcp: .*/manage_dhcp: 0/g" /etc/cobbler/settings
fi
if [ "$DHCP_SUBNET" ]; then
    sed -ri "s/^([ \t]*subnet) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_SUBNET/g" /etc/cobbler/dhcp.template
fi
if [ "$DHCP_NETMASK" ]; then
    sed -ri "s/^([ \t]*subnet.*netmask) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_NETMASK/g" /etc/cobbler/dhcp.template
    sed -ri "s/^([ \t]*option subnet-mask.*) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_NETMASK/g" /etc/cobbler/dhcp.template
fi
if [ "$DHCP_ROUTERS" ]; then
    sed -ri "s/^([ \t]*option routers.*) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_ROUTERS/g" /etc/cobbler/dhcp.template
fi
if [ "$DHCP_NAME_SERVERS" ]; then
    sed -ri "s/^([ \t]*option domain-name-servers.*) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_NAME_SERVERS/g" /etc/cobbler/dhcp.template
fi
if [ "$DHCP_DYN_RANGE" ]; then
    sed -ri "s/^([ \t]*option range dynamic-bootp.*) [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/\1 $DHCP_DYN_RANGE/g" /etc/cobbler/dhcp.template
fi


# DNS
if [ "$MANAGE_DNS" ]; then
    get_yes_no "$MANAGE_DNS" \
        && sed -i "s/^manage_dns: .*/manage_dns: 1/g" /etc/cobbler/settings \
        || sed -i "s/^manage_dns: .*/manage_dns: 0/g" /etc/cobbler/settings
fi
if [ "$DNS_FORWARD_ZONES" ]; then
    sed -i "s/^manage_forward_zones: .*/manage_forward_zones: [$DNS_FORWARD_ZONES]/g" /etc/cobbler/settings
fi
if [ "$DNS_REVERSE_ZONES" ]; then
    sed -i "s/^manage_reverse_zones: .*/manage_reverse_zones: [$DNS_REVERSE_ZONES]/g" /etc/cobbler/settings
fi


# SERVICES
START_HTTPD="${START_HTTPD:-1}"
START_DHCPD="${START_DHCPD:-1}"
START_NAMED="${START_NAMED:-1}"
START_XINTED="${START_XINTED:-1}"
START_COBBLERD="${START_COBBLERD:-1}"
GET_LOADERS="${GET_LOADERS:-1}"
SYNC_COBBLER="${SYNC_COBBLER:-1}"

get_yes_no "$START_HTTPD" && systemctl enable httpd
get_yes_no "$START_DHCPD" && systemctl enable dhcpd
get_yes_no "$START_NAMED" && systemctl enable named
get_yes_no "$START_XINTED" && systemctl enable xinetd
get_yes_no "$START_COBBLERD" && systemctl enable cobblerd

exec /usr/sbin/init