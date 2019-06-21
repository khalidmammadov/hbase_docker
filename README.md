# APACHE HBASE ON DOCKER CONTAINERS

<p align="center" style="vertical-align: middle;">
     <img
      alt="Hbase"
      src="https://github.com/khalidmammadov/hbase_docker/raw/master/images/hbase.png"
      width="400"
    />
      <img
      alt="Docker"
      src="https://github.com/khalidmammadov/hbase_docker/raw/master/images/docker.png"
      width="400"
    />
</p>


## Overview
In this short article I am going to install HBASE distributed database on Docker containers and set underlying file system to HDFS which is configured beforehand ([see this post](https://github.com/khalidmammadov/hadoop_dist_docker))

Here I will create a distributed Hbase cluster with Master, Backup Master and two Region Servers with ZooKeeper. The Backup Master and one Region Server are going to share the same host (although it can also be separated). This set up follows official Hbase set up guide [“2.4. Advanced – Fully Distributed”](https://hbase.apache.org/book.html#quickstart_fully_distributed) from Apache web site.


Here is how it is going to look like at a the end:

|Container, Node Name|	Master|	ZooKeeper|	RegionServer
|---|---|---|---|
|192.168.1.40|yes|yes|no
|192.168.1.41|backup|yes|yes
|192.168.1.42|no|yes|yes|



## Preparation
As mentioned earlier I have already got my Hadoop cluster running so you should have as well.

Then we need to download Hbase from Apache web site. I am using 1.4.0 but you are free to chose version you like but you will also need to make appropriate updates in the Dockerfile.

So:

```
cd ~
mkdir -p docker/hbase.img
 
cd docker/hbase.img/
wget http://www-eu.apache.org/dist/hbase/1.4.0/hbase-1.4.0-bin.tar.gz
```
Now clone this git repository:

```
git clone  https://github.com/khalidmammadov/hbase_docker.git
```
This repository contains all required data.

```
Dockerfile	
backup-masters	
bootstrap_master.sh
bootstrap_region.sh
hbase-env.sh
hbase-site.xml
regionservers
run.sh
```
I will go through the list to explain what each one contains:

## Dockerfile

This is main Docker file that has got all the step by step instructions to build an image. The image is based on latest ubuntu image from Docker repos.  It sets up JAVA (Open JDK), installs HBASE, makes SSH passwordless for inner cluster communication for Hbase and open ports for connectivity.

### backup-masters

Here we set hostname or IP address of backup server. I have set it to 192.168.1.41 as per plan.

### hbase-env.sh

This file is executed before Hbase starts, so I set here location of JAVA_HOME.

```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
```

### hbase-site.xml

This file has all main parameters for the cluster set up. So, we first set Hbase directory, the ZooKeeper estate and data dir. As you can see I pointed the file stores to a HDFS on Hadoop cluster.

```
<property>
  <name>hbase.cluster.distributed</name>
  <value>true</value>
</property>
 
<property>
  <name>hbase.rootdir</name>
  <value>hdfs://192.168.1.30:9000/hbase</value>
</property>
 
<property>
  <name>hbase.zookeeper.quorum</name>
  <value>192.168.1.40,192.168.1.41,192.168.1.42</value>
</property>
 
<property>
  <name>hbase.zookeeper.property.dataDir</name>
  <value>hdfs://192.168.1.30:9000/zookeeper</value>
</property>
```

### regionservers

We need to list all RegionServers in this file as a separate line:

```
192.168.1.41
192.168.1.42
```

### bootstrap_region.sh

This script will be used for RegionServer containers to start SSH on start up.

### bootstrap_region.sh

This script starts Hbase cluster (also starts SSH).

 

## Building and Running

Before we start Hbase we need to build Docker image and define network parameters. We are going to run Docker build command in a second but before that make sure your build folder looks like below (if you did as described in Preparation section)

```
khalid@ubuntu:~/docker/hbase.img$ ll
total 109752
drwxrwxr-x  5 khalid khalid      4096 Jan  3 00:04 ./
drwxr-xr-x 11 khalid khalid      4096 Jan  1 15:33 ../
-rw-rw-r--  1 khalid khalid        13 Jan  2 22:51 backup-masters
-rw-rw-r--  1 khalid khalid       106 Jan  2 23:20 bootstrap_master.sh
-rw-rw-r--  1 khalid khalid        62 Jan  2 23:27 bootstrap_region.sh
-rw-rw-r--  1 khalid khalid      1581 Jan  2 23:59 Dockerfile
drwxrwxr-x  7 khalid khalid      4096 Jan  1 15:30 hbase-1.4.0/
-rw-rw-r--  1 khalid khalid 112324081 Dec  9 00:44 hbase-1.4.0-bin.tar.gz
-rw-r--r--  1 khalid khalid      7586 Jan  2 23:34 hbase-env.sh
-rw-r--r--  1 khalid khalid      1368 Jan  2 22:32 hbase-site.xml
-rw-r--r--  1 khalid khalid        26 Jan  2 23:58 regionservers
-rw-rw-r--  1 khalid khalid       527 Jan  3 00:04 run.sh
```

Now, lets build Docker image from current folder:

```
docker build -t hbase:0.6 .
```

Normally you should get successfully built result.

Verify image creation:

```
khalid@ubuntu:~$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hbase               0.6                 a211d1985471        21 hours ago        1.31GB
....
```

Now the image is ready and we can run Hbase with all required servers.
I have created a script to create and run servers on Docker containers as per below:

```
khalid@ubuntu:~/docker/hbase.img$ cat run.sh 
#clean
docker stop hbase_regionserver2 hbase_regionserver_backup hbase_master
 
docker ps -a| grep hbase| awk '{system("docker rm " $1)}'
 
 
#Run
docker run --name hbase_regionserver_backup -itd --net=pubnet \
      --ip=192.168.1.41 hbase:0.6 \
      /bin/bootstrap_region.sh
 
sleep 2
 
docker run --name hbase_regionserver2 -itd --net=pubnet \
      --ip=192.168.1.42 hbase:0.6 \
      /bin/bootstrap_region.sh
 
sleep 2
 
docker run --name hbase_master -itd \
      --net=pubnet --ip=192.168.1.40 hbase:0.6 \
      /bin/bootstrap_master.sh
```

Let me take through this script before executing it.
The first line stops any running containers. Then it deletes old containers. These are here mainly for development and testing purposes and deletes old containers before creating new ones.
Next comes actual run bit. Here I start Backup Master & Region Server container first from previously created hbase:0.6 image and give it a static IP in the local network. Also, it starts with a shell script as a entry point. In the entry point it start SSH server and opens a shell session.

Afterwards, I start second configured region server similarly on the same local network.
Finally, the Master server is started. It has similar execution signature apart from the entry point script. Here along side of creating SSH and opening shell session it actually start the Hbase and communicates through ssh protocol with other nodes/containers and starts them as well.

Lets start:

```
khalid@ubuntu:~/docker/hbase.img$ . run.sh 
hbase_regionserver2
hbase_regionserver_backup
hbase_master
c1a2f408db9d
954f7c910c11
7b8295f50c47
9c44fbe244caa4ddaf8ce45860cfb5fe7a6177df9d07810838d9f2625f110e35
792eb7a8c63327fb8dd29cd08b536ec6adc24dc89957ebad7b5738212a4089fd
a767f9ad5550b019ce573795b3b8e7696710ddc78eebc2cc299155b5669c205b
```

As you can see three containers started. (It first deletes old ones, you wouldn’t see first 6 lines if you are running this script first time)
Verify:

```
khalid@ubuntu:~/docker/hbase.img$ docker ps| grep hbase
a767f9ad5550        hbase:0.6           "/bin/bootstrap_mast…"   36 seconds ago      Up 35 seconds                           hbase_master
792eb7a8c633        hbase:0.6           "/bin/bootstrap_regi…"   38 seconds ago      Up 37 seconds                           hbase_regionserver2
9c44fbe244ca        hbase:0.6           "/bin/bootstrap_regi…"   41 seconds ago      Up 40 seconds                           hbase_regionserver_backup
```
Lets connect to each of the containers and see what processes are running:

```
khalid@ubuntu:~/docker/hbase.img$ docker attach hbase_regionserver2
root@792eb7a8c633:/bin# 
root@792eb7a8c633:/bin# jps
 325 Jps
 163 HRegionServer
 74 HQuorumPeer
root@792eb7a8c633:/bin# read escape sequence
 
khalid@ubuntu:~/docker/hbase.img$ docker attach hbase_regionserver_backup
root@9c44fbe244ca:/bin# 
root@9c44fbe244ca:/bin# jps
 157 HRegionServer
 228 HMaster
 464 Jps
74 HQuorumPeer
root@9c44fbe244ca:/bin# read escape sequence
 
khalid@ubuntu:~/docker/hbase.img$ docker attach hbase_master
root@a767f9ad5550:/usr/local/hbase/bin#  
root@a767f9ad5550:/usr/local/hbase/bin# jps
 175 HQuorumPeer
 458 Jps
 244 HMaster
root@a767f9ad5550:/usr/local/hbase/bin# read escape sequence
```
As you can see RegionServers are running on first two and there are two masters as well, one main and one backup.

Lets, connect to the web GUI and see how cluster looks like.
Navigate to http://192.168.1.40:16010/master-status page on your browser.

<p align="center">
     <img
      alt="Hbase"
      src="https://github.com/khalidmammadov/hbase_docker/raw/master/images/hbase_docker_ui.png"
      width="800"
    />
</p>

## Summary

In this article I have showed how it’s possible to run distributed Hbase database on Docker containers that uses Hadoop HDFS as a backend storage. Another, interesting thing here is that Hadoop itself also runs on Docker containers as well :).
See below my docker estate:

```
khalid@ubuntu:~/docker/hbase.img$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
09b3d4b7fe45        hbase:0.6           "/bin/bootstrap_mast…"   8 minutes ago       Up 8 minutes                            hbase_master
16e5e3d05bde        hbase:0.6           "/bin/bootstrap_regi…"   8 minutes ago       Up 8 minutes                            hbase_regionserver2
a2deb37afe83        hbase:0.6           "/bin/bootstrap_regi…"   8 minutes ago       Up 8 minutes                            hbase_regionserver_backup
5143d1836848        namenode:0.5        "/bin/bootstrap.sh"      5 days ago          Up 5 days                               namenode
1ee6a4a4c2c9        datanode:0.6        "/bin/bootstrap.sh"      10 days ago         Up 5 days                               serene_banach
a11c5a7a2b84        datanode:0.6        "/bin/bootstrap.sh"      10 days ago         Up 5 days                               suspicious_curie
bd29d2d53013        datanode:0.6        "/bin/bootstrap.sh"      10 days ago         Up 5 days                               brave_almeida
b1070470a710        datanode:0.6        "/bin/bootstrap.sh"      10 days ago         Up 5 days                               optimistic_lichterman
8e08ce2daecf        datanode:0.6        "/bin/bootstrap.sh"      10 days ago         Up 5 days                               dreamy_lamarr
.....
```
