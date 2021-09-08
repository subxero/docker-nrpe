FROM registry.access.redhat.com/ubi8/ubi-init
RUN yum update -y;
RUN yum install -y gcc glibc glibc-common openssl openssl-devel wget make gettext automake autoconf net-snmp;
#net-snmp-utils perl-Net-SNMP;
RUN wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.0.3/nrpe-4.0.3.tar.gz -P /tmp/; wget https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz -P /tmp/;
RUN cd /tmp; tar zxvf nrpe-4.0.3.tar.gz; cd nrpe-4.0.3; ./configure --enable-command-args --with-nrpe-user=nagios --with-nrpe-group=nagios; make install-groups-users; make all; make install;
RUN cd /tmp; tar zxvf nagios-plugins-2.2.1.tar.gz; cd nagios-plugins-2.2.1; ./configure; make; make install;
RUN rm -rf /tmp/nrpe-4.0.3; rm -rf /tmp/nagios-plugins-2.2.1;
RUN make install-config; make install-init; systemctl enable nrpe; yum clean all;
RUN mkdir /etc/systemd/system/nrpe.service.d/; echo -e '[Service]\nRestart=always' > /etc/systemd/system/nrpe.service.d/nrpe.conf;
EXPOSE 5666
CMD [ "/sbin/init" ]
