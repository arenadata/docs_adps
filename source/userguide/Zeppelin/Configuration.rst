Конфигурация Apache Zeppelin
=============================

+ `Свойства Apache Zeppelin`_
+ `Конфигурация SSL`_

  + `Создание и настройка сертификатов`_
  + `Настройка SSL на стороне сервера`_
  + `Включение проверки подлинности сертификата на стороне клиента`_
  + `Скрытие паролей с помощью Jetty Password Tool`_


Свойства Apache Zeppelin
-------------------------

Существует две локации, в которых можно настроить **Apache Zeppelin**:

+ Переменные окружения могут быть заданы в *conf/zeppelin-env.sh* (*conf\zeppelin-env.cmd* для ОС Windows);
+ Свойства Java могут быть определены в *conf/zeppelin-site.xml*.

В случае если настроены обе локации, переменные окружения  будут приоритетными.


.. list-table:: Параметры Zeppelin, их значения и описание
   :header-rows: 1   
   :widths: 50, 50
   :class: longtable
    
   * - Параметр Zeppelin
     - Значение и описание
   * - + zeppelin-env.sh:	
         
       ZEPPELIN_PORT
       
       + zeppelin-site.xml:
       
       zeppelin.server.port
       
     - 
        *8080*
        
        Порт сервера Zeppelin. Примечание: необходимо убедиться, что не используется тот же порт, что для разработки веб-приложений Zeppelin (по умолчанию: 9000)
        
        
   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_PORT
       
       + zeppelin-site.xml:
       
       zeppelin.server.ssl.port
       
     - 
        *8443*
        
        ssl порт сервера Zeppelin (используется, когда значение ssl свойства установлено true)


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_MEM
       
       + zeppelin-site.xml:
       
       N/A
       
     - 
        *-Xmx1024m -XX:MaxPermSize=512m*
        
        Параметры JVM mem


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_INTP_MEM
       
       + zeppelin-site.xml:
       
       N/A
       
     - 
        *ZEPPELIN_MEM*
        
        Параметры JVM mem для процесса интерпретатора


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_JAVA_OPTS
       
       + zeppelin-site.xml:
       
       N/A
       
     - 
        
        Параметры JVM


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_ALLOWED_ORIGINS
       
       + zeppelin-site.xml:
       
       zeppelin.server.allowed.origins
       
     - 
        *символ* "*"
        
        Позволяет разделяя знаком запятой перечислить разрешенные источники для REST и websockets подключений. Например, http://localhost:8080


   * - + zeppelin-env.sh:	
         
       N/A
       
       + zeppelin-site.xml:
       
       zeppelin.anonymous.allowed
       
     - 
        *true*
        
        Вход для неавторизованного пользователя разрешен по умолчанию


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SERVER_CONTEXT_PATH
       
       + zeppelin-site.xml:
       
       zeppelin.server.context.path
       
     - 
        *символ "/"*
        
        Относительный путь веб-приложения


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL
       
       + zeppelin-site.xml:
       
       zeppelin.ssl
       
     - 
        *false*


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_CLIENT_AUTH
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.client.auth
       
     - 
        *false*


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_KEYSTORE_PATH
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.keystore.path
       
     - 
        *keystore*
 

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_KEYSTORE_TYPE
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.keystore.type
       
     - 
        *JKS*
 

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_KEYSTORE_PASSWORD
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.keystore.password
       
     - 
 

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_KEY_MANAGER _PASSWORD
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.key.manager.password
       
     - 
 

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_TRUSTSTORE_PATH
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.truststore.path
       
     - 
  

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_TRUSTSTORE_TYPE
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.truststore.type
       
     - 
  

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SSL_TRUSTSTORE _PASSWORD
       
       + zeppelin-site.xml:
       
       zeppelin.ssl.truststore.password
       
     - 
 

   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_HOMESCREEN
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.homescreen
       
     - 
        Отображение идентификаторов блокнотов на рабочем столе Apache Zeppelin. Например, 2A94M5J1Z


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_HOMESCREEN _HIDE
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.homescreen.hide
       
     - 
        *false*
        
        Скрытие идентификатора блокнота, установленного в ZEPPELIN_NOTEBOOK_HOMESCREEN на рабочем столе Apache Zeppelin


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_WAR_TEMPDIR
       
       + zeppelin-site.xml:
       
       zeppelin.war.tempdir
       
     - 
        *webapps*
        
        Расположение временного каталога jetty


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_DIR
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.dir
       
     - 
        *notebook*
        
        Каталог root, в котором хранятся каталоги блокнотов


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_STORAGE
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.storage
       
     - 
        *org.apache.zeppelin.notebook.repo. GitNotebookRepo*
        
        Список мест хранения блокнотов, перечисленный через запятую


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_ONE_WAY_SYNC
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.one.way.sync
       
     - 
        *false*
        
        Если есть несколько мест для хранения блокнотов, следует ли рассматривать первое как единственное?


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_NOTEBOOK_PUBLIC
       
       + zeppelin-site.xml:
       
       zeppelin.notebook.public
       
     - 
        *true*
        
        Сделать блокнот общедоступным по умолчанию при создании или импортировании (при указании только владельцев). Если установлено значение false, необходимо добавить пользователей, для которых доступно чтение и редактирование, таким образом делая блокнот недоступным и невидимым для пользователей, не имующих прав на него


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_INTERPRETERS
       
       + zeppelin-site.xml:
       
       zeppelin.interpreters
       
     - 
        *org.apache.zeppelin.spark.SparkInterpreter, org.apache.zeppelin.spark.PySparkInterpreter, org.apache.zeppelin.spark.SparkSqlInterpreter, org.apache.zeppelin.spark.DepInterpreter, org.apache.zeppelin.markdown.Markdown, org.apache.zeppelin.shell.ShellInterpreter, ...*
        
        Конфигурации (классы) интерпретатора с разделителями-запятыми. Примечание: это свойство устарело с Zeppelin-0.6.0 и не будет поддерживаться Zeppelin-0.7.0


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_INTERPRETER_DIR
       
       + zeppelin-site.xml:
       
       zeppelin.interpreter.dir
       
     - 
        *interpreter*
        
        Каталог интерпретатора


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_INTERPRETER_DEP _MVNREPO
       
       + zeppelin-site.xml:
       
       zeppelin.interpreter.dep.mvnRepo
       
     - 
        *http://repo1.maven.org/maven2/*
        
        Удаленный основной репозиторий для загрузки дополнительных зависимостей интерпретатора


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_DEP_LOCALREPO
       
       + zeppelin-site.xml:
       
       zeppelin.dep.localrepo
       
     - 
        *local-repo*
        
        Локальный репозиторий для загрузки зависимостей. Модули npm


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_HELIUM_NPM_REGISTRY
       
       + zeppelin-site.xml:
       
       zeppelin.helium.npm.registry
       
     - 
        *http://registry.npmjs.org/*
        
        Удаленный реестр Npm для загрузки зависимостей Helium


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_INTERPRETER_OUTPUT _LIMIT
       
       + zeppelin-site.xml:
       
       zeppelin.interpreter.output.limit
       
     - 
        *102400*
        
        Размер выходного сообщения от интерпретатора. Если сообщение превышает заданный размер, то она урезается до заданного значения.


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_WEBSOCKET_MAX_TEXT _MESSAGE_SIZE
       
       + zeppelin-site.xml:
       
       zeppelin.websocket.max.text.message.size	
       
     - 
        *1024000*
        
        Размер (в символах) максимального текстового сообщения, которое может быть получено от websocket


   * - + zeppelin-env.sh:	
         
       ZEPPELIN_SERVER_DEFAULT_DIR _ALLOWED
       
       + zeppelin-site.xml:
       
       zeppelin.server.default.dir.allowed	
       
     - 
        *false*
        
        Доступность каталогов на сервере


Конфигурация SSL
-----------------

Включение **SSL** требует некоторых изменений конфигурации -- следует создать сертификаты, а затем обновить необходимые настройки для подключения проверки подлинности **SSL** со стороны сервера и/или клиентской стороны.


Создание и настройка сертификатов
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Информацию о создании сертификатов и хранилище ключей можно найти по `ссылке <https://wiki.eclipse.org/Jetty/Howto/Configure_SSL>`_. Краткий пример можно найти в верхнем ответе на вопрос `StackOverflow <http://stackoverflow.com/questions/4008837/configure-ssl-on-jetty>`_.

Хранилище ключей **keystore** содержит закрытый ключ и сертификат на сервере, а хранилище **trustore** содержит сертификаты доверенных клиентов. Необходимо убедиться, что путь и пароль для этих двух хранилищ правильно настроены в полях пароля, приведенных ниже. Они могут быть скрыты с помощью **Jetty Password Tool**. **Maven** подтягивает все зависимости для сборки **Zeppelin**, один из jar-файлов **Jetty** содержит инструмент **Jetty Password Tool**. Необходимо вызвать команду из каталога сборки *Zeppelin Home* с соответствующей версией, пользователем и паролем:

   ::
   
    java -cp ./zeppelin-server/target/lib/jetty-all-server-<version>.jar org.eclipse.jetty.util.security.Password <user> <password>

Если используется самоподписанный сертификат, сертификат, подписанный недоверенным центром сертификации, или если включена аутентификация клиента, то у клиента в браузере должно появиться исключение как в случае https-порта, так и websocket-порта. Это можно проверить, установив HTTPS соединение по обоими портами в браузере (например, если порты *443* и *8443*, при переходе на *https://127.0.0.1:443* и *https://127.0.0.1:8443*). Данный шаг может быть пропущен, если сертификат сервера подписан доверенным центром сертификации и аутентификация клиента отключена.


Настройка SSL на стороне сервера
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для включения **SSL** на стороне сервера необходимо отредактировать в *zeppelin-site.xml* следующие свойства: 

   ::
   
    <property>
      <name>zeppelin.server.ssl.port</name>
      <value>8443</value>
      <description>Server ssl port. (used when ssl property is set to true)</description>
    </property>

    <property>
      <name>zeppelin.ssl</name>
      <value>true</value>
      <description>Should SSL be used by the servers?</description>
    </property>

    <property>
      <name>zeppelin.ssl.keystore.path</name>
      <value>keystore</value>
      <description>Path to keystore relative to Zeppelin configuration directory</description>
    </property>

    <property>
      <name>zeppelin.ssl.keystore.type</name>
      <value>JKS</value>
      <description>The format of the given keystore (e.g. JKS or PKCS12)</description>
    </property>

    <property>
      <name>zeppelin.ssl.keystore.password</name>
      <value>change me</value>
      <description>Keystore password. Can be obfuscated by the Jetty Password tool</description>
    </property>

    <property>
      <name>zeppelin.ssl.key.manager.password</name>
      <value>change me</value>
      <description>Key Manager password. Defaults to keystore password. Can be obfuscated.</description>
    </property>


Включение проверки подлинности сертификата на стороне клиента
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для включения аутентификации по сертификату на стороне клиента необходимо отредактировать в *zeppelin-site.xml* следующие свойства:

   ::
   
    <property>
      <name>zeppelin.server.ssl.port</name>
      <value>8443</value>
      <description>Server ssl port. (used when ssl property is set to true)</description>
    </property>

    <property>
      <name>zeppelin.ssl.client.auth</name>
      <value>true</value>
      <description>Should client authentication be used for SSL connections?</description>
    </property>

    <property>
      <name>zeppelin.ssl.truststore.path</name>
      <value>truststore</value>
      <description>Path to truststore relative to Zeppelin configuration directory. Defaults to the keystore path</description>
    </property>

    <property>
      <name>zeppelin.ssl.truststore.type</name>
      <value>JKS</value>
      <description>The format of the given truststore (e.g. JKS or PKCS12). Defaults to the same type as the keystore type</description>
    </property>

    <property>
      <name>zeppelin.ssl.truststore.password</name>
      <value>change me</value>
      <description>Truststore password. Can be obfuscated by the Jetty Password tool. Defaults to the keystore password</description>
    </property>


Скрытие паролей с помощью Jetty Password Tool
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Лучшие практики по безопасности рекомендуют не использовать текстовые пароли, а с помощью утилиты **Jetty Password Tool** (см. `документацию <http://www.eclipse.org/jetty/documentation/current/configuring-security-secure-passwords.html>`_) можно усложнить пароли, используемые для доступа к **keystore** и **trustore**.

После установки **Jetty Password Tool**:

   ::
   
    java -cp $ZEPPELIN_HOME/zeppelin-server/target/lib/jetty-util-9.2.15.v20160210.jar \
             org.eclipse.jetty.util.security.Password  \
             password
    
    2016-12-15 10:46:47.931:INFO::main: Logging initialized @101ms
    password
    OBF:1v2j1uum1xtv1zej1zer1xtn1uvk1v1v
    MD5:5f4dcc3b5aa765d61d8327deb882cf99

Затем необходимо обновить конфигурацию с паролем:

   ::
   
    <property>
      <name>zeppelin.ssl.keystore.password</name>
      <value>OBF:1v2j1uum1xtv1zej1zer1xtn1uvk1v1v</value>
      <description>Keystore password. Can be obfuscated by the Jetty Password tool</description>
    </property>


.. important:: После обновления настроек сервер Zeppelin необходимо перезапустить
