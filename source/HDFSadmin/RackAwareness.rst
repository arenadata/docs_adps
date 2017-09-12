Настройка Rack Awareness на ADH
-------------------------------

.. |br| raw:: html

   <br />



Для настройки **Rack Awareness** на кластере **ADH** необходимо использовать следующие настройки:


1. Создание скрипта Rack Topology 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Hadoop** использует скрипты топологии для определения местоположения стойки узлов и применяет данную информацию для репликации данных блока в резервные стойки.

+ Создать сценарий топологии и файл данных. Сценарий топологии должен быть исполняемым. 

  **Пример сценария топологии**. Имя файла: *rack-topology.sh*
  
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



  **Пример файла данных топологии**. Имя файла: *rack_topology.data*
  
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

+ Скопировать оба этих файла в каталог */ etc / hadoop / conf* на всех узлах кластера;

+ Запустить скрипт *rack-topology.sh*, чтобы убедиться, что он возвращает правильную информацию о стойке для каждого хоста.



2. Добавление свойства Script Topology в core-site.xml
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+ Остановить HDFS;
+ Добавить в *core-site.xml* следующее свойство:
  ::
  
   <property>
     <name>net.topology.script.file.name</name> 
     <value>/etc/hadoop/conf/rack-topology.sh</value>
   </property>
  
  По умолчанию скрипт топологии обрабатывает до 100 заявок за запрос. Можно указать другое количество заявок в свойстве *net.topology.script.number.args*. Например:
  ::
  
   <property> 
     <name>net.topology.script.number.args</name> 
     <value>75</value>
   </property>
  
  
3. Перезапуск HDFS и MapReduce
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
