Настройка авторизации в Hadoop
------------------------------

+ `Установка Ranger с помощью Ambari`_
+ `Создание политики HDFS`_


Установка Ranger с помощью Ambari
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
:::::::::::::::::::::::::::::::::::::::::::::::::

Для обеспечения принудительной авторизации на уровне групп **LDAP/AD** в **Hadoop**, необходимо настроить сопоставление групп **Hadoop** для **LDAP/AD**.4

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
******************

При использовании **MySQL** машина для хранения таблиц политики администратора **Ranger** обязательно должна поддерживать транзакции. **InnoDB** -- это пример машины, поддерживающей транзакции. 

При использовании **Amazon RDS** есть дополнительные требования (`Требования к Amazon RDS`_).

Для конфигурации экземпляра для **Ranger** для **MySQL** необходимо следовать следующим шагам:

1. 


Конфигурация PostgreSQL
"""""""""""""""""""""""


Конфигурация Oracle
""""""""""""""""""""


Требования к Amazon RDS
"""""""""""""""""""""""


Настройка пользователей базы данных без совместного использования учетных данных DBA
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""





Создание политики HDFS
^^^^^^^^^^^^^^^^^^^^^^


