Режим локального чтения данных 
================================


В **HDFS** чтение обычно проходит через *DataNode*. Таким образом, когда клиент запрашивает *DataNode* для чтения файла, *DataNode* считывает этот файл с диска и отправляет данные клиенту через сокет TCP. Так называемое "локальное чтение" читает в обход *DataNode*, позволяя клиенту непосредственно прочитать файл. Очевидно, что это возможно только в тех случаях, когда клиент находится в одном месте с данными. Локальное чтение обеспечивает значительное повышение производительности для многих приложений.

Для настройки локального чтения данных необходимо включить *libhadoop.so*. Подробные сведения о включении библиотеки приведены в `"Native Libraries" <http://hadoop.apache.org/docs/r2.3.0/hadoop-project-dist/hadoop-common/NativeLibraries.html>`_. 

Так же для настройки локального чтения данных на **HDFS** необходимо в файл *hdfs-site.xml* добавить свойства, приведенные далее. Локальное чтение данных должно быть настроено как для *DataNode*, так и для клиента.

+ ``dfs.client.read.shortcircuit``, значение *true* -- включение режима локального чтения данных;
+ ``dfs.domain.socket.path``, значение */var/lib/hadoop-hdfs/dn_socket* -- путь к сокету домена. В сообщениях при локальном чтении данных используется сокет домена UNIX. Это особый путь в файловой системе, позволяющий связываться клиенту и DataNodes. Необходимо установить путь к этому сокету. DataNode должен иметь возможность создать этот путь. С другой стороны, создание этого пути не должно быть возможным для любого пользователя, кроме пользователя *hdfs* или *root*. По этой причине часто используются пути в */var/run* или */var/lib*; 
+ ``dfs.client.domain.socket.data.traffic``, значение *false* -- контролирует, будет ли обычный трафик данных передаваться через сокет домена UNIX. Функция не была сертифицирована релизами ADH, поэтому рекомендуется установить значение *false*;
+ ``dfs.client.use.legacy.blockreader.local``, значение *false* -- установка значения *false* указывает, что используется новая версия локального чтения (на основе HDFS-347). Эта версия поддерживается и рекомендуется для использования с ADH. Значение *true* означает, что используется старый режим локального чтения;
+ ``dfs.datanode.hdfs-blocks-metadata.enabled``, значение *true* -- логический тип данных, который обеспечивает поддержку на стороне сервера DataNode для экспериментального *DistributedFileSystem#getFileVBlockStorageLocations* API;
+ ``dfs.client.file-block-storage-locations.timeout``, значение *60* -- таймаут для параллельных RPC, сделанных в  *DistributedFileSystem#getFileBlockStorageLocations* (в секундах). Это свойство устарело, но по-прежнему поддерживается для обратной совместимости;
+ ``dfs.client.file-block-storage-locations.timeout.millis``, значение *60000* -- таймаут для параллельных RPC, сделанных в  *DistributedFileSystem#getFileBlockStorageLocations* (в миллисекундах). Это свойство заменяет ``dfs.client.file-block-storage-locations.timeout`` и предлагает более точный уровень детализации;
+ ``dfs.client.read.shortcircuit.skip.checksum``, значение *false* -- если параметр конфигурации установлен, локальное чтение будет пропускать контрольную сумму файлов. Обычно это не рекомендуется, но может быть полезно для специальных настроек. Может пригодиться, если есть собственные контрольные суммы файлов вне HDFS;
+ ``dfs.client.read.shortcircuit.streams.cache.size``, значение *256* -- DFSClient поддерживает кэш недавно открытых файловых дескрипторов. Параметр управляет размером кэша. При установке значения выше указанного используются дополнительные дескрипторы файлов, но они могут обеспечить лучшую производительность при рабочей нагрузке с большим количеством запросов;
+ ``dfs.client.read.shortcircuit.streams.cache.expiry.ms``, значение *300000* -- контролирует минимальный промежуток времени нахождения файловых дескрипторов в контексте кэша клиента, прежде чем они могут быть закрыты (в миллисекундах).


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

