FROM centos

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ “/sys/fs/cgroup” ]

RUN yum -y install epel-release
RUN yum -y install cobbler cobbler-web tftp-server dhcp openssl pykickstart xinetd

RUN (cd /etc/xinetd.d/; for i in *; do [ $i == tftp ] || rm -f $i; done)

ADD start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
