Установка Ranger с помощью Ambari
---------------------------------

**Apache Ranger** можно установить при помощи пользовательского интерфейса **Ambari** или вручную, используя платформу **Arenadata Hadoop**. В отличие от ручного процесса установки, требующего выполнения ряда шагов, установка **Ranger** с использованием интерфейса **Ambari** проще и легче. Опция службы **Ranger** доступна через мастер **Add Service** после инсталляции кластера **ADH** с помощью установщика.

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

+ Рекомендуется хранить аудиты как в HDFS, так и в Solr. Конфигурация по умолчанию для Ranger Audits в Solr использует общий экземпляр Solr, предоставляемый сервисом Ambari Infra (дополнительные сведения см. в разделе `Ranger Audit Settings <https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_security/content/ranger_audit_settings.html>`_);

+ Чтобы обеспечить принудительную авторизацию на уровне групп LDAP/AD в Hadoop, необходимо настроить сопоставление групп Hadoop для LDAP/AD для LDAP (`Настройка сопоставления групп Hadoop для LDAP/AD`_);

+ Должен быть запущен и доступен экземпляр базы данных MySQL, Oracle, PostgreSQL или Amazon RDS, который будет использоваться Ranger. Установщик Ranger создаст двух новых пользователей (имена по умолчанию: *rangeradmin* и *rangerlogger*) и две новые базы данных (имена по умолчанию: *ranger* и *ranger_audit*).

  Конфигурация экземпляра для Ranger для некоторых баз данных описана в следующих разделах:

  + `Конфигурация MySQL`_
  + `Конфигурация PostgreSQL`_
  + `Конфигурация Oracle`_
  
  При использовании Amazon RDS есть дополнительные требования (`Требования к Amazon RDS`_).

+ При решении не предоставлять данные учетной записи администратора базы данных (DBA) установщику Ambari Ranger, можно использовать Python-скрипт *dba_script.py* для создания пользователей базы данных Ranger DB без предоставления этой информации установщику. После чего запустить обычную установку Ambari Ranger без указания имени и пароля администратора. Дополнительные сведения приведены в разделе `Настройка пользователей базы данных без совместного использования учетных данных DBA`_.


Настройка сопоставления групп Hadoop для LDAP/AD
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Для обеспечения принудительной авторизации на уровне групп **LDAP/AD** в **Hadoop**, необходимо настроить сопоставление групп **Hadoop** для **LDAP/AD**.

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

2. Следующая команда используется для подтверждения, что файл *mysql-connector-java.jar* находится в папке общего доступа Java. Команда должна быть запущена на сервере, на котором установлен сервер Ambari:

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

Где *$postgres* -- пользователь Postgres, *$dbname* -- имя базы данных PostgreSQL.

5. Использовать следующий формат команды, чтобы установить путь *jdbc/driver/path* на основе местоположения файла *.jar* драйвера PostgreSQL JDBC. Команда должна выполняться на сервере, на котором установлен сервер Ambari:

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
  + внести следующие изменения пользователям *Ranger db* и *Ranger audit db* в файле *pg_hba.conf* (:numref:`Рис.%s.<security_authorization_Ranger-user>`).

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

3. Использовать следующий формат команды, чтобы установить путь *jdbc/driver/path* на основе местоположения файла *.jar* драйвера Oracle JDBC. Команда должна выполняться на сервере, на котором установлен сервер Ambari:

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

  + Установить переменную MySQL Server *log_bin_trust_function_creators* в значение *1*.
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

Из-за ограничений в `Amazon RDS <https://forums.aws.amazon.com/thread.jspa?messageID=450535>`_ создание пользователя базы данных **Ranger** и табличного пространства, а так же предоставление пользователю **Ranger** необходимых привилегий выполняется вручную.

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

+ `Настройка пользователей базы данных без совместного использования учетных данных DBA`_
+ `Обновление паролей администратора Ranger`_



Запуск инсталляции
~~~~~~~~~~~~~~~~~~~

Запуск инсталляции осуществляется по следующему сценарию:

1. Войти в кластер Ambari с помощью назначенных учетных данных пользователя. При этом отображается главная страница панели инструментов Ambari (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Dashboard>`).

.. _security_authorizationHadoop_InstallingRanger_Dashboard:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Dashboard.*
   :align: center

   Главная страница Ambari

2. В левом меню навигации нажать "Actions", затем выбрать "Add Service" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Add-Service>`).

.. _security_authorizationHadoop_InstallingRanger_Add-Service:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Add-Service.*
   :align: center

   Действие -- Добавить сервис

3. На открывшейся странице "Choose Services" выбрать Ranger и нажать "Next" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Choose-Service>`).

.. _security_authorizationHadoop_InstallingRanger_Choose-Service:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Choose-Service.*
   :align: center

   Добавление сервиса

4. Открывается страница "Ranger Requirements". Необходимо убедиться, что выполнены все требования к установке, установить флажок "I have met all the requirements above" и нажать "Proceed" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Requirements>`).

.. _security_authorizationHadoop_InstallingRanger_Requirements:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Requirements.*
   :align: center

   Требования Ranger

5. Далее на открывшейся странице "Assign Masters" необходимо выбрать хост, на котором будет установлен Ranger Admin (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Assign-Masters>`). Этот хост должен иметь доступ администратора базы данных к хосту Ranger DB и User Sync. На приведенном рисунке показано, что службы Ranger Admin и Ranger User Sync будут установлены на основном узле кластера (*c6401.ambari.apache.org*). Следует запомнить хост администратора Ranger для использования на последующих этапах установки. Нажать "Next" для продолжения.


.. _security_authorizationHadoop_InstallingRanger_Assign-Masters:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Assign-Masters.*
   :align: center

   Выбор хоста для установки Ranger Admin

6. Открывается страница "Customize Services". Настройки сервисов описаны в следующем разделе (`Настройка сервисов`_).



Настройка сервисов
~~~~~~~~~~~~~~~~~~~

Следующим шагом в процессе установки **Ranger** является задание настроек на странице "Customize Services":

+ `Ranger Admin`_
+ `Ranger Audit`_
+ `Ranger User Sync`_
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

+ при установке значения "Yes" имя и пароль администратора базы данных необходимо будет предоставить, как описано на шаге 8. Ranger не сохраняет имя и пароль DBA после установки. Таким образом можно очистить эти значения в пользовательском интерфейсе Ambari после завершения настройки Ranger;

+ установка значения "No" означает отказ от предоставления данных учетной записи DBA установщику Ambari Ranger. Процесс установки Ranger продолжится без предоставления этих данных. В таком случае необходимо выполнить настройку пользователя базы данных системы, как описано в разделе `Настройка пользователей базы данных без совместного использования учетных данных DBA`_, а затем приступить к установке. При этом пользовательский интерфейс по-прежнему требует ввода имени и пароля для продолжения, тогда можно ввести любое значение (значения не обязательно должны быть фактическим именем и паролем администратора).

8. "Database Administrator (DBA) username" и "Database Administrator (DBA) password" задаются при установке сервера баз данных. Если эти сведения отсутствуют, необходимо обратиться к администратору базы данных, установившему сервер.
   
.. csv-table:: Настройки учетных данных DBA
   :header: "", "DBA username", "DBA password"
   :widths: 20, 40, 40

   "Описание", "Пользователь базы данных Ranger, обладающий правами администратора для создания схем баз данных и пользователей", "Пароль пользователя базы данных Ranger" 
   "Значение по умолчанию", "root", ""
   "Пример значения", "root", "root"
   "Обязательность заполнения", "Да", "Да"
   
Если роль пользователя root Oracle DB -- *SYSDBA*, необходимо указать это в параметре имени администратора базы данных. Например, если имя пользователя DBA -- *orcl_root*, следует указать *orcl_root AS SYSDBA*.

Как упомянуто на предыдущем шаге, если "Setup Database and Database User" установлено в положение "No", имя и пароль DBA могут все еще требоваться для продолжения установки Ranger.

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

**Apache Ranger** использует **Apache Solr** для хранения журналов аудита и обеспечивает поиск пользовательского интерфейса через них. **Solr** необходимо установить и настроить перед инсталляцией **Ranger Admin** или любого из плагинов компонента **Ranger**. Конфигурация по умолчанию для **Ranger Audits** в **Solr** использует общий экземпляр **Solr**, предоставляемый сервисом **Ambari Infra**. **Solr** -- это и память, и процессор. Если производственная система имеет большой объем запросов доступа, необходимо убедиться, что хост **Solr** имеет достаточную память, процессор и дисковое пространство.

`SolrCloud <https://lucene.apache.org/solr/guide/6_6/solrcloud.html>`_ является предпочтительной установкой для использования **Ranger**. **SolrCloud**, разворачиваемый с сервисом **Ambari Infra**, представляет собой масштабируемую архитектуру, которая может работать как единый узел или кластер с несколькими узлами. Он имеет дополнительные функции, такие как репликация и сегментирование, что полезно для высокой доступности (HA) и масштабируемости. 

Следует планировать развертывание на основе размера кластера. Поскольку записи аудита могут значительно увеличиваться, важно иметь не менее *1 ТБ* свободного места, где **Solr** будет хранить данные индекса. Необходимо предоставить процессу **Solr** как можно больше памяти (хорошо работает с *32 ГБ* оперативной памяти). Настоятельно рекомендуется использовать **SolrCloud** по меньшей мере с вумя узлами **Solr**, работающими на разных серверах с включенной `репликацией <https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=62687462>`_. **SolrCloud** также требует **Apache ZooKeeper**.

1. На странице "Customize Services" выбрать вкладку "Ranger Audit" (см. :numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_DB-Flavor>`).

Рекомендуется хранить аудиты в Solr и HDFS. Обе эти опции заданы по умолчанию (установлены на положение *ON*). Solr предоставляет возможность индексирования и поиска по самым последним журналам, в то время как HDFS используется как более постоянное и долгосрочное хранилище. По умолчанию Solr используется для индексации журналов аудита за предшествующие 30 дней.

2. В блоке "Audit to Solr" в поле "SolrCloud" установить значение *ON* для активирования SolrCloud (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Audit-to-Solr>`). При этом настройки конфигурации SolrCloud будут загружены автоматически.

.. _security_authorizationHadoop_InstallingRanger_Audit-to-Solr:

.. figure:: ../imgs/security_authorizationHadoop_InstallingRanger_Audit-to-Solr.*
   :align: center

   Audit to Solr



Ranger User Sync
`````````````````
В разделе описывается настройка **Ranger User Sync** для **UNIX** и **LDAP/AD**.

+ Тест-драйв Ranger Usersync;
+ Настройка синхронизации пользователей Ranger для UNIX;
+ Настройка синхронизации пользователя Ranger для LDAP/AD;
+ Автоматическое назначение роли ADMIN/KEYADMIN для внешних пользователей.

+ **Тест-драйв Ranger Usersync**

Перед применением изменений в **usersync** рекомендуется выполнить тестовый запуск, чтобы пользователи и группы извлекались должным образом. Для тестового запуска загрузки данных User и Group в **Ranger** перед фиксацией изменений необходимо:

1. Установить параметр в значение *ranger.usersync.policymanager.mockrun=true*. Он находится в *Ambari> Ranger> Configs> Advanced> Advanced ranger-ugsync-site*

2. Проверить пользователей и группы для загрузки в Ranger: *tail -f /var/log/ranger/usersync/usersync.log*

3. После подтверждения того, что пользователи и группы будут извлечены по назначению, установить *ranger.usersync.policymanager.mockrun=false* и перезапустить Ranger Usersync.

Эти действия приводят к синхронизации пользователей, отображаемых в журнале **usersync**, с базой данных **Ranger**.


+ **Настройка синхронизации пользователей Ranger для UNIX**

Для настройки **Ranger User Sync** для **UNIX** необходимо выполнить следующий порядок действий:

1. На странице "Customize Services" выбрать вкладку "Ranger User Info" (:numref:`Рис.%s.<security_authorizationHadoop_InstallingRanger_Ranger-User-Info>`);

2. В разделе "Enable User Sync" установить значение *Yes*;

3. В раскрывающемся списке "Sync Source" выбрать *UNIX*, а затем установить свойства, указанные в таблице.

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


+ **Настройка синхронизации пользователя Ranger для LDAP/AD**


+ **Автоматическое назначение роли ADMIN/KEYADMIN для внешних пользователей**






Ranger Authentication
``````````````````````



`Ссылка <https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_security/content/customize_ranger_services.html>`_

Завершение установки
~~~~~~~~~~~~~~~~~~~~~





Настройка пользователей базы данных без совместного использования учетных данных DBA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



Обновление паролей администратора Ranger
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



