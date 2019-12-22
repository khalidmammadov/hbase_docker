#Clean
docker stop hbase_regionserver2 hbase_regionserver_backup hbase_master

docker ps -a| grep hbase| awk '{system("docker rm " $1)}'



#Run
docker run \
      --name hbase_regionserver_backup \
      --hostname hbase_regionserver_backup \
      -itd \
      --net=hadoop.net \
      hbase:0.1 \
      /bin/bootstrap_region.sh

sleep 2

docker run \
      --name hbase_regionserver2 \
      --hostname hbase_regionserver2 \
      -itd \
      --net=hadoop.net \
      hbase:0.1 \
      /bin/bootstrap_region.sh

sleep 2

docker run \
      --name hbase_master \
      --hostname hbase_master \
      -itd \
      --net=hadoop.net hbase:0.1 \
      /bin/bootstrap_master.sh
