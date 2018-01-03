
FROM ubuntu:latest


RUN apt-get update \
    && apt-get -y install software-properties-common ssh openssh-server



#Install Open JDK
RUN apt-add-repository "deb http://ftp.uk.debian.org/debian experimental main" \
    && apt-add-repository "deb http://ftp.uk.debian.org/debian sid main" \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8B48AD6246925553 \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010 

RUN apt-get update \
    && apt-get -y install  openjdk-7-jdk \
    && update-java-alternatives -s java-1.7.0-openjdk-amd64

ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre/





#Copy hadoop
COPY hbase-1.4.0-bin.tar.gz /usr/local/
WORKDIR /usr/local/
RUN tar -xf hbase-1.4.0-bin.tar.gz \
    && rm hbase-1.4.0-bin.tar.gz \
    && ln -s ./hbase-1.4.0 hbase

ENV PATH="/usr/local/hbase/bin:${PATH}"

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && chmod 0600 ~/.ssh/authorized_keys

#Config copy
COPY hbase-site.xml /usr/local/hbase/conf/
COPY hbase-env.sh /usr/local/hbase/conf/
COPY regionservers /usr/local/hbase/conf/
COPY backup-masters /usr/local/hbase/conf/


#Bypass interactive prompt
RUN echo "Host *"  >>/root/.ssh/config
RUN echo "StrictHostKeyChecking no" >> /root/.ssh/config



WORKDIR /bin/

ADD bootstrap_master.sh /bin/
RUN chmod +x bootstrap_master.sh

ADD bootstrap_region.sh /bin/
RUN chmod +x bootstrap_region.sh





EXPOSE 22 16010 16030

#Debug

#RUN apt-get install -y xinetd telnetd
#RUN apt-get install -y net-tools iputils-ping
