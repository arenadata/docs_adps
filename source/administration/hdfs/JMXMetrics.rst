APIs JMX Metrics для HDFS Daemons
===================================

Для доступа к показателям **HDFS** можно использовать методы с помощью API-интерфейсов **Java Management Extensions** (**JMX**).

Доступ к метрикам **JMX** можно получить через веб-интерфейс **HDFS daemon**, что является рекомендуемым методом.

Например, для доступа к **NameNode JMX** необходимо использовать следующий формат команды:

  :command:`curl -i http://localhost:50070/jmx`

Для извлечения только определенного ключа можно использовать параметр ``qry``:

  :command:`curl -i http://localhost:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeInfo`


Прямой доступ к удаленному агенту JMX
---------------------------------------

Метод требует, чтобы удаленный агент **JMX** был включен с опцией *JVM* при запуске сервисов **HDFS**.

Например, следующие параметры *JVM* в *hadoop-env.sh* используются для включения удаленного агента **JMX** для *NameNode*. Он работает на порту *8004* с отключенным **SSL**. Имя пользователя и пароль сохраняются в файле *mxremote.password*.
::
 
 export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote
 -Dcom.sun.management.jmxremote.password.file=$HADOOP_CONF_DIR/jmxremote.password
 -Dcom.sun.management.jmxremote.ssl=false
 -Dcom.sun.management.jmxremote.port=8004 $HADOOP_NAMENODE_OPTS"

Подробности о связанных настройках можно найти `здесь <http://docs.oracle.com/javase/7/docs/technotes/guides/management/agent.html>`_. Также можно использовать инструмент `jmxquery <https://code.google.com/p/jmxquery/>`_ для извлечения информации через **JMX**.

**Hadoop** также имеет встроенный инструмент запросов **JMX** -- ``jmxget``. Например:

  :command:`hdfs jmxget -server localhost -port 8004 -service NameNode`

.. important:: Инструмент *jmxget* требует, чтобы аутентификация была отключена, так как она не принимает имя пользователя и пароль

Использование **JMX** может быть сложным для персонала, который не знаком с настройкой **JMX**, особенно **JMX** с **SSL** и **firewall tunnelling**. Поэтому обычно рекомендуется собирать информацию **JXM** через веб-интерфейс **HDFS daemon**, а не напрямую обращаться к удаленному агенту **JMX**.

