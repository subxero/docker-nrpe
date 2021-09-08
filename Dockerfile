FROM registry.access.redhat.com/ubi8/ubi-init
RUN yum update -y;
RUN yum install -y gcc glibc glibc-common openssl openssl-devel wget make;
RUN wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.0.3/nrpe-4.0.3.tar.gz -P /tmp/;
RUN cd /tmp; tar zxvf nrpe-4.0.3.tar.gz; cd nrpe-4.0.3; ./configure --enable-command-args --with-nrpe-user=nagios --with-nrpe-group=nagios; make install-groups-users; make all; make install;
RUN make install-config; make install-init; systemctl enable nrpe; yum clean all;
RUN mkdir /etc/systemd/system/nrpe.service.d/; echo -e '[Service]\nRestart=always' > /etc/systemd/system/nrpe.service.d/nrpe.conf
EXPOSE 5666
CMD [ "/sbin/init" ]
