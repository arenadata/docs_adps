Предварительные требования к установке
======================================

.. important:: Для установки сервисов необходимы вылеоенный сервер или виртуальная машина, доступная в интерфейсе ADCM

Перед установкой **Ranger** необходимо убедиться, что кластер отвечает следующим требованиям:

+ Установлен и настроен кластер Arenadata Hadoop версии не ниже 2.1.3

+ Рекомендуется хранить аудиты как в HDFS, так и в Solr. Конфигурация по умолчанию для Ranger Audits в Solr использует общий экземпляр Solr;

+ Чтобы обеспечить принудительную авторизацию на уровне групп LDAP/AD в Hadoop, необходимо настроить сопоставление групп Hadoop для LDAP/AD для LDAP (`Настройка сопоставления групп Hadoop для LDAP/AD`_);

+ При использовании внешней СУБД для хранения метаданных, должен быть запущен и доступен экземпляр базы данных MySQL, который будет использоваться Ranger. Установщик Ranger создаст двух новых пользователей (имена по умолчанию: *rangeradmin* и *rangerlogger*) и две новые базы данных (имена по умолчанию: *ranger* и *ranger_audit*).


Настройка сопоставления групп Hadoop для LDAP/AD
`````````````````````````````````````````````````

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
