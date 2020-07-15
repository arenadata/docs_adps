Установка интерпретатора
=========================

**Apache Zeppelin** обеспечивает механизм установки интерпретатора, благодаря загруженному с **Zeppelin** бинарному пакету *netinst*, также можно установить другие сторонние интерпретаторы.

+ `Установка интерпретаторов, разрабатываемых сообществом`_

+ `Сторонние интерпретаторы`_

+ `Доступные интерпретаторы, разрабатываемые сообществом`_

.. important:: После установки интерпретаторов необходимо перезапустить Apache Zeppelin, выполнить настройку интерпретатора и привязать его к блокноту (`Интерпретаторы в Apache Zeppelin <http://docs.arenadata.io/adh/v1.4/Zeppelin/Interpreters.html>`_)


Установка интерпретаторов, разрабатываемых сообществом
--------------------------------------------------------

**Apache Zeppelin** позволяет управлять несколькими интерпретаторами одновременно, объединяя их в группы, перечень которых представлен в разделе `Доступные интерпретаторы, разрабатываемые сообществом`_. Если бинарный пакет *netinst* уже загружен, следует в зависимости от необходимых интерпретаторов выполнить соответствующие команды.


+ **Установка предоставляемых сообществом интерпретаторов**

Для установки всех интерпретаторов, которые предоставляются сообществом, необходимо выполнить следующую команду:

  :command:`./bin/install-interpreter.sh --all`
  

+ **Установка выборочных интерпретаторов**

Для установки отдельно выбранных интерпретаторов необходимо воспользоваться следующей командой:

  :command:`./bin/install-interpreter.sh --name md,shell,jdbc,python`

Для получения полного списка интерпретаторов, разрабатываемых сообществом, следует выполнить команду:

  :command:`./bin/install-interpreter.sh --list`


+ **Установка интерпретатора с версией языка Scala 2.10**

**Zeppelin** поддерживает **Scala 2.10** и **2.11** для нескольких интерпретаторов, параметры которых приведены в таблице.

.. csv-table:: Параметры интерпретаторов для Scala
   :header: "Параметр --name", "Параметр --artifact для Scala 2.10", "Параметр --artifact для Scala 2.11"
   :widths: 20, 40, 40

   "cassandra", "org.apache.zeppelin:zeppelin-cassandra_2.10:0.7.3", "org.apache.zeppelin:zeppelin-cassandra_2.11:0.7.3"
   "flink", "org.apache.zeppelin:zeppelin-flink_2.10:0.7.3", "org.apache.zeppelin:zeppelin-flink_2.11:0.7.3"
   "ignite", "org.apache.zeppelin:zeppelin-ignite_2.10:0.7.3", "org.apache.zeppelin:zeppelin-ignite_2.11:0.7.3"
   "scio", "org.apache.zeppelin:zeppelin-scio_2.10:0.7.3", "org.apache.zeppelin:zeppelin-scio_2.11:0.7.3"
   "spark", "org.apache.zeppelin:zeppelin-spark_2.10:0.7.3", "org.apache.zeppelin:zeppelin-spark_2.11:0.7.3"


При установке интерпретатора только с параметром *--name*, программа установки загружает по умолчанию интерпретатор с поддержкой версии языка **Scala 2.11**. Для указания иной версии **Scala** следует добавить параметр *--artifact*. Далее приведен пример установки интерпретатора *flink* с версией языка **Scala 2.10**:

  :command:`./bin/install-interpreter.sh --name flink --artifact org.apache.zeppelin:zeppelin-flink_2.10:0.7.3`


+ **Установка интерпретатора Spark, поддерживающего версию языка Scala 2.10**

Дистрибутив **Spark** до версии *1.6.2* поддерживает **Scala 2.10**. Если *SPARK_HOME* указывает на версию **Spark** ниже *2.0.0*, необходимо скачать интерпретатор **Spark** с версией языка **Scala 2.10**. Для этого следует выполнить команду:

   ::
    
    rm -rf ./interpreter/spark
    ./bin/install-interpreter.sh --name spark --artifact org.apache.zeppelin:zeppelin-spark_2.10:0.7.3


Сторонние интерпретаторы
-------------------------

Сторонние интерпретаторы из репозитория **maven** можно установить при помощи следующей команды: 

  :command:`./bin/install-interpreter.sh --name interpreter1 --artifact groupId1:artifact1:version1`

Данная команда загружает артефакт **maven** *groupId1:artifact1:version1* и все его зависимости в каталог *interpreter/interpreter1*.

Установка нескольких сторонних интерпретаторов осуществляется командой, где аргументы *--name* и *--artifact* указываются списком через запятую:

   ::
    
    ./bin/install-interpreter.sh --name interpreter1,interpreter2 --artifact groupId1:artifact1:version1,groupId2:artifact2:version2


Доступные интерпретаторы, разрабатываемые сообществом
-------------------------------------------------------

Список интерпретаторов, предоставляемых сообществом, приведен в таблице. Также данную информацию можно найти в файле *conf/interpreter-list*. 

.. csv-table:: Предоставляемые сообществом интерпретаторы
   :header: "Параметр --name", "Maven Artifact", "Описание"
   :widths: 20, 40, 40

   "alluxio", "org.apache.zeppelin:zeppelin-alluxio:0.7.3", "Интерпретатор Alluxio"
   "angular", "org.apache.zeppelin:zeppelin-angular:0.7.3", "Просмотр HTML и AngularJS"
   "beam", "org.apache.zeppelin:zeppelin-beam:0.7.3", "Интерпретатор Beam"
   "bigquery", "org.apache.zeppelin:zeppelin-bigquery:0.7.3", "Интерпретатор BigQuery"
   "cassandra", "org.apache.zeppelin:zeppelin-cassandra_2.11:0.7.3", "Интерпретатор Cassandra, построенный с помощью Scala 2.11"
   "elasticsearch", "org.apache.zeppelin:zeppelin-elasticsearch:0.7.3", "Интерпретатор Elasticsearch"
   "file", "org.apache.zeppelin:zeppelin-file:0.7.3", "Интерпретатор файлов HDFS"
   "flink", "org.apache.zeppelin:zeppelin-flink_2.11:0.7.3", "Интерпретатор Flink, построенный с помощью Scala 2.11"
   "hbase", "org.apache.zeppelin:zeppelin-hbase:0.7.3", "Интерпретатор Hbase"
   "ignite", "org.apache.zeppelin:zeppelin-ignite_2.11:0.7.3", "Интерпретатор Ignite, построенный с помощью Scala 2.11"
   "jdbc", "org.apache.zeppelin:zeppelin-jdbc:0.7.3", "Интерпретатор Jdbc"
   "kylin", "org.apache.zeppelin:zeppelin-kylin:0.7.3", "Интерпретатор Kylin"
   "lens", "org.apache.zeppelin:zeppelin-lens:0.7.3", "Интерпретатор Lens"
   "livy", "org.apache.zeppelin:zeppelin-livy:0.7.3", "Интерпретатор Livy"
   "md", "org.apache.zeppelin:zeppelin-markdown:0.7.3", "Поддержка Markdown"
   "pig", "org.apache.zeppelin:zeppelin-pig:0.7.3", "Интерпретатор Pig"
   "postgresql", "org.apache.zeppelin:zeppelin-postgresql:0.7.3", "Интерпретатор Postgresql"
   "python", "org.apache.zeppelin:zeppelin-python:0.7.3", "Интерпретатор Python"
   "scio", "org.apache.zeppelin:zeppelin-scio_2.11:0.7.3", "Интерпретатор Scio, построенный с помощью Scala 2.11"
   "shell", "org.apache.zeppelin:zeppelin-shell:0.7.3", "Команда Shell"

