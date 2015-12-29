FROM centos

RUN yum -y install epel-release
RUN yum -y install cobbler cobbler-web tftp-server dhcp openssl pykickstart xinetd

RUN apachectl ; cobblerd ; cobbler get-loaders ; pkill cobblerd ; pkill httpd

ADD start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]