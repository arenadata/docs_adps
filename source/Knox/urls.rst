Доступ к внутренним сервисам Hadoop
=======================================


Настройка доступа к внутреннему сервису **Hadoop** через **Knox Gateway** осуществляется в два шага:

1. Необходимо изменить файл шлюза *$gateway/conf/topologies$cluster-name.xml*, добавив для каждого сервиса **Hadoop** запись, аналогичную следующей:

  ::
  
   <topology>
       <gateway>
        ...
        </gateway>
        <service>
            <role> $service_name </role>
            <url> $schema://$hostname:$port</url>
        </service>
   </topology>

Где:

+ *$service_name* -- название сервиса -- *AMBARI*, *AMBARIUI*, *ATLAS*, *HIVE*, *JOBTRACKER*, *NAMENODE*, *OOZIE*, *RANGER*, *RANGERUI*, *RESOURCEMANAGER*, *WEBHBASE*, *WEBHCAT*, *WEBHDFS*, *ZEPPELINUI* или *ZEPPELINWS*;
+ *<url>* -- полный внутренний URL-адрес кластера для доступа к сервису, включая:

  + *$schema* -- протокол сервиса;
  + *$hostname* -- разрешенное имя внутреннего узла;
  + *$port* -- порт прослушивания сервиса.

2. Сохранить файл. При этом шлюз создает новый WAR-файл с измененной временной меткой в *$gateway/data/deployments*.

Перезапуск сервера **Knox** после внесения изменений в топологию или сервисы кластера **Hadoop** не требуется.


