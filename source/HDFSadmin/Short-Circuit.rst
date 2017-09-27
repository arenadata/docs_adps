Режим локального чтения данных на HDFS
--------------------------------------

.. |br| raw:: html

   <br />
   

В **HDFS** чтение обычно проходит через **DataNode**. Таким образом, когда клиент запрашивает **DataNode** для чтения файла, **DataNode** считывает этот файл с диска и отправляет данные клиенту через сокет TCP. Так называемое "локальное чтение" читает в обход **DataNode**, позволяя клиенту непосредственно прочитать файл. Очевидно, что это возможно только в тех случаях, когда клиент находится вместе с данными. Локальное чтение обеспечивают значительное повышение производительности для многих приложений.



Необходимые компоненты
^^^^^^^^^^^^^^^^^^^^^^

Для настройки локального чтения данных необходимо включить *libhadoop.so*. Подробные сведения о включении библиотеки см. в `"Native Libraries" <http://hadoop.apache.org/docs/r2.3.0/hadoop-project-dist/hadoop-common/NativeLibraries.html>`_. 



Настройка локального чтения данных на HDFS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для настройки локального чтения данных на **HDFS**, необходимо в файл *hdfs-site.xml* добавить свойства, приведенные в таблице 14. Локальное чтение данных должно быть настроено как для **DataNode**, так и для клиента.


.. csv-table:: Табл. 14. Свойства для файла hdfs-site.xml
   :header: "Свойство", "Значение", "Описание"
   :widths: 15, 10, 25

   "dfs.client.read. |br| shortcircuit", "true", "При значении *true* включается режим локального чтения данных"
   "dfs.domain.socket. |br| path", "/var/lib/hadoop- |br| hdfs/ dn_socket", "Путь к сокету домена. В сообщениях при локальном чтении данных используется сокет домена UNIX. Это особый путь в файловой системе, позволяющий связываться клиенту и DataNodes. Необходимо установить путь к этому сокету. DataNode должен иметь возможность создать этот путь. С другой стороны, создание этого пути не должно быть возможным для любого пользователя, кроме пользователя hdfs или root. По этой причине часто используются пути в /var/run или /var/lib."
   "dfs.client.domain. |br| socket.data.traffic", "false", "Контролирует, будет ли обычный трафик данных передаваться через сокет домена UNIX. Функция не была сертифицирована релизами ADH, поэтому рекомендуется установить значение *false*"
   "dfs.client.use.legacy. |br| blockreader.local", "false", "Установка значения *false* указывает, что используется новая версия локального чтения (на основе HDFS-347). Эта версия поддерживается и рекомендуется для использования с ADH. Значение *true* означает, что используется старый режим локального чтения"
   "dfs.datanode.hdfs- |br| blocks-metadata. |br| enabled", "true", "Логический тип данных, который обеспечивает поддержку на стороне сервера DataNode для экспериментального DistributedFileSystem#getFileVBlockStorageLocations API"
   "dfs.client.file-block- |br| storage-locations. |br| timeout", "60", "Таймаут для параллельных RPC, сделанных в DistributedFileSystem#getFileBlockStorageLocations (в секундах). Это свойство устарело, но по-прежнему поддерживается для обратной совместимости"
   "dfs.client.file-block- |br| storage-locations. |br| timeout.millis", "60000", "Таймаут для параллельных RPC, сделанных в DistributedFileSystem#getFileBlockStorageLocations (в миллисекундах). Это свойство заменяет dfs.client.file-block-storage-locations.timeout и предлагает более точный уровень детализации"
   "dfs.client.read. |br| shortcircuit.skip. |br| checksum", "false", "Если этот параметр конфигурации установлен, локальное чтение будет пропускать контрольную сумму файлов. Обычно это не рекомендуется, но может быть полезно для специальных настроек. Может пригодиться, если есть собственные контрольные суммы файлов вне HDFS"
   "dfs.client.read. |br| shortcircuit.streams. |br| cache.size", "256", "DFSClient поддерживает кэш недавно открытых файловых дескрипторов. Параметр управляет размером кэша. При установке значения выше указанного будут использоваться дополнительные дескрипторы файлов, но они могут обеспечить лучшую производительность при рабочей нагрузке с большим количеством запросов"
   "dfs.client.read. |br| shortcircuit.streams. |br| cache.expiry.ms", "300000", "Контролирует минимальный промежуток времени нахождения файловых дескрипторов в контексте кэша клиента, прежде чем они могут быть закрыты (в миллисекундах)"


XML для вышеуказанных записей:
::
 <configuration>
  <property>
    <name>dfs.client.read.shortcircuit</name>
    <value>true</value>
  </property>
  
  <property>
    <name>dfs.domain.socket.path</name>
    <value>/var/lib/hadoop-hdfs/dn_socket</value>
  </property>
  
  <property>
    <name>dfs.client.domain.socket.data.traffic</name>
    <value>false</value>
  </property>
    
  <property>
    <name>dfs.client.use.legacy.blockreader.local</name>
    <value>false</value>
  </property>
      
  <property>
    <name>dfs.datanode.hdfs-blocks-metadata.enabled</name>
    <value>true</value>
  </property>
  
    <property>
    <name>dfs.client.file-block-storage-locations.timeout.millis</name>
    <value>60000</value>
  </property>
  
    <property>
    <name>dfs.client.read.shortcircuit.skip.checksum</name>
    <value>false</value>
  </property>
    
    <property>
    <name>dfs.client.read.shortcircuit.streams.cache.size</name>
    <value>256</value>
  </property>
    
    <property>
    <name>dfs.client.read.shortcircuit.streams.cache.expiry.ms</name>
    <value>300000</value>
  </property>
 </configuration>



























