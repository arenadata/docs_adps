Настройка авторизации в Hadoop
==================================

+ `Ranger. Введение`_
+ `Предварительные требования к установке`_
+ `Установка Ranger`_
+ `HDFS Policy`_



Ranger. Введение
-----------------------------------

**Apache Ranger** можно установить при помощи пользовательского интерфейса **ADCM**. В отличие от ручного процесса установки, требующего выполнения ряда шагов, установка **Ranger** с использованием интерфейса **ADCM** проще и легче. Опция службы **Ranger** доступна через мастер **Add Service** после инсталляции кластера **ADH** с помощью установщика.

Cлужба Ranger включает в себя следующие компоненты:

+ Ranger Admin
+ Ranger UserSync
+ Ranger Key Management Service

После установки и запуска этих компонентов можно включить плагины **Ranger**, перейдя к каждому отдельному сервису (**HDFS**, **HBase**, **Hiveserver2**, **Storm**, **Knox**, **YARN** и **Kafka**) и изменив конфигурацию в расширенном режиме *ranger-<service>-plugin-properties*.

.. important:: При включении плагина Ranger необходимо перезапустить компонент

.. important:: Включение Apache Kafka требует включения Kerberos


Предварительные требования к установке
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Перед установкой **Ranger** необходимо убедиться, что кластер отвечает следующим требованиям:

+ Установлен и настроен кластер Arenadata Hadoop версии не ниже 2.1.3

+ Рекомендуется хранить аудиты как в HDFS, так и в Solr. Конфигурация по умолчанию для Ranger Audits в Solr использует общий экземпляр Solr;

+ Чтобы обеспечить принудительную авторизацию на уровне групп LDAP/AD в Hadoop, необходимо настроить сопоставление групп Hadoop для LDAP/AD для LDAP (`Настройка сопоставления групп Hadoop для LDAP/AD`_);

+ Должен быть запущен и доступен экземпляр базы данных MySQL, который будет использоваться Ranger. Установщик Ranger создаст двух новых пользователей (имена по умолчанию: *rangeradmin* и *rangerlogger*) и две новые базы данных (имена по умолчанию: *ranger* и *ranger_audit*).


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


Установка Ranger
-----------------


Установка **Ranger** с помощью **ADCM** заключается в три этапа:

+ `Загрузка бандла Arenadata Platform Security`_
+ `Создание кластера`_
+ `Конфигурирование сервисов`_
+ `Запуск установки`_

Смежные темы:

+ `Расширенные настройки пользователей`_
+ `Настройка пользователей без использования учетных данных DBA`_
+ `Обновление паролей администратора Ranger`_
+ `Включение плагинов Ranger`_


Загрузка бандла Arenadata Platform Security
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Для начала работы с компонентами Apache Ranger, необходимо загрузить бындл в текущий инстанс ADCM, с помощью действия "Upload Bundle"

.. _security_upload_bundle:

.. figure:: ../imgs/security_upload_bundle.*
   :align: center

Далее необходимо принять соглашение об использовании (EULA)

.. _security_accept_eula:

.. figure:: ../imgs/security_accept_eula.*
   :align: center


Создание кластера
^^^^^^^^^^^^^^^^^^^

Следующим шагом является создание кластера Arenadata Platform Security с помощью действия "Create cluster" в разделе "Clusters"

.. _security_create_cluster:

.. figure:: ../imgs/security_create_cluster.*
   :align: center

После чего, выберите имя кластера и завершите конфигурацию с помощью кнопки "Create".

.. _security_create_cluster_name:

.. figure:: ../imgs/security_create_cluster_name.*
   :align: center

Следующим шагом является ыбор требуемых сервисов и распределение топологии компонентов. Для этого перейдите в конфигурацию кластера и выберите раздел "Services" и нажмите "Add services"

.. _security_add_service:

.. figure:: ../imgs/security_add_service.*
   :align: center

Выберите необходимые компоненты в интерфейсе ADCM

.. _security_select_service:

.. figure:: ../imgs/security_select_service.*
   :align: center

Далее перейдите в раздел "Host-Components" и распределите компоненты по хостам

.. _security_topology:

.. figure:: ../imgs/security_topology.*
   :align: center

.. important:: Все необходимые хосты должны быть созданы перед установкой компонентов

.. important:: Решение позволяет произвести установку всех компонентов в рамках одного хоста, но для промышленных инсталляций рекомендуется разнести компоненты между различными хостами для обеспечения большей отказоустойчивости


Конфигурирование сервисов
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Следующим шагом в процессе установки **Ranger** является задание настроек на странице сервиса Ranger "Configuration":

+ `Credentials`_
+ `dbks-site.xml`_
+ `ranger-admin-site.xml`_
+ `ranger-ugsync-site.xml`_

Credentials
```````````
В данном разделе необходимо указать учетные данные создаваемых технологических пользователей для доступа к интерфейсу и компонентам сервиса Ranger

.. _security_credentials_config:

.. figure:: ../imgs/security_credentials_config.*
   :align: center


dbks-site.xml
`````````````
В данном разделе необходимо указать пароль доступа для ключей шифрования и пароль подключения к БД

.. _security_dbks_config:

.. figure:: ../imgs/security_dbks_config.*
   :align: center


ranger-admin-site.xml
`````````````````````
В данном разделе необходимо указать пароль доступа для подключения к БД и инстансу Solr для обеспечения аудита действий пользователей

.. _security_configure_ranger_2:

.. figure:: ../imgs/security_configure_ranger_2.*
   :align: center



ranger-ugsync-site.xml
``````````````````````
В разделе описывается настройка **Ranger User Sync** для **UNIX** и **LDAP/AD**.

+ `Настройка синхронизации пользователей Ranger для UNIX`_
+ `Настройка синхронизации пользователя Ranger для LDAP/AD`_
+ `Автоматическое назначение роли ADMIN/KEYADMIN для внешних пользователей`_



Завершение установки
^^^^^^^^^^^^^^^^^^^^^^^

.. important:: Перед запуском установки убедитесь что в интерфейсе более нет предупреждений в части конфигурации сервисов.

Для завершение процесса установки **Ranger** перйдите в раздел Main кластера и выберите действие "Install" в разделе "Run action"

После заершения установки, все компоненты должны иметь "зеленый" статус

.. _security_running:

.. figure:: ../imgs/security_running.*
   :align: center


Включение плагинов Ranger
^^^^^^^^^^^^^^^^^^^^^^^^^^^

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



HDFS Policy
------------

Ranger для авторизации в Hadoop
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

После проверки подлинности пользователя необходимо определить его права доступа. Права доступа пользователя к ресурсам определяет авторизация. Например, пользователю может быть разрешено создание политики и просмотр отчетов, но не разрешено редактирование пользователей и групп. **Ranger** можно использовать для настройки и управления доступом к сервисам **Hadoop**.

**Ranger** позволяет создавать сервисы для определенных ресурсов **Hadoop** (**HDFS**, **HBase**, **Hive** и др.) и добавлять права доступа к этим сервисам. Можно также создавать сервисы на основе тегов и добавлять политики доступа к ним. Использование политик на основе тегов позволяет управлять доступом к ресурсам нескольких компонентов **Hadoop** без создания отдельных сервисов и политик в каждом компоненте. Можно также использовать **Ranger TagSync** для синхронизации хранилища тегов **Ranger** с внешним сервисом метаданных, таким как **Apache Atlas**.


Создание HDFS Policy
^^^^^^^^^^^^^^^^^^^^^

Благодаря конфигурации **Apache Ranger** позволяет проверять для запроса пользователя как политики **Ranger**, так и разрешения **HDFS**. Когда **NameNode** получает пользовательский запрос, плагин **Ranger** проверяет политики, установленные через **Ranger Service Manager**, и если их нет, проверяет разрешения, установленные в **HDFS**.

Рекомендуется создавать разрешения в **Ranger Service Manager** и иметь ограниченные разрешения на уровне **HDFS**.

Добавление новой политики к существующему сервису **HDFS** осуществляется по следующему алгоритму:

1. На странице "Service Manager" выбрать существующий сервис в разделе HDFS (:numref:`Рис.%s.<security_authorizationHadoop_PolicyHDFS_Existing-service>`).

.. _security_authorizationHadoop_PolicyHDFS_Existing-service:

.. figure:: ../imgs/security_authorizationHadoop_PolicyHDFS_Existing-service.*
   :align: center

   Выбор сервиса HDFS

При этом открывается страница "List of Policies", на которой необходимо нажать кнопку "Add New Policy" (:numref:`Рис.%s.<security_authorizationHadoop_PolicyHDFS_List-Policies>`).

.. _security_authorizationHadoop_PolicyHDFS_List-Policies:

.. figure:: ../imgs/security_authorizationHadoop_PolicyHDFS_List-Policies.*
   :align: center

   List of Policies

2. Открывается страница "Create Policy" (:numref:`Рис.%s.<security_authorizationHadoop_PolicyHDFS_Create-Policy>`).

.. _security_authorizationHadoop_PolicyHDFS_Create-Policy:

.. figure:: ../imgs/security_authorizationHadoop_PolicyHDFS_Create-Policy.*
   :align: center

   Create Policy

На странице необходимо заполнить поля. Раздел "Policy Details":

+ *Policy Name* -- ввести уникальное имя для данной политики (имя не может быть продублировано нигде в системе);
+ *Resource Path* -- определить путь к ресурсу для папки/файла политики. Во избежание необходимости указывать полный путь или включать политику для всех вложенных папок или файлов, можно заполнить это поле с помощью подстановочных знаков (например, /home*) либо указать, что политика должна быть рекурсивной;

  + Подстановочные знаки могут быть включены в путь ресурса, имя базы данных, таблицы или столбца: "*" -- указывает ноль или более символов; "?" -- указывает один символ;

+ *Description* -- (опционально) указать цель политики;
+ *Audit Logging* -- указать, выполняется ли аудит данной политики (снять флажок, чтобы отключить аудит).

Раздел "Allow Conditions":

+ *Select Group* -- указать группу, к которой применяется данная политика. Чтобы назначить группу в качестве администратора для выбранного ресурса, выбрать *Admin permissions* (администраторы могут создавать дочерние политики на основе существующих). Группа *public* содержит всех пользователей, поэтому предоставление доступа к ней предоставляет доступ ко всем пользователям;
+ *Select User* -- указать конкретного пользователя, к которому применяется данная политика (за пределами уже указанной группы), или назначить определенного пользователя администратором данной политики (администраторы могут создавать дочерние политики на основе существующих);
+ *Permissions* -- добавить или изменить права: *Read* (чтение), *Write* (запись), *Create* (создание), *Admin* (Администратор), *Select/Deselect All* (выбрать/отменить все);
+ *Delegate Admin* -- когда политика назначается пользователю или группе пользователей, данные пользователи становятся делегированными администраторами. Делегированный администратор может обновлять, удалять политики. Он также может создавать дочерние политики на основе исходной (базовой);

3. Для добавления дополнительных условий можно использовать символ плюс "+". Условия оцениваются в порядке, указанном в списке -- сначала применяется условие в верхней части списка, затем второе, третье и так далее;

4. Нажать кнопку *Add* для сохранения новой политики.
