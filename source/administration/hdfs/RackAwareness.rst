Настройка Rack Awareness 
==========================

Настройка **Rack Awareness** на кластере **ADH** осуществляется в несколько шагов:

+ `Создание скрипта Rack Topology`_;
+ `Добавление свойства Script Topology в core-site.xml`_;
+ `Перезапуск HDFS и MapReduce`_;
+ `Контроль работы Rack Awareness`_;


Создание скрипта Rack Topology 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Hadoop** использует скрипты топологии для определения местоположения стойки узлов и применяет эту информацию для репликации данных блока в резервные стойки.

+ Создать скрипт топологии и файл данных. Скрипт топологии должен быть исполняемым. 

  Пример скрипта топологии. Имя файла: *rack-topology.sh*.
  
  ::
  
   #!/bin/bash 
    
   # Adjust/Add the property "net.topology.script.file.name" 
   # to core-site.xml with the "absolute" path the this
   # file.  ENSURE the file is "executable". 
    
   # Supply appropriate rack prefix
   RACK_PREFIX=default
    
   # To test, supply a hostname as script input:
   if [ $# -gt 0 ]; then
    
   CTL_FILE=${CTL_FILE:-"rack_topology.data"} 
    
   HADOOP_CONF=${HADOOP_CONF:-"/etc/hadoop/conf"} 
    
   if [ ! -f ${HADOOP_CONF}/${CTL_FILE} ]; then
     echo -n "/$RACK_PREFIX/rack "
     exit 0
   fi 
    
   while [ $# -gt 0 ] ; do 
     nodeArg=$1
     exec< ${HADOOP_CONF}/${CTL_FILE}
     result="" 
     while read line ; do
       ar=( $line )
       if [ "${ar[0]}" = "$nodeArg" ] ; then
         result="${ar[1]}"
       fi
     done 
     shift
     if [ -z "$result" ] ; then 
       echo -n "/$RACK_PREFIX/rack " 
     else 
       echo -n "/$RACK_PREFIX/rack_$result "
     fi
   done
    
   else 
     echo -n "/$RACK_PREFIX/rack " 
   fi 



  Пример файла данных топологии. Имя файла: *rack_topology.data*.
  
  ::
  
   # This file should be: 
   #  - Placed in the /etc/hadoop/conf directory 
   #    - On the Namenode (and backups IE: HA, Failover, etc)
   #    - On the Job Tracker OR Resource Manager (and any Failover JT's/RM's)  
   # This file should be placed in the /etc/hadoop/conf directory.
  
   # Add Hostnames to this file. Format <host ip> <rack_location> 
   192.0.2.0 01
   192.0.2.1 02 
   192.0.2.2 03 

+ Скопировать оба этих файла в каталог */etc/hadoop/conf* на всех узлах кластера;

+ Запустить скрипт *rack-topology.sh*, чтобы убедиться, что он возвращает правильную информацию о стойке для каждого хоста.



Добавление свойства Script Topology в core-site.xml
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+ Остановить HDFS;

+ Добавить в *core-site.xml* следующее свойство:
  ::
  
   <property>
     <name>net.topology.script.file.name</name> 
     <value>/etc/hadoop/conf/rack-topology.sh</value>
   </property>
  
  По умолчанию скрипт топологии обрабатывает до *100* заявок за запрос. Можно указать другое количество заявок в свойстве *net.topology.script.number.args*. Например:
  ::
  
   <property> 
     <name>net.topology.script.number.args</name> 
     <value>75</value>
   </property>
  


Перезапуск HDFS и MapReduce
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Перезапустить **HDFS** и **MapReduce**.



Контроль работы Rack Awareness
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

После запуска сервисов для проверки активации **Rack Awareness** можно использовать следующие способы:

+ Просмотреть журналы NameNode, расположенные в */var/log/hadoop/hdfs/* (например: *hadoop-hdfs-namenode-sandbox.log*). Должна быть следующая запись:
  ::
   014-01-13 15:58:08,495 INFO org.apache.hadoop.net.NetworkTopology: Adding a new node: /rack01/<ipaddress>
   
+ Команда Hadoop *fsck* должна возвращать на подобии следующего (в случае двух стоек):
  ::
  
   Status: HEALTHY 
   Total size: 123456789 B 
   Total dirs: 0 
   Total files: 1 
   Total blocks (validated): 1 (avg. block size 123456789 B) 
   Minimally replicated blocks: 1 (100.0 %) 
   Over-replicated blocks: 0 (0.0 %) 
   Under-replicated blocks: 0 (0.0 %) 
   Mis-replicated blocks: 0 (0.0 %) 
   Default replication factor: 3 
   Average block replication: 3.0 
   Corrupt blocks: 0 
   Missing replicas: 0 (0.0 %) 
   Number of data-nodes: 40 
   Number of racks: 2 
   FSCK ended at Mon Jan 13 17:10:51 UTC 2014 in 1 milliseconds

+ Команда Hadoop *dfsadmin -report* возвращает отчет, содержащий имя стойки рядом с каждой машиной. Отчет должен выглядеть примерно следующим образом (частично):
  ::
   [bsmith@hadoop01 ~]$ sudo -u hdfs hadoop dfsadmin -report 
   Configured Capacity: 19010409390080 (17.29 TB)
   Present Capacity: 18228294160384 (16.58 TB)
   DFS Remaining: 5514620928000 (5.02 TB)
   DFS Used: 12713673232384 (11.56 TB) DFS Used%: 69.75%
   Under replicated blocks: 181
   Blocks with corrupt replicas: 0 
   Missing blocks: 0
   
   ------------------------------------------------- 
   Datanodes available: 5 (5 total, 0 dead)
   
   Name: 192.0.2.0:50010 (h2d1.phd.local)
   Hostname: h2d1.phd.local
   Rack: /default/rack_02
   Decommission Status : Normal
   Configured Capacity: 15696052224 (14.62 GB)
   DFS Used: 314380288 (299.82 MB)
   Non DFS Used: 3238612992 (3.02 GB)
   DFS Remaining: 12143058944 (11.31 GB)
   DFS Used%: 2.00%
   DFS Remaining%: 77.36%
   Configured Cache Capacity: 0 (0 B)
   Cache Used: 0 (0 B)
   Cache Remaining: 0 (0 B)
   Cache Used%: 100.00%
   Cache Remaining%: 0.00%
   Last contact: Thu Jun 12 11:39:51 EDT 2014
  
