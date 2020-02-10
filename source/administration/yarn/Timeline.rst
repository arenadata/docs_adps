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

Разработчикам необходимо использовать *TimelineV2Client* API для публикации данных для каждой платформы в **Timeline Service v.2**. Поскольку API сущности/объекта для *v.2* значительно изменилось по отношению к *v.1*,  в части объектной модели. Класс сущности в *v.2* -- ``org.apache.hadoop.yarn.api.records.timelineservice.TimelineEntity``.

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

+ *isrelatedtoEntities and relatestoEntities* -- каждая сущность содержит поля *relatedtoEntities* и *isrelatedtoEntities* для представления отношений с другими сущностями. Оба поля представляют собой сопоставление от строки (name of the relationship) до timeline-сущности. Таким образом, отношения между сущностями могут быть представлены как DAG.

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


Root path
^^^^^^^^^^^


Query Flows
^^^^^^^^^^^^^


Query Flow Runs
^^^^^^^^^^^^^^^^


Query Flow Run
^^^^^^^^^^^^^^^^


Query Apps for a flow
^^^^^^^^^^^^^^^^^^^^^^^


Query Apps for a flow run
^^^^^^^^^^^^^^^^^^^^^^^^^^^


Query app
^^^^^^^^^^^


Query generic entities with in the scope of Application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Query generic entities
^^^^^^^^^^^^^^^^^^^^^^^^


Query generic entity with in the scope of Application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Query generic entity
^^^^^^^^^^^^^^^^^^^^^


Query generic entity types
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

