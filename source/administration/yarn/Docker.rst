Запуск приложений с использованием Docker-контейнеров
======================================================

.. important:: Включение функции и запуск Docker-контейнеров в кластере имеет последствия для безопасности. Учитывая интеграцию Docker со многими мощными функциями ядра, крайне важно, чтобы администраторы понимали безопасность Docker, прежде чем включать данный функционал

`Docker <https://www.docker.io/>`_ сочетает в себе простой в использовании интерфейс с контейнерами **Linux** и простые в создании image-файлы для них. В общем получается, что Docker позволяет пользователям создавать бандлы (bundle) -- то есть связывать приложение с его предпочтительной средой выполнения для исполнения на целевой машине. Дополнительные сведения о Docker приведены в `документации <http://docs.docker.com/>`_.

Механизм **Linux Container Executor** (**LCE**) позволяет **YARN NodeManager** приводить в действие YARN-контейнеры для запуска непосредственно на хост-машине либо внутри Docker-контейнеров. Приложение, запрашивающее ресурсы, может указать для каждого контейнера, как оно должно выполняться. **LCE** также обеспечивает повышенную безопасность, и поэтому он требуется при развертывании кластера. Когда **LCE** запускает YARN-контейнер для выполнения в Docker, приложение может указать используемый образ (image) Docker.

Docker-контейнеры предоставляют кастомную среду выполнения, в которой запускается код приложения, изолированный от среды выполнения **NodeManager** и других приложений. Эти контейнеры могут включать специальные необходимые для приложения библиотеки, и они могут иметь различные версии собственных инструментов и библиотек, включая **Perl**, **Python** и **Java**. Docker-контейнеры могут даже работать с другим типом **Linux**, нежели тот, что работает на **NodeManager**.

Docker для **YARN** обеспечивает как согласованность (все YARN-контейнеры имеют одинаковую программную среду), так и изоляцию (без вмешательства в то, что установлено на физической машине).


Конфигурация кластера
-----------------------

**LCE** требует, чтобы бинарный файл container-executor принадлежал *root:hadoop* и имел разрешения *6050*. Для запуска Docker-контейнеров, демон (daemon) Docker должен быть запущен на всех хостах **NodeManager**, где планируют запускаться Docker-контейнеры. Docker-клиент также должен быть установлен на всех хостах **NodeManager**, на которых планируют запускаться Docker-контейнеры, должен быть запущен и иметь возможность старта Docker-контейнеров.

Для предотвращения тайм-аутов при запуске заданий любые большие Docker-образы, которые планируют использоваться приложением, уже должны быть загружены в кэш Docker-демона на хостах **NodeManager**. Простой способ загрузить образ -- выполнить pull-запрос. Например:

::

 sudo docker pull library/openjdk:8

Следующие свойства должны быть установлены в *yarn-site.xml*:

::

 <configuration>
   <property>
     <name>yarn.nodemanager.container-executor.class</name>
     <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
     <description>
       This is the container executor setting that ensures that all applications
       are started with the LinuxContainerExecutor.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.linux-container-executor.group</name>
     <value>hadoop</value>
     <description>
       The POSIX group of the NodeManager. It should match the setting in
       "container-executor.cfg". This configuration is required for validating
       the secure access of the container-executor binary.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.linux-container-executor.nonsecure-mode.limit-users</name>
     <value>false</value>
     <description>
       Whether all applications should be run as the NodeManager process' owner.
       When false, applications are launched instead as the application owner.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.allowed-runtimes</name>
     <value>default,docker</value>
     <description>
       Comma separated list of runtimes that are allowed when using
       LinuxContainerExecutor. The allowed values are default, docker, and
       javasandbox.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.allowed-container-networks</name>
     <value>host,none,bridge</value>
     <description>
       Optional. A comma-separated set of networks allowed when launching
       containers. Valid values are determined by Docker networks available from
       `docker network ls`
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.default-container-network</name>
     <value>host</value>
     <description>
       The network used when launching Docker containers when no
       network is specified in the request. This network must be one of the
       (configurable) set of allowed container networks.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.host-pid-namespace.allowed</name>
     <value>false</value>
     <description>
       Optional. Whether containers are allowed to use the host PID namespace.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.privileged-containers.allowed</name>
     <value>false</value>
     <description>
       Optional. Whether applications are allowed to run in privileged
       containers. Privileged containers are granted the complete set of
       capabilities and are not subject to the limitations imposed by the device
       cgroup controller. In other words, privileged containers can do almost
       everything that the host can do. Use with extreme care.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.delayed-removal.allowed</name>
     <value>false</value>
     <description>
       Optional. Whether or not users are allowed to request that Docker
       containers honor the debug deletion delay. This is useful for
       troubleshooting Docker container related launch failures.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.stop.grace-period</name>
     <value>10</value>
     <description>
       Optional. A configurable value to pass to the Docker Stop command. This
       value defines the number of seconds between the docker stop command sending
       a SIGTERM and a SIGKILL.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.privileged-containers.acl</name>
     <value></value>
     <description>
       Optional. A comma-separated list of users who are allowed to request
       privileged contains if privileged containers are allowed.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.capabilities</name>
     <value>CHOWN,DAC_OVERRIDE,FSETID,FOWNER,MKNOD,NET_RAW,SETGID,SETUID,SETFCAP,SETPCAP,NET_BIND_SERVICE,SYS_CHROOT,KILL,AUDIT_WRITE</value>
     <description>
       Optional. This configuration setting determines the capabilities
       assigned to docker containers when they are launched. While these may not
       be case-sensitive from a docker perspective, it is best to keep these
       uppercase. To run without any capabilites, set this value to
       "none" or "NONE"
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.enable-userremapping.allowed</name>
     <value>true</value>
     <description>
       Optional. Whether docker containers are run with the UID and GID of the
       calling user.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.userremapping-uid-threshold</name>
     <value>1</value>
     <description>
       Optional. The minimum acceptable UID for a remapped user. Users with UIDs
       lower than this value will not be allowed to launch containers when user
       remapping is enabled.
     </description>
   </property>
 
   <property>
     <name>yarn.nodemanager.runtime.linux.docker.userremapping-gid-threshold</name>
     <value>1</value>
     <description>
       Optional. The minimum acceptable GID for a remapped user. Users belonging
       to any group with a GID lower than this value will not be allowed to
       launch containers when user remapping is enabled.
     </description>
   </property>
 
 </configuration>


Кроме того, файл *container-executer.cfg* должен существовать и содержать настройки для исполнителя контейнера. Файл должен принадлежать пользователю *root* с разрешениями *0400*. Формат файла -- это стандартный формат файла свойств **Java**, например:

::

 `key=value`

Для включения поддержки Docker требуются следующее свойство:

``yarn.nodemanager.linux-container-executor.group`` -- группа Unix для NodeManager. Должно соответствовать ``yarn.nodemanager.linux-container-executor.group`` в файле *yarn-site.xml*.

Файл *container-executor.cfg* должен содержать раздел, чтобы определить возможности, которые разрешены для контейнеров. Содержит следующие свойства:

``module.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить запуск Docker-контейнеров. Значение по умолчанию *0*;

``docker.binary`` -- бинарный файл, используемый для запуска Docker-контейнеров. По умолчанию */usr/bin/docker*;

``docker.allowed.capabilities`` -- разделенные запятыми возможности, которые могут добавлять контейнеры. По умолчанию никакие возможности не могут быть ими добавлены;

``docker.allowed.devices`` -- разделенные запятыми устройства, для которых разрешено устанавливаться к контейнерам. По умолчанию никакие устройства не могут быть добавлены;

``docker.allowed.networks`` -- разделенные запятыми сети, которые разрешено использовать контейнерам. Если при запуске контейнера сеть не указана, используется сеть Docker по умолчанию;

``docker.allowed.ro-mounts`` -- разделенные запятыми каталоги, которые контейнеры могут устанавливать в режиме только для чтения. По умолчанию никакие каталоги не разрешено монтировать;

``docker.allowed.rw-mounts`` -- разделенные запятыми каталоги, которые контейнеры могут устанавливать в режиме чтения-записи. По умолчанию никакие каталоги не разрешено монтировать;

``docker.allowed.volume-drivers`` -- разделенный запятыми список драйверов объема, которые разрешено использовать. По умолчанию никакие драйверы объема не разрешены;

``docker.host-pid-namespace.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить использование хостом PID namespace. Значением по умолчанию является *false*;

``docker.privileged-containers.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить запуск привилегированных контейнеров. Значением по умолчанию является *false*;

``docker.trusted.registries`` -- разделенный запятыми список реестров доверенного докера для запуска доверенных привилегированных Docker-контейнеров. По умолчанию реестры не определены;

``docker.inspect.max.retries`` -- значение Integer для проверки готовности Docker-контейнера. Каждая проверка устанавливается с отсрочкой *3* секунды. Значение по умолчанию, равное *10*, ожидает *30* секунд, пока Docker-контейнер не станет готов, прежде чем пометить его как сбой;

``docker.no-new-privileges.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить флаг *no-new-privileges* для запуска Docker. Значением по умолчанию является *false*;

``docker.allowed.runtimes`` -- разделенные запятыми среды выполнения, которые разрешено использовать контейнерам. По умолчанию никакая среда выполнения не может быть добавлена.

.. important:: При необходимости запуска Docker-контейнеров, которым требуется доступ к локальным каталогам YARN, следует добавить их в список *docker.allowed.rw-mounts*

Кроме того, контейнерам не разрешается устанавливать любого родителя каталога *container-executor.cfg* в режиме чтения-записи.

Следующие свойства являются опциональными:

``min.user.id`` -- минимальный UID, разрешенный для запуска приложений. По умолчанию минимум не установлен;

``banned.users`` -- разделенный запятыми список имен пользователей, которым нельзя разрешать запуск приложений. Значение по умолчанию: *yarn*, *mapred*, *hdfs* и *bin*;

``allowed.system.users`` -- разделенный запятыми список имен пользователей, которым следует разрешать запуск приложений, даже если их UID ниже настроенного минимума. Если пользователь указан в ``allowed.system.users`` и ``banned.users``, он считается забаненным;

``feature.tc.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить команды управления движением (traffic control commands).

Фрагмент *container-executor.cfg*, который позволяет запускать Docker-контейнеры:

::

 yarn.nodemanager.linux-container-executor.group=yarn
 [docker]
   module.enabled=true
   docker.privileged-containers.enabled=true
   docker.trusted.registries=centos
   docker.allowed.capabilities=SYS_CHROOT,MKNOD,SETFCAP,SETPCAP,FSETID,CHOWN,AUDIT_WRITE,SETGID,NET_RAW,FOWNER,SETUID,DAC_OVERRIDE,KILL,NET_BIND_SERVICE
   docker.allowed.networks=bridge,host,none
   docker.allowed.ro-mounts=/sys/fs/cgroup
   docker.allowed.rw-mounts=/var/hadoop/yarn/local-dir,/var/hadoop/yarn/log-dir


Docker Image Requirements
---------------------------


Application Submission
-----------------------


Using Docker Bind Mounted Volumes
----------------------------------


User Management in Docker Container
-------------------------------------


Privileged Container Security Consideration
--------------------------------------------


Container Reacquisition Requirements
-------------------------------------


Connecting to a Secure Docker Repository
-----------------------------------------


Example: MapReduce
-------------------


Example: Spark
---------------


Docker Container ENTRYPOINT Support
------------------------------------




