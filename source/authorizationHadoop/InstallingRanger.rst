Установка Ranger с помощью Ambari
---------------------------------

**Apache Ranger** можно установить при помощи пользовательского интерфейса **Ambari** или вручную, используя платформу **Arenadata Hadoop**. В сравнении с ручным процессом установки, требующего выполнения ряда шагов, установка **Ranger** с использованием интерфейса **Ambari** проще. Опция службы **Ranger** доступна через мастер **Add Service** после инсталляции кластера **ADH** с помощью установщика.

После установки и настройки **Ambari** можно использовать мастер добавления служб для установки следующих компонентов:

+ Ranger Admin
+ Ranger UserSync
+ Ranger Key Management Service

После установки и запуска этих компонентов можно включить плагины **Ranger**, перейдя к каждому отдельному сервису **Ranger** (**HDFS**, **HBase**, **Hiveserver2**, **Storm**, **Knox**, **YARN** и **Kafka**) и изменив конфигурацию в расширенном режиме *ranger-<service>-plugin-properties*.

.. important:: При включении плагина Ranger необходимо перезапустить компонент

.. important:: Включение Apache Storm или Apache Kafka требует включения Kerberos

При обновлении **ADH** (на **Ambari 2.5.0**) установка **Ranger DB** выполняется при первом запуске **Ranger** (в предыдущих версиях настройка **Ranger DB** выполнялась во время установки). Это означает, что **Ranger** при первом запуске может занять больше времени, чем раньше (последующие перезагрузки будут такими же быстрыми, как и раньше).


Предварительные требования к установке
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Перед установкой **Ranger** необходимо убедиться, что кластер отвечает следующим требованиям:

+ Рекомендуется хранить аудиты как в HDFS, так и в Solr. Конфигурация по умолчанию для Ranger Audits в Solr использует общий экземпляр Solr, предоставляемый сервисом Ambari Infra (дополнительные сведения см. в разделе `Ranger Audit`_);

+ Чтобы обеспечить принудительную авторизацию на уровне групп LDAP/AD в Hadoop, необходимо настроить сопоставление групп Hadoop для LDAP/AD для LDAP (`Настройка сопоставления групп Hadoop для LDAP/AD`_);

+ Должен быть запущен и доступен экземпляр базы данных MySQL, Oracle, PostgreSQL или Amazon RDS, который будет использоваться Ranger. Установщик Ranger создаст двух новых пользователей (имена по умолчанию: *rangeradmin* и *rangerlogger*) и две новые базы данных (имена по умолчанию: *ranger* и *ranger_audit*).

  Конфигурация экземпляра для Ranger для некоторых баз данных описана в следующих разделах:

  + `Конфигурация MySQL`_
  + `Конфигурация PostgreSQL`_
  + `Конфигурация Oracle`_
  
  При использовании Amazon RDS есть дополнительные требования (`Требования к Amazon RDS`_).

+ При решении не предоставлять данные учетной записи администратора базы данных (DBA) установщику Ambari Ranger, можно использовать Python-скрипт *dba_script.py* для создания пользователей базы данных Ranger DB без предоставления этой информации установщику. После чего запустить обычную установку Ambari Ranger без указания имени и пароля администратора. Дополнительные сведения приведены в разделе `Настройка пользователей без использования учетных данных DBA`_.


Настройка сопоставления групп Hadoop для LDAP/AD
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Для обеспечения принудительной авторизации на уровне групп **LDAP/AD** в **Hadoop** необходимо настроить сопоставление групп **Hadoop** для **LDAP/AD**.

.. important:: Доступ к LDAP и сведения о подключении: настройки LDAP могут различаться в зависимости от используемой реализации LDAP

Существует три способа настройки сопоставления групп **Hadoop**.

+ **Настройка сопоставления групп Hadoop для LDAP/AD с использованием SSSD (рекомендуется)**

Для сопоставления групп рекомендуется использовать `SSSD <https://fedoraproject.org/wiki/Features/SSSD>`_ или один из следующих сервисов подключения ОС **Linux** к **LDAP**:

+ Centrify
+ NSLCD
+ Winbind
+ SAMBA

Большинство перечисленных сервисов позволяет не только искать пользователя и перечислять группы, но также выполнять другие действия на хосте. При этом ни одно из этих действий не требуется для сопоставления групп **LDAP** в **Hadoop**. Поэтому, оценивая эти сервисы, необходимо понимать разницу между модулем **NSS** (который выполняет разрешение пользователь/группа) и модулем **PAM** (который выполняет аутентификацию пользователя). Для возможности поиска (или "валидации") пользователя в **LDAP** и перечисления групп требуется **NSS**. А **PAM** может представлять угрозу безопасности.


+ **Настройка сопоставления групп Hadoop в файле core-site.xml**

Настройка **Hadoop** для использования сопоставления групп на основе **LDAP** в файле *core-site.xml* осуществляется в следующем порядке:

1. Добавить свойства, показанные в приведенном ниже примере, в файл *core-site.xml*. Необходимо указать значение для привязанного пользователя, его пароль и другие свойства, специфичные для экземпляра LDAP, и убедиться, что фильтры классов объектов, пользователей и групп соответствуют значениям, указанным в экземпляре LDAP.

  ::
  
   <property>
   <name>hadoop.security.group.mapping</name>
   <value>org.apache.hadoop.security.LdapGroupsMapping</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.bind.user</name>
   <value>cn=Manager,dc=hadoop,dc=apache,dc=org</value>
   </property>
   
   <!–
   <property>
   <name>hadoop.security.group.mapping.ldap.bind.password.file</name>
   <value>/etc/hadoop/conf/ldap-conn-pass.txt</value>
   </property>
   –>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.bind.password</name>
   <value>hadoop</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.url</name>
   <value>ldap://localhost:389/dc=hadoop,dc=apache,dc=org</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.url</name>
   <value>ldap://localhost:389/dc=hadoop,dc=apache,dc=org</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.base</name>
   <value></value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.search.filter.user</name>
   <value>(&amp;(|(objectclass=person)(objectclass=applicationProcess))(cn={0}))</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.search.filter.group</name>
   <value>(objectclass=groupOfNames)</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.search.attr.member</name>
   <value>member</value>
   </property>
   
   <property>
   <name>hadoop.security.group.mapping.ldap.search.attr.group.name</name>
   <value>cn</value>
   </property>

2. В зависимости от конфигурации можно обновлять сопоставления пользователей и групп с помощью следующих команд HDFS и YARN:

  ::
  
   hdfs dfsadmin -refreshUserToGroupsMappings
   yarn rmadmin -refreshUserToGroupsMappings

3. Проверить сопоставление групп LDAP, выполнив команду *hdfs groups*. Команда отображает группы из LDAP для текущего пользователя. При настроенном сопоставлении групп LDAP разрешения HDFS могут использовать группы, определенные в LDAP для контроля доступа.


+ **Ручное создание пользователей и групп в среде Linux**

Также можно вручную создавать пользователей и группы в среде `Linux <https://www.linode.com/docs/tools-reference/linux-users-and-groups>`_.


Конфигурация MySQL
~~~~~~~~~~~~~~~~~~~

При использовании **MySQL** машина для хранения таблиц политики администратора **Ranger** обязательно должна поддерживать транзакции. **InnoDB** -- это пример машины, поддерживающей транзакции. 

При использовании **Amazon RDS** есть дополнительные требования (`Требования к Amazon RDS`_).

Для конфигурации экземпляра для **Ranger** для **MySQL** необходимо выполнить следующие шаги:

1. Для создания баз данных Ranger должен использоваться администратор базы данных MySQL. Для создания пользователя *rangerdba* с паролем *rangerdba* необходимо:

  + Войти в систему как пользователь *root* и использовать следующие команды, чтобы создать пользователя *rangerdba* и предоставить ему соответствующие права:
  
    ::
    
     CREATE USER 'rangerdba'@'localhost' IDENTIFIED BY 'rangerdba';
     
     GRANT ALL PRIVILEGES ON *.* TO 'rangerdba'@'localhost';
     
     CREATE USER 'rangerdba'@'%' IDENTIFIED BY 'rangerdba';
     
     GRANT ALL PRIVILEGES ON *.* TO 'rangerdba'@'%';
     
     GRANT ALL PRIVILEGES ON *.* TO 'rangerdba'@'localhost' WITH GRANT OPTION;
     
     GRANT ALL PRIVILEGES ON *.* TO 'rangerdba'@'%' WITH GRANT OPTION;
     
     FLUSH PRIVILEGES;

  + Использовать команду *exit* для выхода из MySQL;
  
  + Теперь можно подключиться к базе данных как *rangerdba*, используя следующую команду:

    ::
    
     mysql -u rangerdba -prangerdba

    После тестирования входа в систему *rangerdba* использовать команду *exit* для выхода из MySQL.

2. Следующая команда используется для подтверждения, что файл *mysql-connector-java.jar* находится в папке общего доступа Java (команда должна быть запущена на сервере, на котором установлен сервер Ambari):

  ::
  
   ls /usr/share/java/mysql-connector-java.jar

Если файл находится не в каталоге общего доступа Java, использовать следующую команду для установки соединения:

+ RHEL/CentOS/Oracle Linux:

  ::
   
   yum install mysql-connector-java*

+ SLES:

  ::
  
   zypper install mysql-connector-java*

3. Использовать следующий формат команды, чтобы установить путь *jdbc/driver/path* на основе местоположения файла *.jar* драйвера MySQL JDBC. Команда должна выполняться на сервере, на котором установлен сервер Ambari:

  ::
  
   ambari-server setup --jdbc-db={database-type} --jdbc-driver={/jdbc/driver/path}

Например:

  ::
  
   ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar



Конфигурация PostgreSQL
~~~~~~~~~~~~~~~~~~~~~~~

При использовании **Amazon RDS** есть дополнительные требования (`Требования к Amazon RDS`_).

Для конфигурации экземпляра для **Ranger** для **PostgreSQL** необходимо выполнить следующие шаги:

1. На хосте PostgreSQL установить соответствующий коннектор PostgreSQL:

  + RHEL/CentOS/Oracle Linux:
  
    ::
    
     yum install postgresql-jdbc*

  + SLES:
  
    ::
    
     zypper install -y postgresql-jdbc
     
2. Убедиться, что файл *.jar* находится в папке общего доступа Java:

  ::
  
   ls /usr/share/java/postgresql-jdbc.jar

3. Изменить режим доступа файла *.jar* на *644*:

  ::
  
   chmod 644 /usr/share/java/postgresql-jdbc.jar
     
4. Для создания баз данных Ranger должен использоваться администратор базы данных PostgreSQL. Для создания пользователя *rangerdba* и предоставления ему соответствующих прав следует использовать команду:

  ::
  
   echo "CREATE DATABASE $dbname;" | sudo -u $postgres psql -U postgres
   echo "CREATE USER $rangerdba WITH PASSWORD '$passwd';" | sudo -u $postgres psql -U postgres
   echo "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $rangerdba;" | sudo -u $postgres psql -U postgres 

Где *$postgres* -- пользователь Postgres, *$dbname* -- имя базы данных PostgreSQL;

5. Использовать следующий формат команды, чтобы установить путь *jdbc/driver/path* на основе местоположения файла *.jar* драйвера PostgreSQL JDBC (команда должна выполняться на сервере, на котором установлен сервер Ambari):

  ::
  
   ambari-server setup --jdbc-db={database-type} --jdbc-driver={/jdbc/driver/path}

Например:

  ::
  
   ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar

6. Выполнить следующую команду:

  ::
  
   export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${JAVA_JDBC_LIBS}:/connector jar path

7. Разрешить доступ *Allow Access* для пользователей Ranger:

  + изменить *listen_addresses='localhost'* на *listen_addresses='*' ('*' = any)*, чтобы прослушивать все IP-адреса в *postgresql.conf*;
  + внести следующие изменения пользователям *Ranger db* и *Ranger audit db* в файле *pg_hba.conf* (:numref:`Рис.%s.<security_authorization_Ranger-user>`):

.. _security_authorization_Ranger-user:

.. figure:: ../imgs/security_authorization_Ranger-user.*
   :align: center

   Необходимые изменения пользователям Ranger db и Ranger audit db

8. После редактирования файла *pg_hba.conf* запустить команду для обновления конфигурации базы данных PostgreSQL:

  ::
  
   sudo -u postgres /usr/bin/pg_ctl -D $PGDATA reload

Например, если файл *pg_hba.conf* находится в каталоге */var/lib/pgsql/data*, значением *$PGDATA* является */var/lib/pgsql/data*.



Конфигурация Oracle
~~~~~~~~~~~~~~~~~~~

При использовании **Amazon RDS** есть дополнительные требования (`Требования к Amazon RDS`_).

Для конфигурации экземпляра для **Ranger** для **Oracle** необходимо выполнить следующие шаги:

1. На узле Oracle установить соответствующий JDBC-файл *.jar*:

  + Загрузить драйвер `Oracle JDBC (OJDBC) <http://www.oracle.com/technetwork/database/features/jdbc/index-091264.html>`_
  + Для Oracle Database 11g: выбрать Oracle Database 11g Release 2 drivers > ojdbc6.jar
  + Для Oracle Database 12c: выбрать Oracle Database 12c Release 1 driver > ojdbc7.jar
  + Скопировать файл *.jar* в папку общего доступа Java. Например, *cp ojdbc7.jar /usr/share/java/*
  + Убедиться, что .jar-файл имеет соответствующие разрешения: 

    ::
    
     chmod 644 /usr/share/java/ojdbc7.jar

2. Для создания баз данных Ranger должен использоваться администратор базы данных Oracle.

Для создания пользователя *RANGERDBA* и предоставления ему прав с помощью SQL*Plus -- утилиты администрирования базы данных Oracle, следует использовать команду:

  ::
  
   # sqlplus sys/root as sysdba
   CREATE USER $RANGERDBA IDENTIFIED BY $RANGERDBAPASSWORD; 
   GRANT SELECT_CATALOG_ROLE TO $RANGERDBA;
   GRANT CONNECT, RESOURCE TO $RANGERDBA; 
   QUIT;

3. Использовать следующий формат команды, чтобы установить путь *jdbc/driver/path* на основе местоположения файла *.jar* драйвера Oracle JDBC (команда должна выполняться на сервере, на котором установлен сервер Ambari):

  ::
  
   ambari-server setup --jdbc-db={database-type} --jdbc-driver={/jdbc/driver/path}

Например:

  ::
  
   ambari-server setup --jdbc-db=oracle --jdbc-driver=/usr/share/java/ojdbc6.jar



Требования к Amazon RDS
~~~~~~~~~~~~~~~~~~~~~~~~

**Ranger** требует наличия реляционной базы данных в качестве хранилища политик. Существуют дополнительные требования для баз данных на основе **Amazon RDS** из-за специфичности настроек и управления.

+ **MySQL/MariaDB**

Во время установки **Ranger** необходимо изменить переменную *log_bin_trust_function_creators* на значение *1*. Через панель управления RDS Dashboard > Parameter group (в левой части страницы):

  + Установить переменной MySQL Server *log_bin_trust_function_creators* значение *1*;
  + (Опционально) после завершения установки Ranger сбросить значение параметра *log_bin_trust_function_creators* в исходное значение (требование к значению переменной относится только на время установки Ranger).
  
Дополнительная информация:

  + `Stratalux: Why You Should Always Use a Custom DB Parameter Group When Creating an RDS Instance <https://www.stratalux.com/blog/always-use-custom-db-parameter-group-creating-rds-instance/>`_
  + `AWS Documentation>Amazon RDS DB Instance Lifecycle » Working with DB Parameter Groups <http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html>`_
  + `MySQL 5.7 Reference Manual >Binary Logging of Stored Programs <https://dev.mysql.com/doc/refman/5.7/en/stored-programs-logging.html>`_
  

+ **PostgreSQL**

Пользователь базы данных **Ranger** на сервере **Amazon RDS PostgreSQL Server** должен быть создан до установки **Ranger** и ему должна быть предоставлена роль *CREATEDB*.

1. Используя основную учетную запись пользователя (заведенную при создании экземпляра RDS PostgreSQL), войти в Amazon RDS PostgreSQL Server и выполнить команды:

  ::
  
   CREATE USER $rangerdbuser WITH LOGIN PASSWORD 'password'
   
   GRANT $rangerdbuser to $postgresroot

Где *$postgresroot* -- это основная учетная запись пользователя RDS PostgreSQL (например, *postgresroot*), а *$rangerdbuser* -- имя пользователя базы данных Ranger (например: *rangeradmin*).

2. Если используется Ranger KMS, выполнить следующие команды:

  ::
  
   CREATE USER $rangerkmsuser WITH LOGIN PASSWORD 'password'

   GRANT $rangerkmsuser to $postgresroot

Где *$postgresroot* -- это основная учетная запись пользователя RDS PostgreSQL (например, *postgresroot*), а *$rangerkmsuser* -- имя пользователя Ranger KMS (например, *rangerkms*).



+ **Oracle**

Из-за ограничений в `Amazon RDS <https://forums.aws.amazon.com/thread.jspa?messageID=450535>`_ создание пользователя базы данных **Ranger** и табличного пространства, а так же предоставление пользователю **Ranger** необходимых привилегий выполняется вручную:

1. Используя основную учетную запись пользователя (заведенную при создании экземпляра RDS Oracle), войти в RDS Oracle Server и выполнить команды:

  ::
  
   create user $rangerdbuser identified by “password”;
   GRANT CREATE SESSION,CREATE PROCEDURE,CREATE TABLE,CREATE VIEW,CREATE SEQUENCE,CREATE PUBLIC SYNONYM,CREATE ANY SYNONYM,CREATE TRIGGER,UNLIMITED Tablespace TO $rangerdbuser;
   create tablespace $rangerdb datafile size 10M autoextend on;
   alter user $rangerdbuser DEFAULT Tablespace $rangerdb;

Где *$rangerdb* -- это фактическое имя базы данных Ranger (например, *ranger*), а *$rangerdbuser* -- имя пользователя Ranger (например: *rangeradmin*).

2. Если используется Ranger KMS, выполнить следующие команды:

  ::
  
   create user $rangerdbuser identified by “password”;
   GRANT CREATE SESSION,CREATE PROCEDURE,CREATE TABLE,CREATE VIEW,CREATE SEQUENCE,CREATE PUBLIC SYNONYM,CREATE ANY SYNONYM,CREATE TRIGGER,UNLIMITED Tablespace TO $rangerkmsuser;
   create tablespace $rangerkmsdb datafile size 10M autoextend on;
   alter user $rangerkmsuser DEFAULT Tablespace $rangerkmsdb;

Где *$rangerkmsdb* -- это фактическое имя базы данных Ranger (например: *rangerkms*), а *$rangerkmsuser* -- имя пользователя Ranger (например: *rangerkms*).



Установка Ranger
^^^^^^^^^^^^^^^^

Установка **Ranger** с помощью **Ambari** заключается в три этапа:

+ `Запуск инсталляции`_
+ `Настройка сервисов`_
+ `Завершение установки`_

Смежные темы:

+ `Расширенные настройки пользователей`_
+ `Настройка Ranger для LDAP SSL`_
+ `Настройка пользователей без использования учетных данных DBA`_
+ `Обновление паролей администратора Ranger`_
+ `Включение плагинов Ranger`_



Запуск инсталляции
~~~~~~~~~~~~~~~~~~~

Запуск инсталляции осуществляется по следующему сценарию:

1. Войти в кластер Ambari с помощью назначенных учетных данных пользователя. При этом отображается главная страница панели инструментов Ambari (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Dashboard>`).

.. _security_authorizationHadoop_InstallingRanger_Dashboard:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Dashboard.*
   :align: center

   Главная страница Ambari

2. В левом меню навигации выбрать пункты меню "Actions > Add Service" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Add-Service>`).

.. _security_authorizationHadoop_InstallingRanger_Add-Service:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Add-Service.*
   :align: center

   Действие -- Добавить сервис

3. На открывшейся странице "Choose Services" выбрать *Ranger* и нажать кнопку *Next* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Choose-Service>`).

.. _security_authorizationHadoop_InstallingRanger_Choose-Service:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Choose-Service.*
   :align: center

   Добавление сервиса

4. Открывается страница "Ranger Requirements". Необходимо убедиться, что выполнены все требования к установке, установить флажок *I have met all the requirements above* и нажать кнопку *Proceed* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Requirements>`).

.. _security_authorizationHadoop_InstallingRanger_Requirements:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Requirements.*
   :align: center

   Требования Ranger

5. Далее на открывшейся странице "Assign Masters" необходимо выбрать хост, на котором будет установлен Ranger Admin (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Assign-Masters>`). Этот хост должен иметь доступ администратора базы данных к хосту Ranger DB и User Sync. На приведенном рисунке показано, что службы Ranger Admin и Ranger User Sync будут установлены на основном узле кластера (*c6401.ambari.apache.org*). Следует запомнить хост администратора Ranger для использования на последующих этапах установки. Нажать кнопку *Next* для продолжения.


.. _security_authorizationHadoop_InstallingRanger_Assign-Masters:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Assign-Masters.*
   :align: center

   Выбор хоста для установки Ranger Admin

6. Открывается страница "Customize Services" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`). Настройки сервисов описаны в следующем разделе (`Настройка сервисов`_).



Настройка сервисов
~~~~~~~~~~~~~~~~~~~

Следующим шагом в процессе установки **Ranger** является задание настроек на странице "Customize Services" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`):

+ `Ranger Admin`_
+ `Ranger Audit`_
+ `Ranger User Sync`_
+ `Ranger Tagsync`_
+ `Ranger Authentication`_


Ranger Admin
````````````

Настройка администратора **Ranger** выполняется в следующем порядке:

1. На странице "Customize Services" выбрать вкладку "Ranger Admin" и в раскрывающемся списке "DB Flavor" выбрать тип базы данных, используемый с Ranger (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`).

.. _security_authorizationHadoop_InstallingRanger_DB-Flavor:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_DB-Flavor.*
   :align: center

   Выбор типа базы данных

2. Ввести адрес сервера базы данных в поле "Ranger DB Host" в соответствии с таблицей.

.. csv-table:: Ranger DB Host
   :header: "DB Flavor", "Host", "Пример"
   :widths: 25, 25, 50

   "MySQL", "<HOST[:PORT]>", "c6401.ambari.apache.org или c6401.ambari.apache.org:3306"
   "Oracle", "<HOST:PORT:SID>", "c6401.ambari.apache.org:1521:ORCL"
   "Oracle", "<HOST:PORT/Service>", "c6401.ambari.apache.org:1521/XE"
   "PostgreSQL", "<HOST[:PORT]>", "c6401.ambari.apache.org или c6401.ambari.apache.org:5432"
   "MS SQL", "<HOST[:PORT]>", "c6401.ambari.apache.org или c6401.ambari.apache.org:1433"
   "SQLA", "<HOST[:PORT]>", "c6401.ambari.apache.org или c6401.ambari.apache.org:2638"

3. Поле "Ranger DB name" -- имя базы данных Ranger Policy, то есть *Ranger_db*. 

.. important:: При использовании Oracle указать имя табличного пространства Oracle

4. Поле "Driver class name for a JDBC Ranger database" -- имя класса драйвера для базы данных JDBC Ranger -- создается автоматически на основе выбранного типа в поле "DB Flavor". В приведенной таблице перечислены настройки класса драйвера по умолчанию (в настоящее время Ranger не поддерживает сторонний драйвер JDBC).

.. csv-table:: Driver Class Name
   :header: "DB Flavor", "Driver class name для JDBC Ranger"
   :widths: 50, 50

   "MySQL", "com.mysql.jdbc.Driver"
   "Oracle", "oracle.jdbc.driver.OracleDriver"
   "PostgreSQL", "org.postgresql.Driver"
   "MS SQL", "com.microsoft.sqlserver.jdbc.SQLServerDriver"
   "SQLA", "sap.jdbc4.sqlanywhere.IDriver"
   
5. В поля "Ranger DB username" и "Ranger DB Password" необходимо ввести имя пользователя и пароль для сервера базы данных Ranger. В таблице описаны более детальные настройки. Можно использовать базу данных MySQL, установленную с Ambari, или внешнюю БД: MySQL, Oracle, PostgreSQL, MS SQL или SQL Anywhere.
   
.. csv-table:: Пользователь и пароль Ranger DB
   :header: "", "Ranger DB username", "Ranger DB password"
   :widths: 30, 35, 35

   "Описание", "Имя пользователя для базы данных Policy", "Пароль для пользователя базы данных Ranger Policy" 
   "Значение по умолчанию", "rangeradmin", ""
   "Пример значения", "rangeradmin", "PassWORd"
   "Обязательность заполнения", "Да", "Да"
   

6. Строка подключения JDBC -- в настоящее время установщик Ambari создает строку соединения JDBC, используя формат *jdbc:oracle:thin:@//host:port/db_name*. Необходимо заменить строку подключения:

+ **MySQL** -- синтаксис: *jdbc:mysql://DB_HOST:PORT/db_name*, пример значения:

  ::
  
   jdbc:mysql://c6401.ambari.apache.org:3306/ranger_db
   
+ **Oracle SID** -- синтаксис: *jdbc:oracle:thin:@DB_HOST:PORT:SID*, пример значения:

  ::
  
   jdbc:oracle:thin:@c6401.ambari.apache.org:1521:ORCL

+ **Oracle Service Name** -- синтаксис: *jdbc:oracle:thin:@//DB_HOST[:PORT][/ServiceName]*, пример значения:

  ::
  
   jdbc:oracle:thin:@//c6401.ambari.apache.org:1521/XE

+ **PostgreSQL** -- синтаксис: *jdbc:postgresql://DB_HOST/db_name*, пример значения:

  ::
  
   jdbc:postgresql://c6401.ambari.apache.org:5432/ranger_db

+ **MS SQL** -- синтаксис: *jdbc:sqlserver://DB_HOST;databaseName=db_name*, пример значения:

  ::
  
   jdbc:sqlserver://c6401.ambari.apache.org:1433;databaseName=ranger_db
   
+ **SQLA** -- синтаксис: *jdbc:sqlanywhere:host=DB_HOST;database=db_name*, пример значения:

  ::
  
   jdbc:sqlanywhere:host=c6401.ambari.apache.org:2638;database=ranger_db

7. Поле "Setup Database and Database User":

+ при установке значения *Yes* имя и пароль администратора базы данных необходимо будет предоставить, как описано на шаге 8. Ranger не сохраняет имя и пароль DBA после установки. Таким образом можно очистить эти значения в пользовательском интерфейсе Ambari после завершения настройки Ranger;

+ установка значения *No* означает отказ от предоставления данных учетной записи DBA установщику Ambari Ranger. Процесс установки Ranger продолжится без предоставления этих данных. В таком случае необходимо выполнить настройку пользователя базы данных системы, как описано в разделе `Настройка пользователей без использования учетных данных DBA`_, а затем приступить к установке. При этом пользовательский интерфейс по-прежнему требует ввода имени и пароля для продолжения, тогда можно ввести любые значения (значения не обязательно должны быть фактическим именем и паролем администратора).

8. "Database Administrator (DBA) username" и "Database Administrator (DBA) password" задаются при установке сервера баз данных. Если эти сведения отсутствуют, необходимо обратиться к администратору базы данных, установившему сервер.
   
.. csv-table:: Настройки учетных данных DBA
   :header: "", "DBA username", "DBA password"
   :widths: 20, 40, 40

   "Описание", "Пользователь базы данных Ranger, обладающий правами администратора для создания схем баз данных и пользователей", "Пароль пользователя базы данных Ranger" 
   "Значение по умолчанию", "root", ""
   "Пример значения", "root", "root"
   "Обязательность заполнения", "Да", "Да"
   
Если роль пользователя root Oracle DB -- *SYSDBA*, необходимо указать это в параметре имени администратора базы данных. Например, если имя пользователя DBA -- *orcl_root*, следует указать *orcl_root AS SYSDBA*.

Как упомянуто на предыдущем шаге, если "Setup Database and Database User" установлено в положение *No*, имя и пароль DBA могут все еще требоваться для продолжения установки Ranger.

На следующих рисунках показаны примеры настроек БД для каждого типа базы данных Ranger (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_MySQL>`, :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Oracle-Service-Name>`, :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Oracle-SID>`, :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_PostgreSQL>`, :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_MS-SQL>`, :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_SQL-Anywhere>`).

.. important:: Чтобы проверить настройки БД, следует нажать "Test Connection". Если база данных Ranger не была предварительно установлена, тестовое соединение завершится неудачно даже при правильной конфигурации 


.. _security_authorizationHadoop_InstallingRanger_MySQL:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_MySQL.*
   :align: center

   MySQL


.. _security_authorizationHadoop_InstallingRanger_Oracle-Service-Name:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Oracle-Service-Name.*
   :align: center

   Oracle Service Name


.. _security_authorizationHadoop_InstallingRanger_Oracle-SID:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Oracle-SID.*
   :align: center

   Oracle SID


.. _security_authorizationHadoop_InstallingRanger_PostgreSQL:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_PostgreSQL.*
   :align: center

   PostgreSQL


.. _security_authorizationHadoop_InstallingRanger_MS-SQL:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_MS-SQL.*
   :align: center

   MS SQL


.. _security_authorizationHadoop_InstallingRanger_SQL-Anywhere:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_SQL-Anywhere.*
   :align: center

   SQL Anywhere



Ranger Audit
`````````````

**Apache Ranger** использует **Apache Solr** для хранения журналов аудита и обеспечивает поиск пользовательского интерфейса через них. **Solr** необходимо установить и настроить перед инсталляцией **Ranger Admin** или любого из плагинов компонента **Ranger**. Конфигурация по умолчанию для **Ranger Audits** в **Solr** использует общий экземпляр **Solr**, предоставляемый сервисом **Ambari Infra**. **Solr** -- это и память, и процессор. Если продуктивная система имеет большой объем запросов доступа, необходимо убедиться, что хост **Solr** имеет достаточную память, процессор и дисковое пространство.

`SolrCloud <https://lucene.apache.org/solr/guide/6_6/solrcloud.html>`_ является предпочтительной установкой для использования **Ranger**. **SolrCloud**, разворачиваемый с сервисом **Ambari Infra**, представляет собой масштабируемую архитектуру, которая может работать как единый узел или кластер с несколькими узлами. Он имеет дополнительные функции, такие как репликация и сегментирование, что полезно для высокой доступности (HA) и масштабируемости. 

Следует планировать развертывание на основе размера кластера. Поскольку записи аудита могут значительно увеличиваться, важно иметь не менее *1 ТБ* свободного места, где **Solr** будет хранить данные индекса. Необходимо предоставить процессу **Solr** как можно больше памяти (хорошо работает с *32 ГБ* оперативной памяти). Настоятельно рекомендуется использовать **SolrCloud** по меньшей мере с двумя узлами **Solr**, работающими на разных серверах с включенной `репликацией <https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=62687462>`_. **SolrCloud** также требует **Apache ZooKeeper**.

1. На странице "Customize Services" выбрать вкладку "Ranger Audit" (см. :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`).

Рекомендуется хранить аудиты в Solr и HDFS. Обе эти опции заданы по умолчанию (установлены в положение *ON*). Solr предоставляет возможность индексирования и поиска по самым последним журналам, в то время как HDFS используется как более постоянное и долгосрочное хранилище. По умолчанию Solr используется для индексации журналов аудита за предшествующие 30 дней.

2. В блоке "Audit to Solr" в поле "SolrCloud" установить значение *ON* для активирования SolrCloud (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Audit-to-Solr>`). При этом настройки конфигурации SolrCloud будут загружены автоматически.

.. _security_authorizationHadoop_InstallingRanger_Audit-to-Solr:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Audit-to-Solr.*
   :align: center

   Audit to Solr



Ranger User Sync
`````````````````
В разделе описывается настройка **Ranger User Sync** для **UNIX** и **LDAP/AD**.

+ `Тест-драйв Ranger Usersync`_
+ `Настройка синхронизации пользователей Ranger для UNIX`_
+ `Настройка синхронизации пользователя Ranger для LDAP/AD`_
+ `Автоматическое назначение роли ADMIN/KEYADMIN для внешних пользователей`_

  
Тест-драйв Ranger Usersync
**************************

Перед применением изменений в **usersync** рекомендуется выполнить тестовый запуск, чтобы пользователи и группы извлекались должным образом. Для тестового запуска загрузки данных User и Group в **Ranger** перед фиксацией изменений необходимо:

1. Установить параметр в значение *ranger.usersync.policymanager.mockrun=true*. Он находится в *Ambari> Ranger> Configs> Advanced> Advanced ranger-ugsync-site*

2. Проверить пользователей и группы для загрузки в Ranger: *tail -f /var/log/ranger/usersync/usersync.log*

3. После подтверждения того, что пользователи и группы будут извлечены по назначению, установить *ranger.usersync.policymanager.mockrun=false* и перезапустить Ranger Usersync.

Эти действия приводят к синхронизации пользователей, отображаемых в журнале **usersync**, с базой данных **Ranger**.


Настройка синхронизации пользователей Ranger для UNIX
******************************************************

Для настройки **Ranger User Sync** для **UNIX** необходимо выполнить следующий порядок действий:

1. На странице "Customize Services" выбрать вкладку "Ranger User Info" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Ranger-User-Info>`);

2. В разделе "Enable User Sync" установить значение *Yes*;

3. В раскрывающемся списке "Sync Source" выбрать *UNIX*, а затем установить свойства, описание которых приведено в таблице.

.. csv-table:: Свойства UNIX User Sync
   :header: "Свойство", "Описание", "Значение по умолчанию"
   :widths: 30, 35, 35

   "Sync Source", "Синхронизировать пользователей только выше указанно ID", "500"
   "Password File", "Расположение файла паролей на сервере Linux", "/etc/passwd"
   "Group File", "Расположение файла групп на сервере Linux", "/etc/group"


.. _security_authorizationHadoop_InstallingRanger_Ranger-User-Info:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Ranger-User-Info.*
   :align: center

   Настройка Ranger User Info для UNIX


Настройка синхронизации пользователя Ranger для LDAP/AD
********************************************************

Для обеспечения принудительной авторизации на уровне групп **LDAP/AD** в **Hadoop** необходимо настроить `сопоставление групп Hadoop для LDAP/AD <http://docs.arenadata.io/adh/authorizationHadoop/InstallingRanger.html#hadoop-ldap-ad>`_.

Для настройки **Ranger User Sync** для **LDAP/AD** необходимо выполнить следующий порядок действий:

1. На странице "Customize Services" выбрать вкладку "Ranger User Info" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_User-Info-LDAP>`);

2. В разделе "Enable User Sync" установить значение *Yes*;

3. В раскрывающемся списке "Sync Source" выбрать *LDAP/AD*, а затем установить свойства:

+ **LDAP/AD URL** -- Добавление URL в зависимости от источника синхронизации LDAP/AD.

  + Значение по умолчанию -- *ldap://{host}:{port}*
  + Пример значения -- *ldap://ldap.example.com:389* или *ldaps://ldap.example.com:636*

+ **Bind Anonymous** -- Если выбрано значение *Yes*, Bind User и Bind User Password не требуются.

  + Значение по умолчанию -- *NO*
  
+ **Bind User** -- Расположение файла групп на сервере Linux.

  + Значение по умолчанию -- Полное distinguished name (DN), включая common name (CN), учетной записи пользователя LDAP/AD с правами поиска пользователей. Используется для запроса пользователей и групп.
  + Пример значения -- *cn=admin,dc=example,dc=com* или *admin@example.com*

+ **Bind User Password** -- Пароль Bind User.

+ **Incremental Sync** -- Если выбрано *Yes*, Ranger Usersync сохраняет последнюю временную метку всех объектов, которые были синхронизированы ранее, и использует эту метку времени для выполнения следующей синхронизации. Затем Usersync использует механизм опроса для выполнения инкрементной синхронизации с помощью атрибутов LDAP *uSNChanged* (для AD) или *modifytimestamp* (для LDAP). Включение инкрементной синхронизации в первый раз приводит к полной синхронизации; последующие операции синхронизации будут инкрементальными. Когда включена инкрементная синхронизация, групповая синхронизация (на вкладке "Group Configs") является обязательной. Рекомендуется для крупных развертываний.

  + Значение по умолчанию -- Для обновления: *No*; для инсталляции: *Yes*.
  + Пример значения -- *Yes*


.. _security_authorizationHadoop_InstallingRanger_User-Info-LDAP:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_User-Info-LDAP.*
   :align: center

   Настройка Ranger User Info для LDAP/AD


4. На вкладке "User Configs" установить свойства (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_User-Configs-LDAP>`):

+ **Group User Map Sync** -- Синхронизация определенных групп для пользователей.

  + Значение по умолчанию -- *Yes*
  + Пример значения -- *Yes*

+ **Username Attribute** -- Атрибут имени пользователя LDAP.

  + Пример значения -- *sAMAccountName* для AD, *uid* или *cn* для OpenLDAP

+ **User Object Class** -- Класс объекта для идентификации записей пользователя.

  + Значение по умолчанию -- *person*
  + Пример значения -- *top*, *person*, *organizationalPerson*, *user* или *posixAccount*

+ **User Search Base** -- Поиск базы для пользователей. Ranger может искать несколько подразделений в AD. Модуль Ranger UserSync выполняет поиск пользователей по каждому настроенному подразделению и добавляет всех пользователей в один список. После того как все подразделения будут обработаны, членство в группе пользователя вычисляется на основе поиска группы.

  + Пример значения -- *cn=users,dc=example,dc=com;ou=example1,ou=example2*

+ **User Search Filter** -- Дополнительный фильтр, ограничивающий пользователей, выбранных для синхронизации.

  + Пример значения -- Для извлечения всех пользователей: cn=*. Для извлечения всех пользователей, которые являются членами groupA или groupB: *(|(memberof=CN=GroupA,OU=groups,DC=example, DC=com)(memberof=CN=GroupB,OU=groups,DC=example,DC=com))*

+ **User Search Scope** -- Ограничение поиска по глубине поиска базы.

  + Значение по умолчанию -- *sub*
  + Пример значения -- *base*, *one* или *sub*

+ **User Group Name Attribute** -- Атрибут из записи пользователя, значения которого рассматриваются как значения группы для отправки в базу данных Access Manager. Можно указать несколько имен атрибутов, разделенных запятыми.

  + Значение по умолчанию -- *memberof,ismemberof*
  + Пример значения -- *memberof*, *ismemberof* или *gidNumber*

+ **Enable User Search** -- Параметр доступен, если выбрана опция "Enable Group Search First".

  + Значение по умолчанию -- *No*
  + Пример значения -- *Yes*


.. _security_authorizationHadoop_InstallingRanger_User-Configs-LDAP:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_User-Configs-LDAP.*
   :align: center

   Настройка User Configs для LDAP/AD


5. На вкладке "Group Configs" установить свойства (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Group-Configs-LDAP>`):

+ **Enable Group Sync** -- Если для параметра "Enable Group Sync" установлено *No*, имена групп, к которым принадлежат пользователи, получены из "User Group Name Attribute". В этом случае не применяются дополнительные групповые фильтры. Если для параметра "Enable Group Sync" установлено *Yes*, группы, к которым принадлежат пользователи, извлекаются из LDAP/AD с помощью атрибутов, связанных с группой. Включено по умолчанию, если включена функция "Incremental Sync" на вкладке "Common Configs".

  + Значение по умолчанию -- *No*
  + Пример значения -- *Yes*

+ **Group Member Attribute** -- Имя атрибута члена группы LDAP.

  + Пример значения -- *member*

+ **Group Name Attribute** -- Атрибут имени группы LDAP.

  + Пример значения -- *distinguishedName* для AD, *cn* для OpenLdap

+ **Group Object Class** -- Класс объекта LDAP Group.

  + Пример значения -- *group*, *groupofnames* или *posixGroup*
  
+ **Group Search Base** -- База поиска для групп. Ranger может искать несколько подразделений в AD. Модуль Ranger UserSync выполняет поиск пользователей по каждому настроенному подразделению и добавляет всех пользователей в один список. После того как все подразделения будут обработаны, членство в группе пользователей вычисляется на основе конфигурации поиска группы. Каждый сегмент подразделения должен быть разделен знаком ";" (точка с запятой).

  + Пример значения -- *ou=groups,DC=example,DC=com;ou=group1;ou=group2*

+ **Group Search Filter** -- Дополнительный фильтр, ограничивающий группы, выбранные для синхронизации.

  + Пример значения -- Для извлечения всех групп: cn=*. Для извлечения только групп, cn которых является *Engineering* или *Sales*: *(|(cn=Engineering)(cn=Sales))*

+ **Enable Group Search First** -- Если параметр "Enable Group Search First" не выбран: пользователи извлекаются из атрибута группы *member*. Если параметр "Enable Group Search First" выбран: членство пользователя вычисляется путем выполнения поиска LDAP на основе пользовательской конфигурации.

  + Значение по умолчанию -- *No*
  + Пример значения -- *Yes*
  
+ **Sync Nested Groups** -- Включает членство во вложенных группах в Ranger, чтобы права, настроенные для родительских групп, применялись ко всем членам в подгруппах. Если сама группа является членом другой группы, пользователи, принадлежащие к этой группе, также являются частью родительской группы. Уровни иерархии групп определяют глубину вложенной группы. Если свойство "Sync Nested Groups" не отображается, следует обновить Ambari 2.6.0+.

  + Значение по умолчанию -- *No*
  + Пример значения -- *Yes*, *No*  
  
+ **Group Hierarchy Levels** -- Количество вложенных групп для оценки в поддержку "Sync Nested Groups". Задать целое число *>0*.

  + Значение по умолчанию -- *0*
  + Пример значения -- *2*
  
    
.. _security_authorizationHadoop_InstallingRanger_Group-Configs-LDAP:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Group-Configs-LDAP.*
   :align: center

   Настройка Group Configs для LDAP/AD



Автоматическое назначение роли ADMIN/KEYADMIN для внешних пользователей
************************************************************************

Можно использовать **usersync** для пометки определенных внешних пользователей или пользователей в определенной внешней группе с ролью *ADMIN* или *KEYADMIN* в **Ranger**. Это полезно в тех случаях, когда внутренние пользователи не могут войти в **Ranger**.

1. В "Ambari>Ranger>Configs>Advanced>Custom ranger-ugsync-site" выбрать "Add Property";
2. Добавить следующие свойства:

+ *ranger.usersync.role.assignment.list.delimiter =* **&**
  
  + Значение по умолчанию -- "&"

+ *ranger.usersync.users.groups.assignment.list.delimiter =* **:**
  
  + Значение по умолчанию -- ":"

+ *ranger.usersync.username.groupname.assignment.list.delimiter =* **,**
  
  + Значение по умолчанию -- ","

  + *ranger.usersync.group.based.role.assignment.rules =* 

  ::

   ROLE_SYS_ADMIN:u:userName1,userName2&ROLE_SYS_ADMIN:g:groupName1,groupName2&ROLE_KEY_ADMIN:u:userName&ROLE_KEY_ADMIN:g:groupName&ROLE_USER:u:userName3,userName4&ROLE_USER:g:groupName


3. Нажать *Add*;
4. Перезапустить Ranger.

Пример:

  ::
  
   ranger.usersync.role.assignment.list.delimiter = &
   ranger.usersync.users.groups.assignment.list.delimiter = :
   ranger.usersync.username.groupname.assignment.list.delimiter = ,
   ranger.usersync.group.based.role.assignment.rules : &ROLE_SYS_ADMIN:u:ldapuser_12,ldapuser2


Ranger Tagsync
**************

Для настройки **Ranger Tagsync** следует на странице "Customize Services" на вкладке "Ranger Tagsync" выбрать необходимый **Tag Source** путем проставления флага в соответствующее поле (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Ranger-Tagsync>`): 

+ Atlas Tag Source;
+ AtlasREST Tag Source;
+ File Tag Source.


.. _security_authorizationHadoop_InstallingRanger_Ranger-Tagsync:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Ranger-Tagsync.*
   :align: center

   Ranger Tagsync


Описание свойств **Tag Source** приведено в таблицах. 


.. csv-table:: Atlas Tag Source
   :header: "Свойство", "Описание"
   :widths: 50, 50

   "Atlas Source: Kafka endpoint", "Конечная точка Kafka: *<kafka_server_url>:6667*"
   "Atlas Source: ZooKeeper endpoint", "Конечная точка ZooKeeper: *<zookeeper_server_url>*:2181"
   "Atlas Source: Kafka consumer group", "Пользователь Ranger"
   
.. csv-table:: AtlasREST Tag Source
   :header: "Свойство", "Описание"
   :widths: 50, 50

   "AtlasREST Source: Atlas endpoint", "Конечная точка AtlasREST: *<atlas_host_url>:21000*"
   "AtlasREST Source: Atlas source download interval", "Интервал загрузки AtlasREST (миллисекунды)"
      
.. csv-table:: File Tag Source
   :header: "Свойство", "Описание"
   :widths: 50, 50

   "File Source: File update polling interval", "Интервал опроса обновлений файла (миллисекунды)"
   "File Source: Filename", "Имя файла tag source"
      


Ranger Authentication
``````````````````````

В разделе описывается, как настроить аутентификацию **Ranger** для **UNIX**, **LDAP** и **AD**:

+ `Ranger UNIX Authentication`_
+ `Ranger LDAP Authentication`_
+ `Ranger Active Directory Authentication`_


После завершения настройки параметров аутентификации нажать кнопку *Next* для продолжения установки. Затем обновить конфигурацию **Ranger admin truststore**, добавив следующие параметры в "Ambari> Ranger> Configs> Advanced> Advanced ranger-admin-site":

  ::
  
   ranger.truststore.file=/etc/ranger/admin/truststore
   ranger.truststore.password=password

И перезапустить Ranger.


Ranger UNIX Authentication
***************************

Для настройки аутентификации **Ranger** для **UNIX** необходимо выполнить следующий порядок действий:

1. Перейти на вкладку "Advanced" на странице "Customize Services" (см. :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`);

2. На открывшейся странице в разделе "Ranger Settings" указать адрес хоста Ranger Access Manager/Service Manager в поле "External URL" в формате *http://<your_ranger_host>:6080* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_UNIX-Authentic>`);

3. В поле "Authentication method" отметить *UNIX*. *HTTP* включен по умолчанию -- если отключить *HTTP*, то возможен только *HTTPS*;

4. В блоке "UNIX Authentication Settings" указать свойства: 

+ **Allow remote Login** -- Флаг для включения/отключения удаленного входа.

  + Значение по умолчанию -- *true*
  + Пример значения -- *true*  

+ **ranger.unixauth.service.hostname** -- Адрес хоста, на котором запущена служба проверки подлинности UNIX.

  + Значение по умолчанию -- *{{ugsync_host}}*
  + Пример значения -- *{{ugsync_host}}*  

+ **ranger.unixauth.service.port** -- Номер порта, на котором запущена служба проверки подлинности UNIX.

  + Значение по умолчанию -- *5151*
  + Пример значения -- *5151*  


Свойства со значением {{xyz}} – это макропеременные, которые производятся из других заданных значений, для оптимизации процесса настройки. Переменные доступны для редактирования. Для восстановления исходного значения следует нажать значок *Set Recommended* справа от поля свойства.

.. _security_authorizationHadoop_InstallingRanger_UNIX-Authentic:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_UNIX-Authentic.*
   :align: center

   Настройка Ranger UNIX Authentication


Ranger LDAP Authentication
**************************

Для настройки аутентификации **Ranger** для **LDAP** необходимо выполнить следующий порядок действий:

1. Перейти на вкладку "Advanced" на странице "Customize Services" (см. :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`);

2. На открывшейся странице в разделе "Ranger Settings" указать адрес хоста Ranger Access Manager/Service Manager в поле "External URL" в формате *http://<your_ranger_host>:6080* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_LDAP-Authentic>`);

3. В поле "Authentication method" отметить *LDAP*;

4. В блоке "LDAP Settings" указать свойства: 

+ **ranger.ldap.base.dn** -- Distinguished Name (DN) начальной точки для поиска на сервере каталогов.

  + Значение по умолчанию -- *dc=example,dc=com*
  + Пример значения -- *dc=example,dc=com*  

+ **Bind User** -- Полное Distinguished Name (DN), включая Common Name (CN) учетной записи пользователя LDAP с правами поиска пользователей. Это значение макропеременной, полученное из значения "Bind User" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_bind_dn}}*
  + Пример значения -- *{{ranger_ug_ldap_bind_dn}}*  

+ **Bind User Password** -- Пароль для Bind User. Это значение макропеременной, которое получено из значения пароля "Bind User" из "Ranger User Info > Common Configs".

+ **ranger.ldap.group. roleattribute** -- Атрибут роли группы LDAP.

  + Значение по умолчанию -- *cn*
  + Пример значения -- *cn*  

+ **ranger.ldap.referral** -- Существует три возможных значения: 

  + *follow* -- сервис LDAP сначала обрабатывает все обычные записи, а затем следует по ссылкам; 
  + *throw* -- все нормальные записи возвращаются в перечислении до того, как выбрано *ReferralException*. При этом в случаях настройки свойства на *follow* или *throw* ответ об ошибке "referral" обрабатывается немедленно;
  + *ignore* -- указывает, что сервер должен возвращать записи ссылок как обычные записи, обычный текст. Это может привести к частичным результатам поиска. 
  
  Рекомендуемая настройка *follow*. При поиске в каталоге сервер может возвращать несколько результатов поиска, а также несколько ссылок, которые показывают, где получить дальнейшие результаты. Эти результаты и ссылки могут чередоваться на уровне протокола.

  + Значение по умолчанию -- *ignore*
  + Пример значения -- *follow | ignore | throw*  

+ **LDAP URL** -- URL-адрес сервера LDAP. Это значение макропеременной, полученное из значения "LDAP/AD URL" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_url}}*
  + Пример значения -- *{{ranger_ug_ldap_url}}*  

+ **ranger.ldap.user. dnpattern** -- Шаблон DN пользователя расширяется при входе пользователя в систему. Например, если пользователь *ldapadmin* выполняет вход, сервер LDAP попытается связаться с DN *uid=ldapadmin,ou=users,dc=example,dc=com*, используя пароль, предоставленный пользователем.

  + Значение по умолчанию -- *uid={0},ou=users,dc=xasecure,dc=net*
  + Пример значения -- *cn=ldapadmin,ou=Users,dc=example,dc=com*  

+ **User Search Filter** -- Фильтр поиска, используемый для Bind Authentication. Это значение макропеременной, полученное из значения "User Search Filter" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_user _searchfilter}}*
  + Пример значения -- *{{ranger_ug_ldap_user _searchfilter}}*  


Свойства со значением *{{xyz}}* -- это макропеременные, которые производятся из других заданных значений, для оптимизации процесса настройки. Переменные доступны для редактирования. Для восстановления исходного значения следует нажать значок *Set Recommended* справа от поля свойства.


.. _security_authorizationHadoop_InstallingRanger_LDAP-Authentic:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_LDAP-Authentic.*
   :align: center

   Настройка Ranger LDAP Authentication
   

Ranger Active Directory Authentication
**************************************

Для настройки аутентификации **Ranger** для **Active Directory** необходимо выполнить следующий порядок действий:

1. Перейти на вкладку "Advanced" на странице "Customize Services" (см. :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`);

2. На открывшейся странице в разделе "Ranger Settings" указать адрес хоста Ranger Access Manager/Service Manager в поле "External URL" в формате *http://<your_ranger_host>:6080* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_AD-Authentic>`);

3. В поле "Authentication method" отметить *ACTIVE_DIRECTORY*;

4. В блоке "AD Settings" указать свойства: 

+ **ranger.ldap.ad.base.dn** -- Distinguished Name (DN) начальной точки для поиска на сервере каталогов.

  + Значение по умолчанию -- *dc=example,dc=com*
  + Пример значения -- *dc=example,dc=com*  

+ **ranger.ldap.ad.bind.dn** -- Полное Distinguished Name (DN), включая Common Name (CN) учетной записи пользователя LDAP с правами поиска пользователей. Это значение макропеременной, полученное из значения "Bind User" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_bind_dn}}*
  + Пример значения -- *{{ranger_ug_ldap_bind_dn}}*  

+ **ranger.ldap.ad.bind.password** -- Пароль для bind.dn. Это значение макропеременной, полученное из значения "Bind User Password" из "Ranger User Info > Common Configs".

+ **Domain Name (Only for AD)** -- Доменное имя сервера аутентификации AD

  + Пример значения -- *dc=example,dc=com*  

+ **ranger.ldap.ad.referral** -- Существует три возможных значения: 

  + *follow* -- сервис LDAP сначала обрабатывает все обычные записи, а затем следует по ссылкам; 
  + *throw* -- все нормальные записи возвращаются в перечислении до того, как выбрано *ReferralException*. При этом в случаях настройки свойства на *follow* или *throw* ответ об ошибке "referral" обрабатывается немедленно;
  + *ignore* -- указывает, что сервер должен возвращать записи ссылок как обычные записи, обычный текст. Это может привести к частичным результатам поиска. 

  Рекомендуемая настройка *follow*. При поиске в каталоге сервер может возвращать несколько результатов поиска, а также несколько ссылок, которые показывают, где получить дальнейшие результаты. Эти результаты и ссылки могут чередоваться на уровне протокола.

  + Значение по умолчанию -- *ignore*
  + Пример значения -- *follow | ignore | throw*  

+ **ranger.ldap.ad.url** -- URL-адрес сервера AD. Это значение макропеременной, полученное из значения "LDAP/AD URL" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_url}}*
  + Пример значения -- *{{ranger_ug_ldap_url}}*  

+ **ranger.ldap.ad.user.searchfilter** -- Фильтр поиска, используемый для Bind Authentication. Это значение макропеременной, полученное из значения "User Search Filter" из "Ranger User Info > Common Configs".

  + Значение по умолчанию -- *{{ranger_ug_ldap_user_searchfilter}}*
  + Пример значения -- *{{ranger_ug_ldap_user_searchfilter}}*  


Свойства со значением *{{xyz}}* -- это макропеременные, которые производятся из других заданных значений, для оптимизации процесса настройки. Переменные доступны для редактирования. Для восстановления исходного значения следует нажать значок *Set Recommended* справа от поля свойства.

.. _security_authorizationHadoop_InstallingRanger_AD-Authentic:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_AD-Authentic.*
   :align: center

   Настройка Ranger Active Directory Authentication


5. При сохранении метода проверки подлинности Active Directory может появиться всплывающее окно "Dependent Configurations", рекомендующее установить метод проверки подлинности LDAP. Эта рекомендуемая конфигурация не должна применяться для AD, поэтому необходимо очистить (отменить) параметр *ranger.authentication.method*, а затем нажать кнопку *OK* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Dep-Conf>`).

.. _security_authorizationHadoop_InstallingRanger_Dep-Conf:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Dep-Conf.*
   :align: center

   Dependent Configurations


Завершение установки
~~~~~~~~~~~~~~~~~~~~~

Завершение процесса установки **Ranger** осуществляется в 3 шага:

1. На странице "Review" внимательно проверить заданные параметры конфигурации. Затем для установки Ranger на сервер Ambari нажать кнопку *Deploy* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Review>`).

.. _security_authorizationHadoop_InstallingRanger_Review:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Review.*
   :align: center

   Проверка установленных параметров конфигурации

2. Ranger устанавливается на указанном хосте на сервере Ambari. Индикатор выполнения отображает ход установки (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Progress-bar>`).

.. _security_authorizationHadoop_InstallingRanger_Progress-bar:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Progress-bar.*
   :align: center

   Отображение хода установки

3. По завершении установки на странице "Summary" отображаются детали установки. Может потребоваться перезапуск служб для компонентов кластера.

.. important:: В случае сбоя установки необходимо завершить процесс установки, а затем перенастроить и переустановить Ranger


Расширенные настройки пользователей
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Для получения доступа к расширенным настройкам пользователя необходимо выбрать вкладку "Advanced" на странице "Customize Service". **Usersync** загружает пользователей из **UNIX**, **LDAP** или **AD** и заполняет ими локальные таблицы пользователей **Ranger**.

+ `Настройки UNIX Usersync`_
+ `Необходимые настройки LDAP и AD Usersync`_
+ `Дополнительные настройки LDAP и AD Usersync`_

.. important:: Чтобы гарантировать, что авторизация уровня LDAP/AD применяется в Hadoop, следует сначала настроить Hadoop Group Mapping для LDAP/AD: `Настройка сопоставления групп Hadoop для LDAP/AD`_

.. important:: Перед применением изменений рекомендуется протестировать Usersync, чтобы пользователи и группы извлекались по назначению: `Тест-драйв Ranger Usersync`_

После указания всех настроек на странице "Customize Services" следует нажать кнопку *Next* для продолжения установки.


Настройки UNIX Usersync
```````````````````````

При использовании аутентификации **UNIX** значения по умолчанию для свойств *Advanced ranger-ugsync-site* -- это настройки для проверки подлинности **UNIX** (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Advanced>`).

.. _security_authorizationHadoop_InstallingRanger_Advanced:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Advanced.*
   :align: center

   Свойства Advanced ranger-ugsync-site


Необходимые настройки LDAP и AD Usersync
`````````````````````````````````````````

При использовании аутентификации **LDAP** необходимо обновить следующие свойства *Advanced ranger-ugsync-site*:

.. csv-table:: Настройки LDAP Advanced ranger-ugsync-site
   :header: "Свойство", "Значение LDAP"
   :widths: 50, 50

   "ranger.usersync.ldap.bindkeystore", "Установить значение таким же, как и в свойстве *ranger.usersync.credstore.filename*. Значение по умолчанию: /usr/hdp/current/ranger-usersync/conf/ugsync.jceks"
   "ranger.usersync.ldap.bindalias", "ranger.usersync.ldap.bindalias"
   "ranger.usersync.source.impl.class", "ldap"
   
.. csv-table:: Настройки AD Advanced ranger-ugsync-site
   :header: "Свойство", "Значение AD"
   :widths: 50, 50

   "ranger.usersync.source.impl.class", "ldap"
  
  
Дополнительные настройки LDAP и AD Usersync
````````````````````````````````````````````

При использовании проверки подлинности **LDAP** или **Active Directory** может потребоваться обновление свойств в зависимости от конкретных характеристик развертывания:

+ **ranger.usersync.ldap.url**

  + Значение LDAP: *ldap://127.0.0.1:389*
  + Значение AD: *ldap://ad-conrowoller-hostname:389*


+ **ranger.usersync.ldap.binddn**

  + Значение LDAP: *cn=ldapadmin,ou=users, dc=example,dc=com*
  + Значение AD: *cn=adadmin,cn=Users, dc=example,dc=com*


+ **ranger.usersync.ldap.ldapbindpassword**

  + Значение LDAP: *secret*
  + Значение AD: *secret*


+ **ranger.usersync.ldap.searchBase**

  + Значение LDAP: *dc=example,dc=com*
  + Значение AD: *dc=example,dc=com*


+ **ranger.usersync.source.impl.class**

  + Значение LDAP: *org.apache.ranger. ladpusersync. process.LdapUserGroupBuilder*
  

+ **ranger.usersync.ldap.user.searchbase**

  + Значение LDAP: *ou=users, dc=example, dc=com*
  + Значение AD: *dc=example,dc=com*


+ **ranger.usersync.ldap.user.searchscope**

  + Значение LDAP: *sub*
  + Значение AD: *sub*


+ **ranger.usersync.ldap.user.objectclass**

  + Значение LDAP: *person*
  + Значение AD: *person*


+ **ranger.usersync.ldap.user.searchfilter**

  + Значение LDAP: *Set to single empty space if no value. Do not leave it as “empty”*
  + Значение AD: *(objectcategory=person)*


+ **ranger.usersync.ldap.user.nameattribute**

  + Значение LDAP: *uid or cn*
  + Значение AD: *sAMAccountName*


+ **ranger.usersync.ldap.user.groupnameattribute**

  + Значение LDAP: *memberof,ismemberof*
  + Значение AD: *memberof,ismemberof*


+ **ranger.usersync.ldap.username.caseconversion**

  + Значение LDAP: *none*
  + Значение AD: *none*


+ **ranger.usersync.ldap.groupname.caseconversion**

  + Значение LDAP: *none*
  + Значение AD: *none*

Следующие свойства применяются при фильтровке групп:

+ **ranger.usersync.group.searchenabled**

  + Значение LDAP: *false*
  + Значение AD: *false*


+ **ranger.usersync.group.usermapsyncenabled**

  + Значение LDAP: *false*
  + Значение AD: *false*


+ **ranger.usersync.group.searchbase**

  + Значение LDAP: *ou=groups, dc=example, dc=com*
  + Значение AD: *dc=example,dc=com*


+ **ranger.usersync.group.searchscope**

  + Значение LDAP: *sub*
  + Значение AD: *sub*


+ **ranger.usersync.group.objectclass**

  + Значение LDAP: *groupofnames*
  + Значение AD: *groupofnames*


+ **ranger.usersync.group.searchfilter**

  + Значение LDAP: *needed for AD authentication*
  + Значение AD: *(member=CN={0}, OU=MyUsers, DC=AD-HDP, DC=COM)*


+ **ranger.usersync.group.nameattribute**

  + Значение LDAP: *cn*
  + Значение AD: *cn*


+ **ranger.usersync.group.memberattributename**

  + Значение LDAP: *member*
  + Значение AD: *member*


+ **ranger.usersync.pagedresultsenabled**

  + Значение LDAP: *true*
  + Значение AD: *true*


+ **ranger.usersync.pagedresultssize**

  + Значение LDAP: *500*
  + Значение AD: *500*


+ **ranger.usersync.user.searchenabled**

  + Значение LDAP: *false*
  + Значение AD: *false*


+ **ranger.usersync.group.search.first.enabled**

  + Значение LDAP: *false*
  + Значение AD: *false*



Настройка Ranger для LDAP SSL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Можно использовать следующие настройки **LDAP SSL** с помощью самоподписанных сертификатов в стандартном **Ranger User Sync TrustStore**:

1. Для свойства *ranger.usersync.truststore.file* расположение по умолчанию */usr/hdp/current/ranger-usersync/conf/mytruststore.jks*;
2. Скопировать и отредактировать самоподписанные сертификаты;
3. Установить свойство *ranger.usersync.truststore.file* в новый файл:

  ::
  
   cd /usr/hdp/<version>/ranger-usersync 
   service ranger-usersync stop 
   service ranger-usersync start

  Сертификат LDAPS содержится в *cert.pem*.



Настройка пользователей без использования учетных данных DBA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

С целью не предоставления деталей учетной записи администратора базы данных (DBA) установщику **Ambari Ranger** можно использовать скрипт **Python** *dba_script.py* для создания пользователей базы данных **Ranger DB** без передачи информации об учетной записи DBA. После этого можно запустить обычную установку **Ambari Ranger** без указания имени и пароля администратора.

Создание пользователей **Ranger DB** при помощи скрипта *dba_script.py*:

1. Загрузить Ranger rpm с помощью команды *yum install*:

  ::
  
   yum install ranger-admin
   
2. В каталоге */usr/hdp/current/ranger-admin* должен быть файл с именем *dba_script.py*; 

3. Получить внутренний скрипт и убедиться, что DBA имеет право запускать его;

4. Выполнить скрипт командой:

  ::
  
   python dba_script.py
   
5. Указать все необходимые значения в аргументе (включает *db flavor*, *JDBC jar*, *db host*, *db name*, *db user* и другие параметры):
 
+ Если во время выполнения не предпочитается передача аргументов в командной строке, можно обновить файл */usr/hdp/current/ranger-admin/install.properties*, а затем выполнить команду:
  
  ::
  
   python dba_script.py -q
  
При указании опции *-q* скрипт считывает всю необходимую информацию из файла *install.properties*;
  
+ Опция *-d* используется для запуска скрипта в режиме "dry". Это приводит к созданию сценария базы данных:
  
  ::
  
   python dba_script.py -d /tmp/generated-script.sql
   
Сценарий может выполнить любой пользователь, но рекомендуется, чтобы его запустил в режиме "dry" системный администратор баз данных. В любом случае системный DBA должен просматривать сгенерированный скрипт, но при этом вносить лишь незначительные корректировки, например, изменение расположения конкретного файла базы данных. Не следует вносить существенных изменений, которые могут сильно изменить скрипт -- в противном случае установка Ranger может завершиться ошибкой.

Затем системному администратору баз данных необходимо запустить созданный скрипт.

6. Запустить процедуру установки Ranger Ambari, предварительно установив на странице "Customize Services" в разделе "Ranger Admin" для параметра *Setup Database and Database User* значение *No*.



Обновление паролей администратора Ranger
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

При обновлении паролей на странице "Ranger Configs" для нижеприведенных пользователей необходимо также обновить пароли каждого компонента **Ambari**, для которого включен плагин **Ranger**. 

.. important:: Индивидуальные конфигурации компонентов Ambari не обновляются автоматически -- перезапуск сервиса завершается ошибкой, если пароли для каждого компонента не обновлены

+ Ranger Admin user -- учетные данные пользователя устанавливаются в "Configs > Advanced ranger-env" в полях "admin_username" (значение по умолчанию: *admin*) и "admin_password" (значение по умолчанию: *admin*);

+ Admin user, используемый Ambari для создания репозитория/политик -- имя пользователя задается в "Configs > Admin Settings" в поле "Ranger Admin username for Ambari" (значение по умолчанию: *amb_ranger_admin*). Пароль устанавливается в поле "Ranger Admin user's password for Ambari" (задается во время установки Ranger).

На рисунке показано расположение полей с перечисленными параметрами на странице настроек "Ranger Configs" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Configs-page>`).

.. _security_authorizationHadoop_InstallingRanger_Configs-page:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Configs-page.*
   :align: center

   Обновление паролей администратора Ranger


Включение плагинов Ranger
~~~~~~~~~~~~~~~~~~~~~~~~~

Плагины **Ranger** могут быть включены для нескольких сервисов **ADH**. По соображениям производительности рекомендуется хранить аудиты в **Solr** и **HDFS**, а не в базе данных.

При использовании кластера с поддержкой **Kerberos** необходимо выполнить ряд дополнительных шагов, чтобы убедиться в возможности использования подключаемых плагинов **Ranger** в кластере **Kerberos** (`HDFS в кластере с поддержкой Kerberos`_).

Доступны следующие плагины **Ranger**: `HDFS`_, **Hive**, **HBase**, **Kafka**, **Knox**, **YARN**, **Storm**, **Atlas**. 


HDFS
`````

Для включения плагина **Ranger HDFS** необходимо выполнить следующие действия:

1. На странице "Ranger Configs" выбрать вкладку "Ranger Plugin" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Ranger-Plugin>`).

.. _security_authorizationHadoop_InstallingRanger_Ranger-Plugin:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Ranger-Plugin.*
   :align: center

   Ranger Plugin

2. В поле "HDFS Ranger Plugin" активировать кнопку *On* и сохранить действие.

3. При этом появляется всплывающее окно "Save Configuration". Необходимо ввести примечание с описанием только что внесенных изменений и сохранить кнопкой *Save* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Save-Config>`).

.. _security_authorizationHadoop_InstallingRanger_Save-Config:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Save-Config.*
   :align: center

   Save Configuration

4. При этом появляется всплывающее окно "Dependent Configuration". Для подтверждения обновлений конфигурации необходимо нажать кнопку *OK* (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Dependent-Config>`).

.. _security_authorizationHadoop_InstallingRanger_Dependent-Config:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Dependent-Config.*
   :align: center

   Dependent Configuration

5. Нажать кнопку *OK* во всплывающем окне сохранения настроек "Save Configuration Changes" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Save-Config-Changes>`).

.. _security_authorizationHadoop_InstallingRanger_Save-Config-Changes:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Save-Config-Changes.*
   :align: center

   Save Configuration Changes

6. Перейти в меню навигации на пункт "HDFS", затем выбрать "Restart > Restart All Affected" для перезапуска сервиса HDFS и загрузки новой конфигурации (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Restart>`).

.. _security_authorizationHadoop_InstallingRanger_Restart:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Restart.*
   :align: center

   Restart All Affected

7. Нажать *Confirm Restart All* во всплывающем окне "Confirmation" для подтверждения перезапуска HDFS (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Confirm>`).

.. _security_authorizationHadoop_InstallingRanger_Confirm:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Confirm.*
   :align: center

   Confirm Restart All

8. После перезапуска HDFS плагин Ranger для HDFS будет включен. Другие компоненты могут также потребовать перезагрузки.


HDFS в кластере с поддержкой Kerberos
`````````````````````````````````````

Для включения плагина **Ranger HDFS** в кластере с поддержкой **Kerberos** необходимо выполнить следующие действия:

1. Создать пользователя системы *rangerhdfslookup*. Убедиться, что пользователь синхронизирован с *Ranger Admin* (на вкладке "Settings > Users/Groups" в интерфейсе "Ranger Admin User Interface");

2. Создать принципала Kerberos для *rangerhdfslookup*, введя следующую команду (один пользователь/принципал, например, *rangerrepouser*, может быть создан и использован в разных сервисах):

  ::
  
   kadmin.local -q 'addprinc -pw rangerhdfslookup rangerhdfslookup@example.com
   
3. Перейти в разделе сервиса "HDFS" на вкладку "Config";

4. В блоке "Advanced ranger-hdfs-plugin-properties" обновить свойства, перечисленные в таблице под рисунком (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_HDFS-Config>`).

.. _security_authorizationHadoop_InstallingRanger_HDFS-Config:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_HDFS-Config.*
   :align: center

   Advanced ranger-hdfs-plugin-properties


.. csv-table:: Свойства HDFS Plugin
   :header: "Свойство конфигурации", "Значение"
   :widths: 50, 50

   "Ranger repository config user", "rangerhdfslookup@example.com"
   "Ranger repository config password", "rangerhdfslookup"
   "common.name.for.certificate", "blank"

5. После обновления свойств нажать кнопку *Save* и перезапустить сервис HDFS.





