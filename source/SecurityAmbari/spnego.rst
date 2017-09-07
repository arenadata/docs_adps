Аутентификация SPNEGO для Hadoop
--------------------------------

По умолчанию доступ к HTTP-сервисам и пользовательскому интерфейсу кластера не настроен на необходимость аутентификации. 
Аутентификацию **Kerberos** можно настроить для веб-интерфейсов **HDFS**, **YARN**, **MapReduce2**, **HBase** и **Oozie**.



Настройка сервера Ambari для HTTP с проверкой подлинности
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для работы **Ambari** с кластером, требующим аутентифицированный HTTP-доступ к веб-интерфейсу, необходимо настроить сервер **Ambari** для **Kerberos**. Подробное описание настроек приведено в разделе "Настройка Kerberos для сервера Ambari (опционально)". 



Настройка HTTP-аутентификации для HDFS, YARN, MapReduce2, HBase и Oozie
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для настройки HTTP-аутентификации для **HDFS**, **YARN**, **MapReduce2**, **HBase** и **Oozie** необходимо выполнить следующие действия:

1. Создать секретный ключ, используемый для подписания токенов аутентификации. Этот файл должен содержать случайные данные и размещаться на каждом узле кластера. Он также должен принадлежать пользователям и группам *hdfs*, входящим в группу *hadoop*. Права должны быть установлены на *440*. Например:

  :command:`dd if=/dev/urandom of=/etc/security/http_secret bs=1024 count=1`

  :command:`chown hdfs:hadoop /etc/security/http_secret`

  :command:`chmod 440 /etc/security/http_secret`

2. В Ambari Web перейти по вкладкам :menuselection:`"Services --> HDFS  --> Configs"`;
3. Добавить или изменить свойства конфигурации в *Advanced core-site*, приведенные в таблице 6.

.. csv-table:: Табл. 6. Новые значения свойств конфигурации в Advanced core-site
   :header: "Свойство", "Новое значение"
   :widths: 25, 25

   "hadoop.http.authentication.simple.anonymous.allowed", "false"
   "hadoop.http.authentication.signature.secret.file", "/etc/security/http_secret"
   "hadoop.http.authentication.type", "kerberos"
   "hadoop.http.authentication.kerberos.keytab", "/etc/security/keytabs/spnego.service.keytab"
   "hadoop.http.authentication.kerberos.principal", "HTTP/_HOST@ **EXAMPLE.COM**"
   "hadoop.http.filter.initializers", "org.apache.hadoop.security.AuthenticationFilterInitializer"
   "hadoop.http.authentication.cookie.domain", "**mycompany.local**"
   
Выделенные в таблице записи зависят от сайта. Свойство *hadoop.http.authentication.cookie.domain* основано на полностью доменных именах серверов в кластере. Например, если **FQDN** вашего **NameNode** – *host1.mycompany.local*, то *hasoop.http.authentication.cookie.domain* должен быть установлен в *mycompany.local*.

4.	Сохранить настройки и перезапустить соответствующие сервера.
























