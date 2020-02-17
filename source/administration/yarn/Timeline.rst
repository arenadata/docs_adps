YARN Timeline Service v.2
==========================

Краткий обзор
--------------

**YARN Timeline Service v.2** -- это следующая крупная итерация **Timeline Server** после *v.1* и *v.1.5*. Версия *v.2* создана с целью решения двух основных задач *v.1*.

Масштабируемость
^^^^^^^^^^^^^^^^^

Версия *v.1* ограничивается одним экземпляром устройства записи/чтения и хранения и не может масштабироваться далеко за пределы небольших кластеров. Версия *v.2* использует более масштабируемую распределенную архитектуру записи и масштабируемое backend-хранилище.

**YARN Timeline Service v.2** отделяет сбор (запись) данных от обслуживания (чтения) данных. Он использует распределенные коллекторы, и по существу для каждого приложения **YARN** выделяется один коллектор. Читатели -- это отдельные экземпляры, предназначенные для обслуживания запросов через REST API.

В качестве основного резервного хранилища **YARN Timeline Service v.2** выбирает СУБД **Apache HBase**, поскольку она хорошо масштабируется до большого размера, сохраняя при этом хорошее время отклика для чтения и записи.


Улучшения юзабилити
^^^^^^^^^^^^^^^^^^^^

В большинстве случаев пользователи интересуются информацией на уровне "потоков" (flows) или логических групп приложений **YARN**. Гораздо более распространенным является запуск набора или серии приложений YARN для завершения логического приложения. **Timeline Service v.2** поддерживает понятие потоков в явном виде. Кроме того, он поддерживает агрегирование метрик на flow-уровне.

К тому же, такая информация, как конфигурация и метрики, обрабатывается и поддерживается как объекты первого класса.

Диаграмма иллюстрирует взаимосвязь между различными сущностями **YARN**, моделирующими потоки (:numref:`Рис.%s.<yarn_flow_hierarchy>`).

.. _yarn_flow_hierarchy:

.. figure:: ../../imgs/administration/yarn/yarn_flow_hierarchy.png
   :align: center

   Взаимосвязь между сущностями YARN


Архитектура
^^^^^^^^^^^^^

**YARN Timeline Service v.2** использует набор коллекторов (писателей) для записи данных в backend-хранилище. Коллекторы распределяются и размещаются совместно с **Application Masters** (AM), которым они предназначены. Все данные, принадлежащие приложению, отправляются timeline-коллекторам уровня приложения, за исключением timeline-коллектора уровня **Resource Manager** (RM).

Для такого приложения **Application Master** может записывать данные в совместно расположенные timeline-коллекторы (которые являются вспомогательным сервисом **NodeManager** в этом выпуске). Кроме того, **NodeManagers** других узлов с выполняющимися контейнерами для приложения, также записывают данные в timeline-коллектор на узле, на котором выполняется **Application Master**.

**Resource Manager** тоже поддерживает свой собственный timeline-коллектор. Он генерирует только события жизненного цикла, характерные для **YARN**, чтобы поддерживать разумный объем записей.

Timeline-читатели -- это отделенные от timeline-коллекторов демоны, предназначенные для обслуживания запросов через REST API (:numref:`Рис.%s.<yarn_timeline_architecture>`).

.. _yarn_timeline_architecture:

.. figure:: ../../imgs/administration/yarn/yarn_timeline_architecture.jpg
   :align: center

   Архитектура на высоком уровне


Текущее состояние и планы на будущее
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**YARN Timeline Service v.2** в настоящее время находится в альфа-версии ("alpha 2"). Это работа в процессе, и многие вещи могут и будут быстро меняться.

Полный сквозной поток операций записи и чтения является функциональным с **Apache HBase** в качестве серверной части. При включении сервиса публикуются все общие для **YARN** события, а также системные метрики **YARN**, такие как процессор и память. Кроме того, некоторые приложения, в том числе **Distributed Shell** и **MapReduce**, могут записывать в **YARN Timeline Service v.2** данные для каждой платформы.

Основным способом доступа к данным является REST. Поэтому REST API поставляется с большим количеством полезных и гибких шаблонов запросов (`REST API`_). К тому же в настоящее время отсутствует поддержка доступа к командной строке. 

Коллекторы (писатели) в настоящее время встроены в **Node Managers** в качестве вспомогательных сервисов. **Resource Manager** также имеет свой специальный внутрипроцессный коллектор. Читатель в настоящее время является единственным экземпляром. Также в текущий период невозможно выполнить запись в **Timeline Service** вне контекста приложения **YARN** (то есть вне кластерного клиента).

Начиная с *alpha2*, **Timeline Service v.2** поддерживает простую авторизацию в виде настраиваемого белого списка пользователей и групп, которые могут читать timeline-данные. Администраторам кластера по умолчанию разрешено читать эти данные.

Отключенный **YARN Timeline Service v.2** никак не влияет на любую другую существующую функциональность.

Работа, чтобы сделать сервис действительно готовым к production-ready, продолжается. Некоторые ключевые элементы включают в себя:

+ Более надежная отказоустойчивость хранилища;
+ Поддержка внекластерных клиентов;
+ Улучшенная поддержка для долгоработающих приложений;
+ Поддержка ACL;
+ Автономное (периодическое по времени) агрегирование потоков, пользователей и очередей для отчетов и анализа;
+ Коллекторы timeline как отдельные экземпляры от Node Managers;
+ Кластеризация читателей;
+ Миграция и совместимость с v.1.


Развертывание
--------------

Конфигурация
^^^^^^^^^^^^^^

**Basic**:

``yarn.timeline-service.enabled`` -- указывает клиентам, включен ли сервис Timeline. При включенном параметре используемая приложениями библиотека *TimelineClient* публикует сущности и события на сервер Timeline. Значение по умолчанию *false*;

``yarn.timeline-service.version`` -- указывает текущую версию запущенного Timeline Service. Например, если значение параметра равно *1,5*, а ``yarn.timeline-service.enabled`` установлен на *true*, то это означает, что кластер будет и должен запускать Timeline Service версии *v.1.5*. На стороне клиента, если он использует такую же версию сервера, результат будет успешным. В случае если клиент выбирает меньшую версию, несмотря на то, насколько надежна история совместимости между версиями, результаты могут отличаться. По умолчанию значение параметра *1.0f*.

Новые параметры, введенные в версии *v.2*:

``yarn.timeline-service.writer.class`` -- класс операции записи backend-хранилища. Значение по умолчанию *HBase*;

``yarn.timeline-service.reader.class`` -- класс операции чтения backend-хранилища. Значение по умолчанию *HBase*;

``yarn.system-metrics-publisher.enabled`` -- определяет, публикуются ли системные метрики YARN в сервисе Timeline (от Resource Manager и Node Manager). Значение по умолчанию *false*;

``yarn.timeline-service.schema.prefix`` -- префикс схемы для hbase-таблиц. По умолчанию ``prod.``.

**Advanced**:

``yarn.timeline-service.hostname`` -- имя хоста веб-приложения сервиса Timeline. Значение по умолчанию *0.0.0.0*;

``yarn.timeline-service.reader.webapp.address`` -- http-адрес веб-приложения Timeline Reader. По умолчанию *${yarn.timeline-service.hostname}:8188*;

``yarn.timeline-service.reader.webapp.https.address`` -- https-адрес веб-приложения Timeline Reader. По умолчанию *${yarn.timeline-service.hostname}:8190*;

``yarn.timeline-service.reader.bind-host`` -- фактический адрес, к которому привязывается timeline-читатель. Если параметр установлен, сервер читателя связывается с этим адресом и портом, указанным в ``yarn.timeline-service.reader.webapp.address``. Наиболее полезно в целях прослушивания сервисом всех интерфейсов, задав значение параметра *0.0.0.0*.

Новые параметры, введенные в версии *v.2*:

``yarn.timeline-service.hbase.configuration.file`` -- необязательный URL-адрес файла конфигурации *hbase-site.xml*, используемый для подключения кластера timeline-service hbase. Если значение параметра пусто или не указано, конфигурация HBase загружается из *classpath*. Указанное значение параметра переопределяет *classpath*. По умолчанию установлено пустое значение;

``yarn.timeline-service.writer.flush-interval-seconds`` -- определяет частоту сброса записи timeline. Значение по умолчанию *60*;

``yarn.timeline-service.app-collector.linger-period.ms`` -- период времени, в течение которого коллектор приложений активен в Node Manager после завершения работы Application Master. Значение по умолчанию *60000* (60 секунд);

``yarn.timeline-service.timeline-client.number-of-async-entities-to-merge`` -- количество попыток клиента timeline V2 для объединения многочисленных асинхронных сущностей (если они доступны), после чего вызывает REST ATS V2 API для отправки. Значение по умолчанию *10*;

``yarn.timeline-service.hbase.coprocessor.app-final-value-retention-milliseconds`` -- определяет, как долго сохраняется финальное значение метрики завершенного приложения до объединения с суммой потока. По умолчанию *259200000* (3 дня). Значение должно быть установлено в кластере HBase;

``yarn.rm.system-metrics-publisher.emit-container-events`` -- определяет, публикуется ли метрика контейнера yarn на сервере timeline (от Resource Manager). Параметр конфигурации предназначен для ATS V2. Значение по умолчанию *false*.

**Security**:

Безопасность можно включить, установив для ``yarn.timeline-service.http-authentication.type`` значение *kerberos*, после чего станут доступны следующие параметры конфигурации:

``yarn.timeline-service.http-authentication.type`` -- определяет аутентификацию, используемую для конечной точки HTTP timeline-сервера (коллектор/читатель). Поддерживаемые значения: *simple* / *kerberos* / *#AUTHENTICATION_HANDLER_CLASSNAME#*. Значение по умолчанию *simple*;

``yarn.timeline-service.http-authentication.simple.anonymous.allowed`` -- указывает, разрешены ли анонимные запросы timeline-сервером при использовании аутентификации *simple*. По умолчанию *true*;

``yarn.timeline-service.http-authentication.kerberos.principal`` -- принципал Kerberos, используемый для конечной точки HTTP timeline-сервера (коллектор/читатель);

``yarn.timeline-service.http-authentication.kerberos.keytab`` -- keytab-файл Kerberos, используемый для конечной точки HTTP timeline-сервера (коллектор/читатель);

``yarn.timeline-service.principal`` -- принципал Kerberos для timeline-читателя. Для timeline-коллектора используется принципал Node Manager, поскольку он работает в качестве вспомогательного сервиса внутри Node Manager;

``yarn.timeline-service.keytab`` -- keytab-файл Kerberos для timeline-читателя. Для timeline-коллектора используется keytab-файл ключей Node Manager, поскольку он работает в качестве вспомогательного сервиса внутри Node Manager;

``yarn.timeline-service.delegation.key.update-interval`` -- значение по умолчанию *86400000* (1 день);

``yarn.timeline-service.delegation.token.renew-interval`` -- значение по умолчанию *86400000* (1 день);

``yarn.timeline-service.delegation.token.max-lifetime`` --  значение по умолчанию *604800000* (7 дней);

``yarn.timeline-service.read.authentication.enabled`` -- включает или отключает проверку авторизации для чтения данных timeline service v2. По умолчанию установлено *false* -- отключена;

``yarn.timeline-service.read.allowed.users`` -- разделенный запятыми список пользователей и после пробела разделенный запятыми список групп. Функция позволяет введенному списку пользователей и групп читать данные и отклонять остальных пользователей и группы. По умолчанию установлено значение *none*. Если авторизация включена, то данный параметр обязателен.

**Включение поддержки CORS**

Для включения поддержки совместного использования ресурсов (Cross-origin resource sharing, CORS) в **Timeline Service v.2** необходимо установить следующие параметры конфигурации:

+ В *yarn-site.xml* параметр ``yarn.timeline-service.http-cross-origin.enabled`` установить на *true*;

+ В *core-site.xml* добавить ``org.apache.hadoop.security.HttpCrossOriginFilterInitializer`` к ``hadoop.http.filter.initializers``.

Важно обратить внимание, что параметр ``yarn.timeline-service.http-cross-origin.enabled``, установленный на *true*, переопределяет ``hadoop.http.cross-origin.enabled``.


Включение Timeline Service v.2
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Подготовка кластера **Apache HBase** к **Timeline Service v.2** заключается в выполнении нескольких шагов:

+ `Настройка кластера HBase`_;
+ `Включение сопроцессора`_;
+ `Создание схемы для Timeline Service v.2`_.


Настройка кластера HBase
~~~~~~~~~~~~~~~~~~~~~~~~~

Первый шаг заключается в настройке или выборе **Apache HBase** для использования в качестве кластера хранения. Версия **Timeline Service v.2** поддерживает **Apache HBase 1.2.6**. Ранние версии **Apache HBase** (*1.0.x*) не работают с **Timeline Service v.2**, а более поздние не протестированы.

**HBase** имеет разные режимы развертывания. При намерении создания простого профиля для кластера **Apache HBase** со слабой загрузкой данных, но с сохранением их при входе и выходе с узла, подходит режим развертывания "Standalone HBase over HDFS".

Это полезный вариант автономной настройки **HBase**, когда все демоны **HBase** работают внутри одной JVM, и вместо того, чтобы сохраняться в локальной файловой системе, сохраняются в экземпляре **HDFS**. Для настройки такого автономного варианта необходимо отредактировать файл *hbase-site.xml*, указав ``hbase.rootdir`` на каталог в экземпляре **HDFS**, а затем установить для ``hbase.cluster.distributed`` значение *false*. Например:

::

 <configuration>
   <property>
     <name>hbase.rootdir</name>
     <value>hdfs://namenode.example.org:8020/hbase</value>
   </property>
   <property>
     <name>hbase.cluster.distributed</name>
     <value>false</value>
   </property>
 </configuration>


Включение сопроцессора
~~~~~~~~~~~~~~~~~~~~~~~~

В этой версии осуществляется динамическая загрузка сопроцессора (табличный сопроцессор для flowrun-таблицы). Для этого необходимо скопировать jar-файл сервиса timeline в **HDFS**, откуда **HBase** сможет его загрузить. Это требуется для создания flowrun-таблицы в schema creator. По умолчанию расположение в **HDFS** -- */hbase/coprocessor*. Например:

::

 hadoop fs -mkdir /hbase/coprocessor
 hadoop fs -put hadoop-yarn-server-timelineservice-hbase-3.0.0-alpha1-SNAPSHOT.jar
        /hbase/coprocessor/hadoop-yarn-server-timelineservice.jar

Также можно воспользоваться параметром yarn-конфигурации -- ``yarn.timeline-service.hbase.coprocessor.jar.hdfs.location``. Например:

::

 <property>
   <name>yarn.timeline-service.hbase.coprocessor.jar.hdfs.location</name>
   <value>/custom/hdfs/path/jarName</value>
 </property>


Создание схемы для Timeline Service v.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Подготовка кластера **Apache HBase** к **Timeline Service v.2** завершается запуском инструмента schema creator для создания необходимых таблиц:

::

 bin/hadoop org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator -create

Инструмент **TimelineSchemaCreator** поддерживает несколько опций, которые могут пригодиться, особенно при тестировании. Например, можно использовать ``-skipExistingTable`` (сокращенно ``-s``), чтобы пропустить существующие таблицы и продолжить создание других таблиц, не прерывая создания схемы. Если параметр или ``-help`` (сокращенно ``-h``) не задан, отображается command usage и продолжается создание других таблиц без сбоя создания схемы. По умолчанию таблицы имеют префикс схемы ``prod.``.


Основные конфигурации Timeline Service v.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Основные конфигурации для запуска **Timeline service v.2**:

::

 <property>
   <name>yarn.timeline-service.version</name>
   <value>2.0f</value>
 </property>
 
 <property>
   <name>yarn.timeline-service.enabled</name>
   <value>true</value>
 </property>
 
 <property>
   <name>yarn.nodemanager.aux-services</name>
   <value>mapreduce_shuffle,timeline_collector</value>
 </property>
 
 <property>
  <name>yarn.nodemanager.aux-services.timeline_collector.class</name>
   <value>org.apache.hadoop.yarn.server.timelineservice.collector.PerNodeTimelineCollectorsAuxService</value>
 </property>
 
 <property>
   <description>The setting that controls whether yarn system metrics is
   published on the Timeline service or not by RM And NM.</description>
   <name>yarn.system-metrics-publisher.enabled</name>
   <value>true</value>
 </property>
 
 <property>
   <description>The setting that controls whether yarn container events are
   published to the timeline service or not by RM. This configuration setting
   is for ATS V2.</description>
   <name>yarn.rm.system-metrics-publisher.emit-container-events</name>
   <value>true</value>
 </property>

Кроме того, для имени кластера **YARN** можно установить уникальное значение (удобно при использовании нескольких кластеров для хранения данных в одном и том же хранилище **Apache HBase**):

::

 <property>
   <name>yarn.resourcemanager.cluster-id</name>
   <value>my_research_test_cluster</value>
 </property>

Также можно добавить файл *hbase-site.xml* в конфигурацию кластера **Hadoop** клиента, чтобы он мог записывать данные в используемый кластер **Apache HBase**, или установить ``yarn.timeline-service.hbase.configuration.file`` в URL файла на *hbase-site.xml*. Например:

::

 <property>
   <description> Optional URL to an hbase-site.xml configuration file to be
   used to connect to the timeline-service hbase cluster. If empty or not
   specified, then the HBase configuration will be loaded from the classpath.
   When specified the values in the specified configuration file will override
   those from the ones that are present on the classpath.
   </description>
   <name>yarn.timeline-service.hbase.configuration.file</name>
   <value>file:/etc/hbase/hbase-ats-dc1/hbase-site.xml</value>
 </property>


Запуск Timeline Service v.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Для того, чтобы выбрать новую конфигурацию, необходимо перезапустить **Resource Manager**, а также **Node Managers**. Коллекторы запускаются в рамках **Resource Manager** и **Node Managers**.

**Timeline Service reader** -- это отдельный демон **YARN**, который можно запустить, используя следующий синтаксис:

::

 $ yarn-daemon.sh start timelinereader


Включение MapReduce для записи в Timeline Service v.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Для записи данных **MapReduce** в **Timeline Service v.2** необходимо включить следующую конфигурацию в *mapred-site.xml*:

::

 <property>
   <name>mapreduce.job.emit-timeline-data</name>
   <value>true</value>
 </property>


Обновление с alpha1 до alpha2
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

При использовании **Timeline Service v.2** версии *alpha1* рекомендуется:

+ Очистить существующие данные в таблицах (truncate tables), так как ключ строки для *AppToFlow* изменился;

+ Сопроцессор теперь является динамически загружаемым сопроцессором уровня таблицы в *alpha2*. Рекомендуется удалить таблицу, заменить jar-файл сопроцессора на hdfs на *alpha2*, перезапустить серверы *Region* и воссоздать flowrun-таблицу.


Публикация определенных данных приложения
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Глава предназначена для разработчиков приложений **YARN**, которые хотят интегрироваться с **Timeline Service v.2**.

Разработчикам необходимо использовать *TimelineV2Client* API для публикации данных для каждой платформы в **Timeline Service v.2**, поскольку API сущности/объекта для *v.2* значительно изменилось по отношению к *v.1*,  в части объектной модели. Класс сущности в *v.2* -- ``org.apache.hadoop.yarn.api.records.timelineservice.TimelineEntity``.

Метод ``putEntities`` в **Timeline Service v.2** бывает двух видов: ``putEntities`` и ``putEntitiesAsync``. Первый -- это операция блокировки, используемая для записи наиболее важных данных (например, событий жизненного цикла). Последний является неблокирующей операцией. Важно обратить внимание, что ни один из методов не имеет возвращаемого значения.

Создание *TimelineV2Client* включает передачу идентификатора приложения статическому методу *TimelineV2Client.createTimelineClient*.

::

 // Create and start the Timeline client v.2
 TimelineV2Client timelineClient =
     TimelineV2Client.createTimelineClient(appId);
 timelineClient.init(conf);
 timelineClient.start();
 
 try {
   TimelineEntity myEntity = new TimelineEntity();
   myEntity.setType("MY_APPLICATION");
   myEntity.setId("MyApp1");
   // Compose other entity info
 
   // Blocking write
   timelineClient.putEntities(myEntity);
 
   TimelineEntity myEntity2 = new TimelineEntity();
   // Compose other info
 
   // Non-blocking write
   timelineClient.putEntitiesAsync(myEntity2);
 
 } catch (IOException | YarnException e) {
   // Handle the exception
 } finally {
   // Stop the Timeline client
   timelineClient.stop();
 }


Как показано в примере, следует указать идентификатор приложения **YARN**, чтобы иметь возможность записи в **Timeline Service v.2**. Также важно обратить внимание, что при текущей версии необходимо находиться в кластере, чтобы иметь возможность записи в сервис. Например, **Application Master** или код в контейнере могут выполнять запись в **Timeline Service**, в то время как отправитель задания (job submitter) **MapReduce** вне кластера -- нет.

После создания клиента *timeline v2* пользователь также должен установить информацию timeline-коллектора,  содержащую его адрес и токен (только в безопасном режиме) для приложения. Если используется *AMRMClient*, то достаточно зарегистрировать timeline-клиент, вызвав ``AMRMClient#registerTimelineV2Client``.

::

 amRMClient.registerTimelineV2Client(timelineClient);


Еще один адрес должен быть извлечен из распределенного отклика от **Application Master** и должен быть явно установлен в timeline-клиенте:

::

 timelineClient.setTimelineCollectorInfo(response.getCollectorInfo());

Создавать и публиковать собственные сущности, события и метрики можно также, как и в предыдущих версиях.

Объекты *TimelineEntity* имеют следующие поля для хранения timeline-данных:

+ *events* -- набор TimelineEvents, упорядоченный по метке времени событий в порядке убывания. Каждое событие связано с одной меткой времени и содержит один идентификатор и карту для хранения связанной информации;

+ *configs* -- сопоставление из строки (config name) в строку (config value), представляющее все настройки, связанные с сущностью. Пользователи могут публиковать весь конфиг или его часть в поле конфигурации. Поддерживается для приложений и общих сущностей;

+ *metrics* -- набор метрик, связанных с сущностью. Бывает два типа метрик: метрика одного значения (single value) и метрика временного ряда (time series). Каждый элемент метрики содержит имя метрики (id), значение и тип операции агрегирования, которая должна выполняться в этой метрике (по умолчанию *noop*). Поддерживается для потока, приложения и общих сущностей;

+ *info* -- сопоставление из строки (info key name) в объект (info value) для хранения связанной информации для сущности. Поддерживается для приложений и общих сущностей;

+ *isrelatedtoEntities and relatestoEntities* -- каждая сущность содержит поля *relatedtoEntities* и *isrelatedtoEntities* для представления взаимосвязей с другими сущностями. Оба поля представляют собой сопоставление от строки (name of the relationship) до timeline-сущности. Таким образом, взаимосвязи между сущностями могут быть представлены как DAG.

Важно обратить внимание, что при публикации timeline-метрик можно выбрать способ агрегирования каждой метрики с помощью метода ``TimelineMetric#setRealtimeAggregationOp()``. Слово "aggregate" здесь означает применение одной из операций *TimelineMetricOperation* для набора сущностей. **Timeline service v2** обеспечивает встроенную агрегацию на уровне приложения, что означает агрегирование метрик из разных timeline-сущностей в одном YARN-приложении. В настоящее время в *TimelineMetricOperation* поддерживается два вида операций:

+ *MAX* -- получение максимального значения среди всех объектов TimelineMetric;
+ *SUM* -- получение суммы всех объектов TimelineMetric.
 
По умолчанию задается *NOP* -- в реальном времени никакая операция агрегирования не выполняется.

Платформы приложений по возможности должны устанавливать "flow context", чтобы воспользоваться преимуществами поддержки потока **Timeline Service v.2**. Контекст потока состоит из:

+ *Flow name* -- строка, идентифицирующая поток высокого уровня (например, "distributed grep" или любое имя, которое может уникально представлять приложение);

+ *Flow run id* -- возрастающая последовательность чисел, отличающая разные серии одного и того же потока;

+ *Flow version*, опционально -- строковый идентификатор, обозначающий версию потока. Версия потока может использоваться для определения изменений в потоках, таких как изменения кода или сценариев.

Если контекст потока не указан, по умолчанию предоставляется:

+ *Flow name* -- имя приложения YARN (или идентификатор приложения, если имя не задано);

+ *Flow run id* -- время запуска приложения в Unix time (миллисекунды);

+ *Flow version* -- "1".

Можно предоставить контекст потока через теги YARN-приложения:

::

 ApplicationSubmissionContext appContext = app.getApplicationSubmissionContext();
 
 // set the flow context as YARN application tags
 Set<String> tags = new HashSet<>();
 tags.add(TimelineUtils.generateFlowNameTag("distributed grep"));
 tags.add(Timelineutils.generateFlowVersionTag("3df8b0d6100530080d2e0decf9e528e57c42a90a"));
 tags.add(TimelineUtils.generateFlowRunIdTag(System.currentTimeMillis()));
 
 appContext.setApplicationTags(tags);

.. important:: Resource Manager преобразует теги приложения YARN в нижний регистр перед их сохранением. Следовательно, необходимо преобразовать имена и версии потоков в нижний регистр, прежде чем использовать их в запросах REST API


Timeline Service v.2 REST API
-------------------------------

Запросы **Timeline Service v.2** в настоящее время поддерживается только через REST API; в библиотеках **YARN** не реализован API-клиент.

REST API в версии *v.2* осуществляется по пути */ws/v2/timeline/* в веб-сервисе **Timeline Service**.

Root path:

::

 GET /ws/v2/timeline/
 
Возвращает объект JSON, описывающий экземпляр сервиса и информацию о версии. 

::

 {
   "About":"Timeline Reader API",
   "timeline-service-version":"3.0.0-alpha1-SNAPSHOT",
   "timeline-service-build-version":"3.0.0-alpha1-SNAPSHOT from fb0acd08e6f0b030d82eeb7cbfa5404376313e60 by sjlee source checksum be6cba0e42417d53be16459e1685e7",
   "timeline-service-version-built-on":"2016-04-11T23:15Z",
   "hadoop-version":"3.0.0-alpha1-SNAPSHOT",
   "hadoop-build-version":"3.0.0-alpha1-SNAPSHOT from fb0acd08e6f0b030d82eeb7cbfa5404376313e60 by sjlee source checksum ee968fd0aedcc7384230ee3ca216e790",
   "hadoop-version-built-on":"2016-04-11T23:14Z"
 }


В следующих подглавах описываются поддерживаемые запросы в REST API.


Query Flows
^^^^^^^^^^^^^

С помощью Query Flows API можно получить список активных потоков, запущенных за последнее время. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если ни один из потоков не соответствует предикатам, возвращается пустой список.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/flows/
 
 or
 
 GET /ws/v2/timeline/flows/

Поддерживаемые параметры запроса:

``limit`` -- определяет количество возвращаемых потоков. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``daterange`` -- формат значения ``[startdate]-[enddate]``, то есть начальная и конечная даты, разделенные дефисом, или одна дата. Даты интерпретируются в формате *yyyyMMdd* и допускаются в формате UTC. Если указана одна дата, возвращаются все потоки, активные в этот день. Если задано начальное и конечное значение, возвращаются все активные потоки в указанный период. Если задана только начальная дата, возвращаются активные потоки на указанный день и все последующие. Если задана только конечная дата, возвращаются потоки, активные на указанный день и все предшествующие. Например:

+ ``daterange=20150711`` -- возвращает активные потоки на дату 11.07.2015;
+ ``daterange=20150711-20150714`` -- возвращает активные потоки на период 11.07.2015-14.07.2015;
+ ``daterange=20150711-`` -- возвращает активные потоки на дату 11.07.2015 и все последующие;
+ ``daterange=-20150711`` -- возвращает активные потоки на дату 11.07.2015 и все предшествующие;

``fromid`` -- возвращение набора потоков из заданного *fromid*, включая набор сущностей. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе.

Пример ответа JSON:

::

 [
   {
     "metrics": [],
     "events": [],
     "id": "test-cluster/1460419200000/sjlee@ds-date",
     "type": "YARN_FLOW_ACTIVITY",
     "createdtime": 0,
     "flowruns": [
       {
         "metrics": [],
         "events": [],
         "id": "sjlee@ds-date/1460420305659",
         "type": "YARN_FLOW_RUN",
         "createdtime": 0,
         "info": {
           "SYSTEM_INFO_FLOW_VERSION": "1",
           "SYSTEM_INFO_FLOW_RUN_ID": 1460420305659,
           "SYSTEM_INFO_FLOW_NAME": "ds-date",
           "SYSTEM_INFO_USER": "sjlee"
         },
         "isrelatedto": {},
         "relatesto": {}
       },
       {
         "metrics": [],
         "events": [],
         "id": "sjlee@ds-date/1460420587974",
         "type": "YARN_FLOW_RUN",
         "createdtime": 0,
         "info": {
           "SYSTEM_INFO_FLOW_VERSION": "1",
           "SYSTEM_INFO_FLOW_RUN_ID": 1460420587974,
           "SYSTEM_INFO_FLOW_NAME": "ds-date",
           "SYSTEM_INFO_USER": "sjlee"
         },
         "isrelatedto": {},
         "relatesto": {}
       }
     ],
     "info": {
       "SYSTEM_INFO_CLUSTER": "test-cluster",
       "UID": "test-cluster!sjlee!ds-date",
       "FROM_ID": "test-cluster!1460419200000!sjlee!ds-date",
       "SYSTEM_INFO_FLOW_NAME": "ds-date",
       "SYSTEM_INFO_DATE": 1460419200000,
       "SYSTEM_INFO_USER": "sjlee"
     },
     "isrelatedto": {},
     "relatesto": {}
   }
 ]

Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query Flow Runs
^^^^^^^^^^^^^^^^

С помощью Query Flow Runs API можно углубиться в детали и получить запуски (runs) потока (конкретные экземпляры). Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если ни один из запусков потока не соответствует предикатам, возвращается пустой список.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{user name}/flows/{flow name}/runs/
 
 or
 
 GET /ws/v2/timeline/users/{user name}/flows/{flow name}/runs/

Поддерживаемые параметры запроса:

``limit`` -- определяет количество возвращаемых потоков. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``createdtimestart`` -- возвращаются runs потока, запущенные после указанной временной метки;

``createdtimeend`` -- возвращаются runs потока, запущенные до указанной временной метки;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Если параметр не задан, в ответе возвращаются поля *id*, *type*, *createdtime* и *info*. Для выполнения запроса flow runs доступны только поля *ALL* и *METRICS*, другие поля приводят к ответу HTTP 400 (Bad Request);

``fromid`` -- возвращение набора flow run из заданного *fromid*, включая набор сущностей. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе.

Пример ответа JSON:

::

 [
   {
     "metrics": [],
     "events": [],
     "id": "sjlee@ds-date/1460420587974",
     "type": "YARN_FLOW_RUN",
     "createdtime": 1460420587974,
     "info": {
       "UID": "test-cluster!sjlee!ds-date!1460420587974",
       "FROM_ID": "test-cluster!sjlee!ds-date!1460420587974",
       "SYSTEM_INFO_FLOW_RUN_ID": 1460420587974,
       "SYSTEM_INFO_FLOW_NAME": "ds-date",
       "SYSTEM_INFO_FLOW_RUN_END_TIME": 1460420595198,
       "SYSTEM_INFO_USER": "sjlee"
     },
     "isrelatedto": {},
     "relatesto": {}
   },
   {
     "metrics": [],
     "events": [],
     "id": "sjlee@ds-date/1460420305659",
     "type": "YARN_FLOW_RUN",
     "createdtime": 1460420305659,
     "info": {
       "UID": "test-cluster!sjlee!ds-date!1460420305659",
       "FROM_ID": "test-cluster!sjlee!ds-date!1460420305659",
       "SYSTEM_INFO_FLOW_RUN_ID": 1460420305659,
       "SYSTEM_INFO_FLOW_NAME": "ds-date",
       "SYSTEM_INFO_FLOW_RUN_END_TIME": 1460420311966,
       "SYSTEM_INFO_USER": "sjlee"
     },
     "isrelatedto": {},
     "relatesto": {}
   }
 ]


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса или указано недопустимое для запроса поле; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query Flow Run
^^^^^^^^^^^^^^^^

С помощью данного API можно запросить определенный flow run, идентифицированный кластером, пользователем, именем потока или run-идентификатором. Так же при этом по умолчанию возвращаются метрики потока. Если используется конечная точка REST без имени кластера, берется кластер, указанный в ``configuration yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. 

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{user name}/flows/{flow name}/runs/{run id}
 
 or
 
 GET /ws/v2/timeline/users/{user name}/flows/{flow name}/runs/{run id}


Поддерживаемые параметры запроса:

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы.

Пример ответа JSON:

::

 {
   "metrics": [
     {
       "type": "SINGLE_VALUE",
       "id": "org.apache.hadoop.mapreduce.lib.input.FileInputFormatCounter:BYTES_READ",
       "aggregationOp": "NOP",
       "values": {
         "1465246377261": 118
       }
     },
     {
       "type": "SINGLE_VALUE",
       "id": "org.apache.hadoop.mapreduce.lib.output.FileOutputFormatCounter:BYTES_WRITTEN",
       "aggregationOp": "NOP",
       "values": {
         "1465246377261": 97
       }
     }
   ],
   "events": [],
   "id": "varun@QuasiMonteCarlo/1465246348599",
   "type": "YARN_FLOW_RUN",
   "createdtime": 1465246348599,
   "isrelatedto": {},
   "info": {
     "UID":"yarn-cluster!varun!QuasiMonteCarlo!1465246348599",
     "FROM_ID":"yarn-cluster!varun!QuasiMonteCarlo!1465246348599",
     "SYSTEM_INFO_FLOW_RUN_END_TIME":1465246378051,
     "SYSTEM_INFO_FLOW_NAME":"QuasiMonteCarlo",
     "SYSTEM_INFO_USER":"varun",
     "SYSTEM_INFO_FLOW_RUN_ID":1465246348599
   },
   "relatesto": {}
 }


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 404 (Not Found) -- запуск потока для данного flow run id не может быть найден;
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query Apps for a flow
^^^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать все приложения **YARN**, которые являются частью определенного потока. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если количество совпадающих приложений превышает установленный лимит, возвращаются последние приложения до достижения предела. Если ни одно из приложений не соответствует предикатам, возвращается пустой список.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{user name}/flows/{flow name}/apps
 
 or
 
 GET /ws/v2/timeline/users/{user name}/flows/{flow name}/apps

Поддерживаемые параметры запроса:

``limit`` -- определяет количество возвращаемых потоков. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``createdtimestart`` -- возвращаются приложения, созданные после указанной временной метки;

``createdtimeend`` -- возвращаются приложения, созданные до указанной временной метки;

``relatesto`` -- определяет, должны ли совпадающие приложения относиться к заданным сущностям. Представляется как выражение вида: ``(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…) <op> !(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…)``. Если выражение имеет тип сущности (взаимосвязь идентификатора(-ов) сущности, указанная в скобках, последующих за знаком ``!``) это означает, что приложения с этими взаимосвязями не возвращаются. Для выражений или подвыражений без знака ``!`` возвращаются все приложения, имеющие указанные отношения в своем поле *relatesto*. Оператор ``оp`` является логическим и может быть *AND* или *OR*. Тип сущности может сопровождаться любым числом идентификаторов сущностей. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: *relatesto* может быть ``(((type1:id1:id2:id3,type3:id9) AND !(type2:id7:id8)) OR (type1:id4))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``isrelatedto`` -- определяет, должны ли совпадающие приложения быть связаны с данными сущностями. Представляется так же, как выражение ``relatesto``;

``infofilters`` -- определяет, должны ли совпадающие приложения иметь точное совпадение с данным информационным ключом и должны ли быть равны его значению. Информационный ключ (info key) -- это строка, значением которой может быть любой объект. Инфофильтры представляются в виде выражения: ``(<key> <compareop> <value>) <op> (<key> <compareop> <value>)``. Оператор ``оp`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие ключа для совпадения не требуется) или *ene* (означает "не равно", но наличие ключа необходимо). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((infokey1 eq value1) AND (infokey2 ne value1)) OR (infokey1 ene value3))``. Если *value* является объектом, значение может быть задано в форме JSON-формата без пробелов. Например: ``(infokey1 eq {“<key>”:“<value>”,“<key>”:“<value>”…})``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``conffilters`` -- определяет, должны ли совпадающие приложения иметь точное совпадение с данным именем конфигурации и должны ли быть равны ее значению. Имя и значение конфигурации должны быть строками. Представляется так же, как выражение ``infofilters``;

``metricfilters`` -- определяет, должны ли совпадающие приложения иметь точные совпадения с данной метрикой и удовлетворять указанной связи со значением метрики. Идентификатор метрики должен быть строкой, а значение метрики должно быть целочисленным (integral). Параметр представляется в выражении вида: ``(<metricid> <compareop> <metricvalue>) <op> (<metricid> <compareop> <metricvalue>)``. Оператор ``op`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие метрики для совпадения не требуется), *ene* (означает "не равно", но наличие метрики необходимо), *gt* (означает "боольше, чем"), *ge* (означает "больше или равно"), *lt* (означает "меньше, чем") и *le* (означает "меньше или равно"). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((metric1 eq 50) AND (metric2 gt 40)) OR (metric1 lt 20))``. По сути, это выражение эквивалентно ``(metric1 == 50 AND metric2 > 40) OR (metric1 < 20)``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``eventfilters`` -- определяет, должны ли совпадающие приложения содержать данные события. Параметр представляется в выражении вида: ``(<eventid>,<eventid>) <op> !(<eventid>,<eventid>,<eventid>)``. Здесь ``!`` означает, что ни один из перечисленных через запятую списков событий в скобках со знаком ``!`` не должен существовать для того, чтобы произошло совпадение. Если ``!`` не указано, события в скобках должны существовать. Оператор ``op`` может быть *AND* или *OR*. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((event1,event2) AND !(event4)) OR (event3,event7,event5))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-приложения, тип (эквивалент *YARN_APPLICATION*), время создания приложения и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени;

``fromid`` -- возвращение набора сущностей приложения из заданного *fromid*. Набор сущностей включает указанный *fromid*. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе потока сущности.

Пример ответа JSON:

::

 [
   {
     "metrics": [ ],
     "events": [ ],
     "type": "YARN_APPLICATION",
     "id": "application_1465246237936_0001",
     "createdtime": 1465246348599,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!application_1465246237936_0001"
       "FROM_ID": "yarn-cluster!varun!QuasiMonteCarlo!1465246348599!application_1465246237936_0001",
     },
     "relatesto": { }
   },
   {
     "metrics": [ ],
     "events": [ ],
     "type": "YARN_APPLICATION",
     "id": "application_1464983628730_0005",
     "createdtime": 1465033881959,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!application_1464983628730_0005"
       "FROM_ID": "yarn-cluster!varun!QuasiMonteCarlo!1465246348599!application_1464983628730_0005",
     },
     "relatesto": { }
   }
 ]

Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query Apps for a flow run
^^^^^^^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать все приложения **YARN**, которые являются частью определенного flow run. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если количество совпадающих приложений превышает установленный лимит, возвращаются последние приложения до достижения предела. Если ни одно из приложений не соответствует предикатам, возвращается пустой список.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{user name}/flows/{flow name}/runs/{run id}/apps
 
 or
 
 GET /ws/v2/timeline/users/{user name}/flows/{flow name}/runs/{run id}/apps/


Поддерживаемые параметры запроса:

``limit`` -- определяет количество возвращаемых приложений. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``createdtimestart`` -- возвращаются приложения, созданные после указанной метки времени;

``createdtimeend`` -- возвращаются приложения, созданные до указанной метки времени;

``relatesto`` -- определяет, должны ли совпадающие приложения относиться к заданным сущностям. Представляется как выражение вида: ``(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…) <op> !(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…)``. Если выражение имеет тип сущности (взаимосвязь идентификатора(-ов) сущности, указанная в скобках, последующих за знаком ``!``) это означает, что приложения с этими взаимосвязями не возвращаются. Для выражений или подвыражений без знака ``!`` возвращаются все приложения, имеющие указанные отношения в своем поле *relatesto*. Оператор ``оp`` является логическим и может быть *AND* или *OR*. Тип сущности может сопровождаться любым числом идентификаторов сущностей. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: *relatesto* может быть ``(((type1:id1:id2:id3,type3:id9) AND !(type2:id7:id8)) OR (type1:id4))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``isrelatedto`` -- определяет, должны ли совпадающие приложения быть связаны с данными сущностями и их типом. Представляется так же, как выражение ``relatesto``;

``infofilters`` -- определяет, должны ли совпадающие приложения иметь точное совпадение с данным информационным ключом и должны ли быть равны его значению. Информационный ключ (info key) -- это строка, значением которой может быть любой объект. Инфофильтры представляются в виде выражения: ``(<key> <compareop> <value>) <op> (<key> <compareop> <value>)``. Оператор ``оp`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие ключа для совпадения не требуется) или *ene* (означает "не равно", но наличие ключа необходимо). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((infokey1 eq value1) AND (infokey2 ne value1)) OR (infokey1 ene value3))``. Если *value* является объектом, значение может быть задано в форме JSON-формата без пробелов. Например: ``(infokey1 eq {“<key>”:“<value>”,“<key>”:“<value>”…})``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``conffilters`` -- определяет, должны ли совпадающие приложения иметь точное совпадение с данным именем конфигурации и должны ли быть равны ее значению. Имя и значение конфигурации должны быть строками. Представляется так же, как выражение ``infofilters``;

``metricfilters`` -- определяет, должны ли совпадающие приложения иметь точные совпадения с данной метрикой и удовлетворять указанной связи со значением метрики. Идентификатор метрики должен быть строкой, а значение метрики должно быть целочисленным (integral). Параметр представляется в выражении вида: ``(<metricid> <compareop> <metricvalue>) <op> (<metricid> <compareop> <metricvalue>)``. Оператор ``op`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие метрики для совпадения не требуется), *ene* (означает "не равно", но наличие метрики необходимо), *gt* (означает "боольше, чем"), *ge* (означает "больше или равно"), *lt* (означает "меньше, чем") и *le* (означает "меньше или равно"). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((metric1 eq 50) AND (metric2 gt 40)) OR (metric1 lt 20))``. По сути, это выражение эквивалентно ``(metric1 == 50 AND metric2 > 40) OR (metric1 < 20)``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``eventfilters`` -- определяет, должны ли совпадающие приложения содержать данные события. Параметр представляется в выражении вида: ``(<eventid>,<eventid>) <op> !(<eventid>,<eventid>,<eventid>)``. Здесь ``!`` означает, что ни один из перечисленных через запятую списков событий в скобках со знаком ``!`` не должен существовать для того, чтобы произошло совпадение. Если ``!`` не указано, события в скобках должны существовать. Оператор ``op`` может быть *AND* или *OR*. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((event1,event2) AND !(event4)) OR (event3,event7,event5))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-приложения, тип (эквивалент *YARN_APPLICATION*), время создания приложения и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени;

``fromid`` -- возвращение набора сущностей приложения из заданного *fromid*. Набор сущностей включает указанный *fromid*. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе потока сущности.

Пример ответа JSON:

::

 [
   {
     "metrics": [],
     "events": [],
     "id": "application_1460419579913_0002",
     "type": "YARN_APPLICATION",
     "createdtime": 1460419580171,
     "info": {
       "UID": "test-cluster!sjlee!ds-date!1460419580171!application_1460419579913_0002"
       "FROM_ID": "test-cluster!sjlee!ds-date!1460419580171!application_1460419579913_0002",
     },
     "configs": {},
     "isrelatedto": {},
     "relatesto": {}
   }
 ]
 
Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query app
^^^^^^^^^^^

С помощью данного API можно запрашивать одно приложение **YARN**, идентифицированное кластером ID-приложения. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Информация о контексте потока, то есть пользователь, имя потока и run id, не являются обязательными, но если они указаны в параметре запроса, это может исключить необходимость в дополнительной операции для получения информации о контексте потока на основе id кластера и приложения.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/apps/{app id}
 
 or
 
 GET /ws/v2/timeline/apps/{app id}


Поддерживаемые параметры запроса:

``userid`` -- возвращает приложения, принадлежащие данному пользователю. Параметр запроса должен быть указан вместе с параметрами ``flowname`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowname`` -- возвращает приложения, принадлежащие данному имени потока. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowrunid`` -- возвращает приложения, принадлежащие данному идентификатору flow run. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowname``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-приложения, тип (эквивалент *YARN_APPLICATION*), время создания приложения и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени.

Пример ответа JSON:

::

 {
   "metrics": [],
   "events": [],
   "id": "application_1460419579913_0002",
   "type": "YARN_APPLICATION",
   "createdtime": 1460419580171,
   "info": {
     "UID": "test-cluster!sjlee!ds-date!1460419580171!application_1460419579913_0002"
   },
   "configs": {},
   "isrelatedto": {},
   "relatesto": {}
 }


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 404 (Not Found) -- информация о контексте потока не может быть получена или приложение для данного id приложения не может быть найдено;
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query generic entities with in the scope of Application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать общие сущности, идентифицируемые по ID-кластера и приложения и типу сущности для каждой платформы. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Информация о контексте потока, то есть пользователь, имя потока и run id, не являются обязательными, но если они указаны в параметре запроса, это может исключить необходимость в дополнительной операции для получения информации о контексте потока на основе id кластера и приложения. Если количество совпадающих сущностей превышает установленный лимит, возвращаются последние сущности до достижения предела. Эта конечная точка может использоваться для запроса контейнеров, приложения или любой другой общей сущности, которую клиенты помещают в серверную часть. Например, можно запросить контейнеры, указав тип сущности как *YARN_CONTAINER* и *YARN_APPLICATION_ATTEMPT*. Если ни одна из сущностей не соответствует предикатам, возвращается пустой список.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/apps/{app id}/entities/{entity type}
 
 or
 
 GET /ws/v2/timeline/apps/{app id}/entities/{entity type}


Поддерживаемые параметры запроса:

``userid`` -- возвращает сущности, принадлежащие данному пользователю. Параметр запроса должен быть указан вместе с параметрами ``flowname`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowname`` -- возвращает сущности, принадлежащие данному имени потока. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowrunid`` -- возвращает сущности, принадлежащие данному идентификатору flow run. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowname``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``limit`` -- определяет количество возвращаемых сущностей. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``createdtimestart`` -- возвращаются сущности, созданные после указанной метки времени;

``createdtimeend`` -- возвращаются сущности, созданные до указанной метки времени;

``relatesto`` -- определяет, должны ли совпадающие сущности относиться к заданным сущностям. Представляется как выражение вида: ``(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…) <op> !(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…)``. Если выражение имеет тип сущности (взаимосвязь идентификатора(-ов) сущности, указанная в скобках, последующих за знаком ``!``) это означает, что сущности с этими взаимосвязями не возвращаются. Для выражений или подвыражений без знака ``!`` возвращаются все сущности, имеющие указанные отношения в своем поле *relatesto*. Оператор ``оp`` является логическим и может быть *AND* или *OR*. Тип сущности может сопровождаться любым числом идентификаторов сущностей. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: *relatesto* может быть ``(((type1:id1:id2:id3,type3:id9) AND !(type2:id7:id8)) OR (type1:id4))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``isrelatedto`` -- определяет, должны ли совпадающие сущности быть связаны с данными сущностями и их типом. Представляется так же, как выражение ``relatesto``;

``infofilters`` -- определяет, должны ли совпадающие сущности иметь точное совпадение с данным информационным ключом и должны ли быть равны его значению. Информационный ключ (info key) -- это строка, значением которой может быть любой объект. Инфофильтры представляются в виде выражения: ``(<key> <compareop> <value>) <op> (<key> <compareop> <value>)``. Оператор ``оp`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие ключа для совпадения не требуется) или *ene* (означает "не равно", но наличие ключа необходимо). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((infokey1 eq value1) AND (infokey2 ne value1)) OR (infokey1 ene value3))``. Если *value* является объектом, значение может быть задано в форме JSON-формата без пробелов. Например: ``(infokey1 eq {“<key>”:“<value>”,“<key>”:“<value>”…})``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``conffilters`` -- определяет, должны ли совпадающие сущности иметь точное совпадение с данным именем конфигурации и должны ли быть равны ее значению. Имя и значение конфигурации должны быть строками. Представляется так же, как выражение ``infofilters``;

``metricfilters`` -- определяет, должны ли совпадающие сущности иметь точные совпадения с данной метрикой и удовлетворять указанной связи со значением метрики. Идентификатор метрики должен быть строкой, а значение метрики должно быть целочисленным (integral). Параметр представляется в выражении вида: ``(<metricid> <compareop> <metricvalue>) <op> (<metricid> <compareop> <metricvalue>)``. Оператор ``op`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие метрики для совпадения не требуется), *ene* (означает "не равно", но наличие метрики необходимо), *gt* (означает "боольше, чем"), *ge* (означает "больше или равно"), *lt* (означает "меньше, чем") и *le* (означает "меньше или равно"). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((metric1 eq 50) AND (metric2 gt 40)) OR (metric1 lt 20))``. По сути, это выражение эквивалентно ``(metric1 == 50 AND metric2 > 40) OR (metric1 < 20)``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``eventfilters`` -- определяет, должны ли совпадающие сущности содержать данные события. Параметр представляется в выражении вида: ``(<eventid>,<eventid>) <op> !(<eventid>,<eventid>,<eventid>)``. Здесь ``!`` означает, что ни один из перечисленных через запятую списков событий в скобках со знаком ``!`` не должен существовать для того, чтобы произошло совпадение. Если ``!`` не указано, события в скобках должны существовать. Оператор ``op`` может быть *AND* или *OR*. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((event1,event2) AND !(event4)) OR (event3,event7,event5))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-сущности и ее тип, время создания и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени;

``fromid`` -- возвращение набора общих сущностей из заданного *fromid*. Набор сущностей включает указанный *fromid*. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе потока сущности.

Пример ответа JSON:

::

 [
   {
     "metrics": [ ],
     "events": [ ],
     "type": "YARN_APPLICATION_ATTEMPT",
     "id": "appattempt_1465246237936_0001_000001",
     "createdtime": 1465246358873,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!appattempt_1465246237936_0001_000001"
       "FROM_ID": "yarn-cluster!sjlee!ds-date!1460419580171!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!0!appattempt_1465246237936_0001_000001"
     },
     "relatesto": { }
   },
   {
     "metrics": [ ],
     "events": [ ],
     "type": "YARN_APPLICATION_ATTEMPT",
     "id": "appattempt_1465246237936_0001_000002",
     "createdtime": 1465246359045,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!appattempt_1465246237936_0001_000002"
       "FROM_ID": "yarn-cluster!sjlee!ds-date!1460419580171!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!0!appattempt_1465246237936_0001_000002"
     },
     "relatesto": { }
   }
 ]


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 404 (Not Found) -- информация о контексте потока не может быть получена;
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query generic entities
^^^^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать общие сущности для каждого пользователя, идентифицируемые по ID-кластера, *doAsUser* и типу сущности. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если количество совпадающих сущностей превышает установленный лимит, возвращаются последние сущности до достижения предела. Эта конечная точка может использоваться для запроса общей сущности, которую клиенты помещают в серверную часть. Например, можно запросить пользовательские сущности, указав тип сущности как *TEZ_DAG_ID*. Если ни одна из сущностей не соответствует предикатам, возвращается пустой список. Примечание: на данный момент можно запрашивать только те сущности, которые опубликованы с помощью *doAsUser*, отличного от владельца приложения.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{userid}/entities/{entitytype}
 
 or
 
 GET /ws/v2/timeline/users/{userid}/entities/{entitytype}

Поддерживаемые параметры запроса:

``limit`` -- определяет количество возвращаемых сущностей. Максимально возможное значение лимита -- максимальное значение *Long*. Если значение не указано или меньше *0*, то лимит считается равным *100*;

``createdtimestart`` -- возвращаются сущности, созданные после указанной метки времени;

``createdtimeend`` -- возвращаются сущности, созданные до указанной метки времени;

``relatesto`` -- определяет, должны ли совпадающие сущности относиться к заданным сущностям. Представляется как выражение вида: ``(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…) <op> !(<entitytype>:<entityid>:<entityid>…,<entitytype>:<entityid>:<entityid>…)``. Если выражение имеет тип сущности (взаимосвязь идентификатора(-ов) сущности, указанная в скобках, последующих за знаком ``!``) это означает, что сущности с этими взаимосвязями не возвращаются. Для выражений или подвыражений без знака ``!`` возвращаются все сущности, имеющие указанные отношения в своем поле *relatesto*. Оператор ``оp`` является логическим и может быть *AND* или *OR*. Тип сущности может сопровождаться любым числом идентификаторов сущностей. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: *relatesto* может быть ``(((type1:id1:id2:id3,type3:id9) AND !(type2:id7:id8)) OR (type1:id4))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``isrelatedto`` -- определяет, должны ли совпадающие сущности быть связаны с данными сущностями и их типом. Представляется так же, как выражение ``relatesto``;

``infofilters`` -- определяет, должны ли совпадающие сущности иметь точное совпадение с данным информационным ключом и должны ли быть равны его значению. Информационный ключ (info key) -- это строка, значением которой может быть любой объект. Инфофильтры представляются в виде выражения: ``(<key> <compareop> <value>) <op> (<key> <compareop> <value>)``. Оператор ``оp`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие ключа для совпадения не требуется) или *ene* (означает "не равно", но наличие ключа необходимо). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((infokey1 eq value1) AND (infokey2 ne value1)) OR (infokey1 ene value3))``. Если *value* является объектом, значение может быть задано в форме JSON-формата без пробелов. Например: ``(infokey1 eq {“<key>”:“<value>”,“<key>”:“<value>”…})``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``conffilters`` -- определяет, должны ли совпадающие сущности иметь точное совпадение с данным именем конфигурации и должны ли быть равны ее значению. Имя и значение конфигурации должны быть строками. Представляется так же, как выражение ``infofilters``;

``metricfilters `` -- определяет, должны ли совпадающие сущности иметь точные совпадения с данной метрикой и удовлетворять указанной связи со значением метрики. Идентификатор метрики должен быть строкой, а значение метрики должно быть целочисленным (integral). Параметр представляется в выражении вида: ``(<metricid> <compareop> <metricvalue>) <op> (<metricid> <compareop> <metricvalue>)``. Оператор ``op`` может быть *AND* или *OR*; ``compareop`` -- *eq* (означает "равно"), *ne* (означает "не равно" и наличие метрики для совпадения не требуется), *ene* (означает "не равно", но наличие метрики необходимо), *gt* (означает "боольше, чем"), *ge* (означает "больше или равно"), *lt* (означает "меньше, чем") и *le* (означает "меньше или равно"). Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((metric1 eq 50) AND (metric2 gt 40)) OR (metric1 lt 20))``. По сути, это выражение эквивалентно ``(metric1 == 50 AND metric2 > 40) OR (metric1 < 20)``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``eventfilters`` -- определяет, должны ли совпадающие сущности содержать данные события. Параметр представляется в выражении вида: ``(<eventid>,<eventid>) <op> !(<eventid>,<eventid>,<eventid>)``. Здесь ``!`` означает, что ни один из перечисленных через запятую списков событий в скобках со знаком ``!`` не должен существовать для того, чтобы произошло совпадение. Если ``!`` не указано, события в скобках должны существовать. Оператор ``op`` может быть *AND* или *OR*. Можно комбинировать любое количество *AND* и *OR* для создания сложных выражений. Для объединения выражений можно использовать скобки. Например: ``(((event1,event2) AND !(event4)) OR (event3,event7,event5))``. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-сущности и ее тип, время создания и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени;

``fromid`` -- возвращение набора общих сущностей из заданного *fromid*. Набор сущностей включает указанный *fromid*. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе потока сущности.

Пример ответа JSON:

::

 [
   {
     "metrics": [ ],
     "events": [ ],
     "type": "TEZ_DAG_ID",
     "id": "dag_1465246237936_0001_000001",
     "createdtime": 1465246358873,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!sjlee!TEZ_DAG_ID!0!dag_1465246237936_0001_000001"
       "FROM_ID": "sjlee!yarn-cluster!TEZ_DAG_ID!0!dag_1465246237936_0001_000001"
     },
     "relatesto": { }
   },
   {
     "metrics": [ ],
     "events": [ ],
     "type": "TEZ_DAG_ID",
     "id": "dag_1465246237936_0001_000002",
     "createdtime": 1465246359045,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!sjlee!TEZ_DAG_ID!0!dag_1465246237936_0001_000002!userX"
       "FROM_ID": "sjlee!yarn-cluster!TEZ_DAG_ID!0!dag_1465246237936_0001_000002!userX"
     },
     "relatesto": { }
   }
 ]


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query generic entity with in the scope of Application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать определенную общую сущность, идентифицированную по ID кластера и приложения, типу сущности для каждой платформы и ID-сущности. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Информация о контексте потока, то есть пользователь, имя потока и run id, не являются обязательными, но если они указаны в параметре запроса, это может исключить необходимость в дополнительной операции для получения информации о контексте потока на основе id кластера и приложения. Эта конечная точка может использоваться для запроса отдельного контейнера, приложения или любой другой общей сущности, что клиенты помещают в серверную часть. Например, можно запросить определенный YARN-контейнер, указав тип сущности как *YARN_CONTAINER* и задав идентификатор сущности как ID контейнера. Аналогично, приложение может быть запрошено путем указания типа сущности как *YARN_APPLICATION_ATTEMPT*, а application attempt ID в виде идентификатора сущности.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/apps/{app id}/entities/{entity type}/{entity id}
 
 or
 
 GET /ws/v2/timeline/apps/{app id}/entities/{entity type}/{entity id}


Поддерживаемые параметры запроса:

``userid`` -- возвращает сущности, принадлежащие данному пользователю. Параметр запроса должен быть указан вместе с параметрами ``flowname`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowname`` -- возвращает сущности, принадлежащие данному имени потока. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowrunid``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``flowrunid`` -- возвращает сущности, принадлежащие данному идентификатору flow run. Параметр запроса должен быть указан вместе с параметрами ``userid`` и ``flowname``, в противном случае он игнорируется. Если все три параметра не заданы, то извлекать информацию о контексте потока приходится при выполнении запроса на основе id кластера и приложения;

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-сущности и ее тип, время создания и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени.

``entityidprefix`` -- задает id-префикс для извлекаемой сущности. При указанном параметре извлечение сущности ускоряется.

Пример ответа JSON:

::

 {
   "metrics": [ ],
   "events": [ ],
   "type": "YARN_APPLICATION_ATTEMPT",
   "id": "appattempt_1465246237936_0001_000001",
   "createdtime": 1465246358873,
   "isrelatedto": { },
   "configs": { },
   "info": {
     "UID": "yarn-cluster!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!0!appattempt_1465246237936_0001_000001"
     "FROM_ID": "yarn-cluster!sjlee!ds-date!1460419580171!application_1465246237936_0001!YARN_APPLICATION_ATTEMPT!0!appattempt_1465246237936_0001_000001"
   },
   "relatesto": { }
 }


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 404 (Not Found) -- информация о контексте потока не может быть получена или сущность для данного id-сущности не может быть найдена;
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.


Query generic entity
^^^^^^^^^^^^^^^^^^^^^

С помощью данного API можно запрашивать общую сущность для каждого пользователя, идентифицируемую по ID-кластера, *doAsUser* и типу сущности и ее ID. Если используется конечная точка REST без имени кластера, берется кластер, указанный в конфигурации ``yarn.resourcemanager.cluster-id`` в *yarn-site.xml*. Если количество совпадающих сущностей превышает установленный лимит, возвращаются последние сущности до достижения предела. Эта конечная точка может использоваться для запроса общей сущности, которую клиенты помещают в серверную часть. Например, можно запросить пользовательские сущности, указав тип сущности как *TEZ_DAG_ID*. Если ни одна из сущностей не соответствует предикатам, возвращается пустой список. Примечание: на данный момент можно запрашивать только те сущности, которые опубликованы с помощью *doAsUser*, отличного от владельца приложения.

HTTP:

::

 GET /ws/v2/timeline/clusters/{cluster name}/users/{userid}/entities/{entitytype}/{entityid}
 
 or
 
 GET /ws/v2/timeline/users/{userid}/entities/{entitytype}/{entityid}


Поддерживаемые параметры запроса:

``metricstoretrieve`` -- определяет, какие метрики извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- разделенный запятыми список id-префиксов метрики. В таком случае извлекаются все соответствующие указанным префиксам метрики. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<metricprefix>,<metricprefix>,<metricprefix>,<metricprefix>…)`` -- что тоже указывает на разделенный запятыми список id-префиксов метрики, но в таком случае извлекаются только не соответствующие ни одному из префиксов метрики. Если параметр задан, метрики извлекаются независимо от того, указаны ли они в полях *METRICS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``confstoretrieve`` -- определяет, какие конфигурации извлекать, и отправляет обратно в ответе. Может быть выражением вида: ``(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)`` --  разделенный запятыми список префиксов имени конфигурации. В таком случае извлекаются все соответствующие указанным префиксам конфигурации. Для простого выражения скобки необязательны. Альтернативно, выражения могут иметь такую форму: ``!(<config_name_prefix>,<config_name_prefix>,<config_name_prefix>,<config_name_prefix>…)``  -- что тоже указывает на разделенный запятыми список префиксов имени конфигурации, но в таком случае извлекаются только не соответствующие ни одному из префиксов конфигурации. Если параметр задан, конфигурации извлекаются независимо от того, указаны ли они в полях *CONFIGS* параметра запроса или нет. Важно обратить внимание, что небезопасные символы URL, такие как пробелы, должны быть соответствующим образом закодированы;

``fields`` -- определяет поля для извлечения. Возможные значения для полей: *EVENTS*, *INFO*, *CONFIGS*, *METRICS*, *RELATES_TO*, *IS_RELATED_TO* и *ALL*. Если указано *ALL*, извлекаются все поля. Может быть указано несколько полей в виде списка через запятую. Если ни одно поле не указано, в ответе возвращается id-сущности и ее тип, время создания и UID из поля *info*;

``metricslimit`` -- определяет количество возвращаемых метрик. Учитывается только в случае, если поля содержат *METRICS*/*ALL* или указан ``metricstoretrieve``. В иных случаях игнорируется. Максимально возможным значением может быть максимальное значение Integer. Если параметр не указан или имеет значение меньше *1*, и при этом метрики должны быть получены, то ``metricslimit`` рассматривается как *1*, и возвращает последнее значение метрики (метрик);

``metricstimestart`` -- возвращаются метрики для сущности после указанной метки времени;

``metricstimeend`` -- возвращаются метрики для сущности до указанной метки времени;

``fromid`` -- возвращение набора общих сущностей из заданного *fromid*. Набор сущностей включает указанный *fromid*. Значение *fromid* должно быть взято из информационного ключа *FROM_ID* в отправленном ранее ответе потока сущности.

Пример ответа JSON:

::

 [
   {
     "metrics": [ ],
     "events": [ ],
     "type": "TEZ_DAG_ID",
     "id": "dag_1465246237936_0001_000001",
     "createdtime": 1465246358873,
     "isrelatedto": { },
     "configs": { },
     "info": {
       "UID": "yarn-cluster!sjlee!TEZ_DAG_ID!0!dag_1465246237936_0001_000001!userX"
       "FROM_ID": "sjlee!yarn-cluster!TEZ_DAG_ID!0!dag_1465246237936_0001_000001!userX"
     },
     "relatesto": { }
   }
 ]


Код ответа:

+ HTTP 200 (ОК) -- успех;
+ HTTP 400 (Bad Request) -- какая-либо проблема при синтаксическом анализе запроса; 
+ HTTP 500 (Internal Server Error) -- неустранимые ошибки при возвращении данных.



Query generic entity types
^^^^^^^^^^^^^^^^^^^^^^^^^^^^






