Настройка Rack Awareness на ADH
-------------------------------

.. |br| raw:: html

   <br />



Для настройки **Rack Awareness** на кластере **ADH** необходимо использовать следующие настройки:


1. Создание скрипта Rack Topology 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Hadoop** использует скрипты топологии для определения местоположения стойки узлов и применяет данную информацию для репликации данных блока в резервные стойки.

+ Создать сценарий топологии и файл данных. Сценарий топологии должен быть исполняемым. 

  **Пример сценария топологии**. Имя файла: *rack-topology.sh*:
  
  :command:`#!/bin/bash` |br| 

  :command:`# Adjust/Add the property "net.topology.script.file.name"` |br| 
  :command:`# to core-site.xml with the "absolute" path the this` |br| 
  :command:`# file.  ENSURE the file is "executable".` |br| 
  
  :command:`# Supply appropriate rack prefix` |br| 
  :command:`RACK_PREFIX=default` |br| 
  
  :command:`# To test, supply a hostname as script input:` |br| 
  :command:`if [ $# -gt 0 ]; then` |br| 
  
  :command:`CTL_FILE=${CTL_FILE:-"rack_topology.data"}` |br| 
  
  :command:`HADOOP_CONF=${HADOOP_CONF:-"/etc/hadoop/conf"}` |br|  
  
  :command:`if [ ! -f ${HADOOP_CONF}/${CTL_FILE} ]; then` |br| 
    :command:`echo -n "/$RACK_PREFIX/rack "` |br| 
    :command:`exit 0` |br| 
  :command:`fi` |br| 
  
  :command:`while [ $# -gt 0 ] ; do` |br| 
    :command:`nodeArg=$1` |br| 
    :command:`exec< ${HADOOP_CONF}/${CTL_FILE}` |br| 
    :command:`result=""` |br| 
    :command:`while read line ; do` |br| 
      :command:`ar=( $line )` |br| 
      :command:`if [ "${ar[0]}" = "$nodeArg" ] ; then` |br| 
        :command:`result="${ar[1]}"` |br| 
      :command:`fi` |br| 
    :command:`done` |br| 
    :command:`shift` |br| 
    :command:`if [ -z "$result" ] ; then` |br| 
      :command:`echo -n "/$RACK_PREFIX/rack "` |br| 
    :command:`else` |br| 
      :command:`echo -n "/$RACK_PREFIX/rack_$result "` |br| 
    :command:`fi` |br| 
  :command:`done` |br| 
  
  :command:`else` |br| 
    :command:`echo -n "/$RACK_PREFIX/rack "` |br| 
  :command:`fi` |br| 

  **Пример файла данных топологии**. Имя файла: *rack_topology.data*:
  
  :command:`# This file should be:` |br| 
  :command:`#  - Placed in the /etc/hadoop/conf directory` |br| 
  :command:`#    - On the Namenode (and backups IE: HA, Failover, etc)` |br| 
  :command:`#    - On the Job Tracker OR Resource Manager (and any Failover JT's/RM's)` |br|  
  :command:`# This file should be placed in the /etc/hadoop/conf directory.` |br| 
  
  :command:`# Add Hostnames to this file. Format <host ip> <rack_location>` |br| 
  :command:`192.0.2.0 01` |br| 
  :command:`192.0.2.1 02` |br| 
  :command:`192.0.2.2 03` |br| 
|br|
+ Скопировать оба этих файла в каталог */ etc / hadoop / conf* на всех узлах кластера;

+ Запустить скрипт *rack-topology.sh*, чтобы убедиться, что он возвращает правильную информацию о стойке для каждого хоста.





 **Пример файла данных топологии**. Имя файла: *rack_topology.data*::
  
  # This file should be: 
  #  - Placed in the /etc/hadoop/conf directory 
  #    - On the Namenode (and backups IE: HA, Failover, etc)
  #    - On the Job Tracker OR Resource Manager (and any Failover JT's/RM's)  
  # This file should be placed in the /etc/hadoop/conf directory.
  
  # Add Hostnames to this file. Format <host ip> <rack_location> 
  192.0.2.0 01
  192.0.2.1 02 
  192.0.2.2 03 
|br|
+ Скопировать оба этих файла в каталог */ etc / hadoop / conf* на всех узлах кластера;

+ Запустить скрипт *rack-topology.sh*, чтобы убедиться, что он возвращает правильную информацию о стойке для каждого хоста.


2. Добавление свойства Script Topology в core-site.xml
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



