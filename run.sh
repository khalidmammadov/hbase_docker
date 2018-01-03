docker stop hbase_regionserver2 hbase_regionserver_backup hbase_master

docker ps -a| grep hbase| awk '{system("docker rm " $1)}'




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
