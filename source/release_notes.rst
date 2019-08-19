Release notes
=============

Ниже представлен список версий и состав сервисов Apache в ADH |version|, release notes и известные проблемы.

Столбец *"Версия"* содержит ссылки на release notes компонентов.

+-------+------------------+--------------------------+--------------------------------+
| № пп. | Сервис           | Компонент                | Версия                         |
+=======+==================+==========================+================================+
| 1     | Apache HBase     | Master server            | `2.0.2 <hbase_version_>`_      |
|       |                  +--------------------------+                                |
|       |                  | RegionServer             |                                |
|       |                  +--------------------------+                                |
|       |                  | Thrift2 server           |                                |
|       |                  +--------------------------+--------------------------------+
|       |                  | Phoenix query server     | `5.0.0 <phoenix_version_>`_    |
+-------+------------------+--------------------------+--------------------------------+
| 2     | Apache HDFS      | DataNode                 | `3.1.2 <hdfs_version_>`_       |
|       |                  +--------------------------+                                |
|       |                  | NameNode                 |                                |
|       |                  +--------------------------+                                |
|       |                  | Secondary NameNode       |                                |
+-------+------------------+--------------------------+--------------------------------+
| 3     | Apache Hive      | HiveServer2              | `3.1.1 <hive_version_>`_       |
|       |                  +--------------------------+                                |
|       |                  | Metastore                |                                |
|       |                  +--------------------------+--------------------------------+
|       |                  | Tez                      | `0.9.2 <tez_version_>`_        |
|       |                  +--------------------------+                                |
|       |                  | TezUI                    |                                |
+-------+------------------+--------------------------+--------------------------------+
| 4     | Apache Spark     | History server           | `2.3.2 <spark_version_>`_      |
|       |                  +--------------------------+                                |
|       |                  | Thrift server            |                                |
|       |                  +--------------------------+--------------------------------+
|       |                  | Livy                     | `0.6.0 <livy_version_>`_       |
+-------+------------------+--------------------------+--------------------------------+
| 5     | Apache YARN      | MapReduce History server | `3.1.2 <yarn_version_>`_       |
|       |                  +--------------------------+                                |
|       |                  | NodeManager              |                                |
|       |                  +--------------------------+                                |
|       |                  | ResourceManager          |                                |
|       |                  +--------------------------+                                |
|       |                  | Timeline server          |                                |
+-------+------------------+--------------------------+--------------------------------+
| 6     | Apache Zeppelin  | Server                   | `0.8.1 <zeppelin_version_>`_   |
+-------+------------------+--------------------------+--------------------------------+
| 7     | Apache Zookeeper | Server                   | `3.4.14 <zookeeper_version_>`_ |
+-------+------------------+--------------------------+--------------------------------+

**Arenadata** оставляет за собой право добавления необходимых изменений и патчей для обеспечения стабильного функционирования компонентов и их интеграции.

.. 2.0.5 RN is for whole 2.0 line

.. _hbase_version: https://apache.org/dist/hbase/2.0.5/RELEASENOTES.md
.. _phoenix_version: https://phoenix.apache.org/release_notes.html#Phoenix_5.0.0-alpha_Release_Notes
.. _hdfs_version: https://hadoop.apache.org/docs/r3.1.2/hadoop-project-dist/hadoop-common/release/3.1.2/RELEASENOTES.3.1.2.html
.. _hive_version: https://issues.apache.org/jira/secure/ReleaseNote.jspa?version=12344240&styleName=Text&projectId=12310843
.. _tez_version: https://tez.apache.org/releases/0.9.2/release-notes.txt
.. _spark_version: https://spark.apache.org/releases/spark-release-2-3-2.html
.. _livy_version: https://livy.apache.org/history/#v0-6-0-incubating
.. _yarn_version: https://hadoop.apache.org/docs/r3.1.2/hadoop-project-dist/hadoop-common/release/3.1.2/RELEASENOTES.3.1.2.html
.. _zeppelin_version: https://zeppelin.apache.org/releases/zeppelin-release-0.8.1.html
.. _zookeeper_version: https://zookeeper.apache.org/doc/r3.4.14/releasenotes.html

.. important:: Контактная информация службы поддержки -- e-mail: info@arenadata.io
