Команды Shell
=============

**Hadoop** включает в себя различные shell-подобные команды, напрямую взаимодействующие с **HDFS** и другими файловыми системами, которые поддерживает **Hadoop**. Команда ``bin/hdfs dfs -help`` выводит список команд, поддерживаемых оболочкой **Hadoop**, а ``bin/hdfs dfs -help command-name`` отображает более подробную справку. Команды поддерживают большинство обычных операций файловой системы, таких как копирование файлов, изменение прав доступа к файлам и т.д. Но также поддерживаются некоторые специфические операции **HDFS**, например, изменение репликации файлов.

Команда ``bin/hdfs dfsadmin`` поддерживает операции, связанные с администрированием **HDFS**, а ``bin/hdfs dfsadmin -help`` выводит список всех поддерживаемых в данный момент команд, например:

* ``-report`` -- сообщает основную статистику HDFS. Некоторые из этих сведений также доступны на главной странице NameNode;

* ``-safemode`` -- хотя обычно это не требуется, администратор может вручную войти или покинуть режим Safemode;

* ``-finalizeUpgrade`` -- удаляет предыдущую резервную копию кластера, созданную во время последнего обновления;

* ``-refreshNodes`` -- обновляет интерфейс NameNode с набором узлов DataNode, разрешенным подключаться к NameNode. По умолчанию NameNodes повторно считывает имена узлов DataNode в файле, определенном dfs.hosts и dfs.hosts.exclude. Хосты в dfs.hosts -- это узлы данных, которые являются частью кластера. Если в dfs.hosts есть записи, то только хосты в нем могут регистрироваться с помощью NameNode. Записи в dfs.hosts.exclude -- это узлы данных, которые должны быть выведены из эксплуатации. Альтернативно, если для *dfs.namenode.hosts.provider.classname* задано значение *org.apache.hadoop.hdfs.server.blockmanagement.CombinedHostFileManager*, все хосты include и exclude указываются в файле JSON, заданном dfs.hosts. Вывод из эксплуатации завершает DataNodes, когда все их записи среплицированы в другие DataNodes, при этом списанные узлы не выключаются автоматически и не выбираются для записи новых реплик;

* ``-printTopology`` -- вывод топологии кластера. Отображение дерева стоек и узлов данных, прикрепленных к трекам, как показано в NameNode.

Пример использования:

::

     hdfs dfsadmin [-report [-live] [-dead] [-decommissioning] [-enteringmaintenance] [-inmaintenance]]
     hdfs dfsadmin [-safemode enter | leave | get | wait | forceExit]
     hdfs dfsadmin [-saveNamespace [-beforeShutdown]]
     hdfs dfsadmin [-rollEdits]
     hdfs dfsadmin [-restoreFailedStorage true |false |check]
     hdfs dfsadmin [-refreshNodes]
     hdfs dfsadmin [-setQuota <quota> <dirname>...<dirname>]
     hdfs dfsadmin [-clrQuota <dirname>...<dirname>]
     hdfs dfsadmin [-setSpaceQuota <quota> [-storageType <storagetype>] <dirname>...<dirname>]
     hdfs dfsadmin [-clrSpaceQuota [-storageType <storagetype>] <dirname>...<dirname>]
     hdfs dfsadmin [-finalizeUpgrade]
     hdfs dfsadmin [-rollingUpgrade [<query> |<prepare> |<finalize>]]
     hdfs dfsadmin [-upgrade [query | finalize]
     hdfs dfsadmin [-refreshServiceAcl]
     hdfs dfsadmin [-refreshUserToGroupsMappings]
     hdfs dfsadmin [-refreshSuperUserGroupsConfiguration]
     hdfs dfsadmin [-refreshCallQueue]
     hdfs dfsadmin [-refresh <host:ipc_port> <key> [arg1..argn]]
     hdfs dfsadmin [-reconfig <namenode|datanode> <host:ipc_port> <start |status |properties>]
     hdfs dfsadmin [-printTopology]
     hdfs dfsadmin [-refreshNamenodes datanodehost:port]
     hdfs dfsadmin [-getVolumeReport datanodehost:port]
     hdfs dfsadmin [-deleteBlockPool datanode-host:port blockpoolId [force]]
     hdfs dfsadmin [-setBalancerBandwidth <bandwidth in bytes per second>]
     hdfs dfsadmin [-getBalancerBandwidth <datanode_host:ipc_port>]
     hdfs dfsadmin [-fetchImage <local directory>]
     hdfs dfsadmin [-allowSnapshot <snapshotDir>]
     hdfs dfsadmin [-disallowSnapshot <snapshotDir>]
     hdfs dfsadmin [-shutdownDatanode <datanode_host:ipc_port> [upgrade]]
     hdfs dfsadmin [-evictWriters <datanode_host:ipc_port>]
     hdfs dfsadmin [-getDatanodeInfo <datanode_host:ipc_port>]
     hdfs dfsadmin [-metasave filename]
     hdfs dfsadmin [-triggerBlockReport [-incremental] <datanode_host:ipc_port>]
     hdfs dfsadmin [-listOpenFiles [-blockingDecommission] [-path <path>]]
     hdfs dfsadmin [-help [cmd]]

* ``-report [-live] [-dead] [-decommissioning] [-enteringmaintenance] [-inmaintenance]`` -- сообщает основную информацию и статистику файловой системы. Использование *dfs* может отличаться от *du*, поскольку оно измеряет необработанное пространство, используемое репликацией, контрольными суммами, снапшотами и т.д. на всех DN. Дополнительные флаги можно применять для фильтрации списка отображаемых DataNodes;

* ``-safemode enter|leave|get|wait|forceExit`` -- команда обслуживания безопасного режима Safe mode -- состояние Namenode, в котором он:

  * Не принимает изменения в пространстве имен (только для чтения);
  * Не копирует и не удаляет блоки.

  Безопасный режим вводится автоматически при запуске Namenode и автоматически выключается, когда настроенный минимальный процент блоков удовлетворяет условию минимальной репликации. Если Namenode обнаруживает какую-либо аномалию, он остается в безопасном режиме, пока проблема не будет решена. Если эта аномалия является следствием преднамеренного действия, администратор может использовать команду ``-safemode forceExit`` для принудительного выхода из безопасного режима. Случаи, когда это может потребоваться:

  * Метаданные Namenode не согласованы. Если Namenode обнаруживает, что метаданные были изменены вне диапазона и могут привести к потере данных, то Namenode переходит в состояние *forceExit*. В этот момент пользователь может либо перезапустить Namenode с правильными файлами метаданных, либо использовать *forceExit* (если потеря данных допустима);
  * Откат приводит к тому, что метаданные заменяются, и в редких случаях он может вызвать режим принудительного выхода из безопасного режима в Namenode.
  
  Безопасный режим можно ввести вручную, но тогда отключить его можно будет тоже только вручную;

* ``-saveNamespace [-beforeShutdown]`` -- сохранение текущего пространства имен в каталогах хранилища и сброс журнала изменений. Требуется безопасный режим. Если задана опция *beforeShutdown*, NameNode делает контрольную точку тогда и только тогда, когда в течение временного окна контрольная точка не была установлена (настраиваемое количество периодов контрольных точек). Обычно функция используется перед закрытием NameNode для предотвращения возможного повреждения fsimage или журнала изменений;

* ``-rollEdits`` -- откат журнала редактирования на активном NameNode;

* ``-restoreFailedStorage true|false|check`` -- включение/выключение автоматической попытки восстановления неудачных реплик хранилища. Если сбойное хранилище снова станет доступным, система попытается восстановить журнал изменений и/или fsimage во время контрольной точки. Опция *check* возвращает текущую настройку;

* ``-refreshNodes`` -- повторное чтение хостов и исключение файлов для обновления набора Datanodes, которым разрешено подключаться к Namenode, и тех, которые должны быть выведены из эксплуатации или повторно введены;

* ``-finalizeUpgrade`` -- завершение обновления HDFS. Datanodes удаляют свои рабочие каталоги предыдущей версии, после чего Namenode делает то же самое. На этом процесс обновления завершается;

* ``-upgrade query|finalize`` -- query: запрос текущего состояния обновления; finalize: завершить обновление HDFS (эквивалентно *finalizeUpgrade*);

* ``-refreshServiceAcl`` -- перезагрузка файла политики авторизации на уровне сервиса;

* ``-refreshUserToGroupsMappings`` -- обновить сопоставления пользователей и групп;

* ``-refreshSuperUserGroupsConfiguration`` -- обновить сопоставления proxy-групп суперпользователя;

* ``-refreshCallQueue`` -- перезагрузить очередь вызовов из конфига;

* ``-refresh <host:ipc_port> <key> [arg1..argn]`` -- запуск обновления во время выполнения ресурса, указанного <key> на <host: ipc_port>. Все остальные аргументы после отправляются на хост;

* ``-reconfig <datanode |namenode> <host:ipc_port> <start|status|properties>`` -- запуск реконфигурации, либо получение статуса текущей реконфигурации, либо получение списка реконфигурируемых свойств. Второй параметр указывает тип узла;

* ``-printTopology`` -- отобразить дерево стоек и их узлов, как передается в Namenode;

* ``-refreshNamenodes datanodehost:port`` -- перезагрузка файлов конфигурации для указанного datanode, прекращение обслуживания удаленных пулов блоков и старт обслуживания новых пулов блоков;

* ``-getVolumeReport datanodehost:port`` -- получить отчет об объеме для указанного datanode;

* ``-deleteBlockPool datanode-host:port blockpoolId [force]`` -- при принудительном вводе каталог пула блоков для указанного идентификатора блока данных на указанном datanode удаляется вместе с его содержимым, в противном случае каталог удаляется, только если он пуст. Команда не будет выполнена, если datanode все еще обслуживает пул блоков. Для выключения сервиса пула блоков на datanode использовать *refreshNamenodes*;

* ``-setBalancerBandwidth <bandwidth in bytes per second>`` -- изменение пропускной способности сети, используемой каждым datanode во время балансировки блоков HDFS. <bandwidth> -- максимальное число байтов в секунду, которое будет использоваться каждой datanode. Это значение переопределяет параметр *dfs.datanode.balance.bandwidthPerSec*. При этом новое значение не является постоянным в узле DataNode;

* ``-getBalancerBandwidth <datanode_host:ipc_port>`` -- получение пропускной способности сети (в байтах в секунду) для указанного datanode. Это максимальная пропускная способность сети, используемая datanode при балансировке блоков HDFS;

* ``-fetchImage <local directory>`` -- загрузка последнего fsimage из NameNode и сохранение его в указанном локальном каталоге;

* ``-allowSnapshot <snapshotDir>`` -- разрешение на создание снапшотов каталога. Если операция завершается успешно, каталог становится моментальным снимком;

* ``-disallowSnapshot <snapshotDir>`` -- запрет на создание снапшотов каталога, который будет создан. Все снимки каталога должны быть удалены перед включением функции;

* ``-shutdownDatanode <datanode_host:ipc_port> [upgrade]`` -- отправить запрос на отключение для указанного datanode;

* ``-evictWriters <datanode_host:ipc_port>`` -- заставляет datanode выселить всех клиентов, которые пишут блок. Функция полезна, когда эксплуатация приостановлена из-за медленных писателей;

* ``-getDatanodeInfo <datanode_host:ipc_port>`` -- получение информации о указанном datanode;

* ``-metasave filename`` -- сохранение основных структур данных Namenode в *filename* в каталоге, указанном свойством *hadoop.log.dir*. Файл *filename* перезаписывается, если уже существует. При этом *filename* содержит одну строку для каждого из следующих:

  * Сообщения heartbeat узлов Datanodes с Namenode;
  * Ожидающие репликации блоки;
  * Копируемые в настоящее время блоки;
  * Ожидающие удаления блоки.

* ``-triggerBlockReport [-incremental] <datanode_host:ipc_port>`` -- запуск отчета о блокировке для указанного datanode. Если указано значение *incremental*, то отчет о полном блоке;

* ``-listOpenFiles [-blockingDecommission] [-path <path>]`` -- список всех открытых файлов, которыми в данный момент управляет NameNode, а также имя клиента и клиентский компьютер, к которому они обращаются. Список открытых файлов фильтруется по заданному типу и пути;

* ``-help [cmd]`` -- справка для указанной команды или для всех команд, если ни одна не указана.

