
Установка Ranger
=================


Установка **Ranger** с помощью **ADCM** заключается в три этапа:

+ `Загрузка бандла Arenadata Platform Security`_
+ `Создание кластера`_
+ `Конфигурирование сервисов`_
+ `Завершение установки`_

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
