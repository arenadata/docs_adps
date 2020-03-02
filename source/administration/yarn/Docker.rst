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




