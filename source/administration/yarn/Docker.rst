Запуск приложений с использованием Docker-контейнеров
======================================================

.. important:: Включение функции и запуск Docker-контейнеров в кластере имеет последствия для безопасности. Учитывая интеграцию Docker со многими мощными функциями ядра, крайне важно, чтобы администраторы понимали безопасность Docker, прежде чем включать данный функционал

`Docker <https://www.docker.io/>`_ сочетает в себе простой в использовании интерфейс с контейнерами **Linux** и простые в создании image-файлы для них. В общем получается, что Docker позволяет пользователям создавать бандлы (bundle) -- то есть связывать приложение с его предпочтительной средой выполнения для исполнения на целевой машине. Дополнительные сведения о Docker приведены в `документации <http://docs.docker.com/>`_.

Механизм **Linux Container Executor** (**LCE**) позволяет **YARN NodeManager** приводить в действие YARN-контейнеры для запуска непосредственно на хост-машине либо внутри Docker-контейнеров. Приложение, запрашивающее ресурсы, может указать для каждого контейнера, как оно должно выполняться. **LCE** также обеспечивает повышенную безопасность, и поэтому он требуется при развертывании кластера. Когда **LCE** запускает YARN-контейнер для выполнения в Docker, приложение может указать используемый образ (image) Docker.

Docker-контейнеры предоставляют кастомную среду выполнения, в которой запускается код приложения, изолированный от среды выполнения **NodeManager** и других приложений. Эти контейнеры могут включать специальные необходимые для приложения библиотеки, и они могут иметь различные версии собственных инструментов и библиотек, включая **Perl**, **Python** и **Java**. Docker-контейнеры могут даже работать с другим типом **Linux**, нежели тот, что работает на **NodeManager**.

Docker для **YARN** обеспечивает как согласованность (все YARN-контейнеры имеют одинаковую программную среду), так и изоляцию (без вмешательства в то, что установлено на физической машине).


Конфигурация кластера
-----------------------

**LCE** требует, чтобы бинарный файл container-executor принадлежал *root:hadoop* и имел разрешения *6050*. Для запуска Docker-контейнеров, демон (daemon) Docker должен быть запущен на всех хостах **NodeManager**, где планируют запускаться docker-контейнеры. Docker-клиент также должен быть установлен на всех хостах **NodeManager**, на которых планируют запускаться docker-контейнеры, должен быть запущен и иметь возможность старта Docker-контейнеров.

Для предотвращения тайм-аутов при запуске заданий любые большие Docker-образы, которые планируют использоваться приложением, уже должны быть загружены в кэш docker-демона на хостах **NodeManager**. Простой способ загрузить образ -- выполнить pull-запрос. Например:

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

``docker.binary`` -- бинарный файл, используемый для запуска docker-контейнеров. По умолчанию */usr/bin/docker*;

``docker.allowed.capabilities`` -- разделенные запятыми возможности, которые могут добавлять контейнеры. По умолчанию никакие возможности не могут быть ими добавлены;

``docker.allowed.devices`` -- разделенные запятыми устройства, для которых разрешено устанавливаться к контейнерам. По умолчанию никакие устройства не могут быть добавлены;

``docker.allowed.networks`` -- разделенные запятыми сети, которые разрешено использовать контейнерам. Если при запуске контейнера сеть не указана, используется сеть Docker по умолчанию;

``docker.allowed.ro-mounts`` -- разделенные запятыми каталоги, которые контейнеры могут устанавливать в режиме только для чтения. По умолчанию никакие каталоги не разрешено монтировать;

``docker.allowed.rw-mounts`` -- разделенные запятыми каталоги, которые контейнеры могут устанавливать в режиме чтения-записи. По умолчанию никакие каталоги не разрешено монтировать;

``docker.allowed.volume-drivers`` -- разделенный запятыми список драйверов тома Docker, которые разрешено использовать. По умолчанию никакие драйверы тома не разрешены;

``docker.host-pid-namespace.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить использование хостом PID namespace. Значением по умолчанию является *false*;

``docker.privileged-containers.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить запуск привилегированных контейнеров. Значением по умолчанию является *false*;

``docker.trusted.registries`` -- разделенный запятыми список реестров доверенного докера для запуска доверенных привилегированных docker-контейнеров. По умолчанию реестры не определены;

``docker.inspect.max.retries`` -- значение Integer для проверки готовности docker-контейнера. Каждая проверка устанавливается с отсрочкой *3* секунды. Значение по умолчанию, равное *10*, ожидает *30* секунд, пока Docker-контейнер не станет готов, прежде чем пометить его как сбой;

``docker.no-new-privileges.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить флаг *no-new-privileges* для запуска Docker. Значением по умолчанию является *false*;

``docker.allowed.runtimes`` -- разделенные запятыми среды выполнения, которые разрешено использовать контейнерам. По умолчанию никакая среда выполнения не может быть добавлена.

.. important:: При необходимости запуска Docker-контейнеров, которым требуется доступ к локальным каталогам YARN, следует добавить их в список *docker.allowed.rw-mounts*

Кроме того, контейнерам не разрешается устанавливать любого родителя каталога *container-executor.cfg* в режиме чтения-записи.

Следующие свойства являются опциональными:

``min.user.id`` -- минимальный UID, разрешенный для запуска приложений. По умолчанию минимум не установлен;

``banned.users`` -- разделенный запятыми список имен пользователей, которым нельзя разрешать запуск приложений. Значение по умолчанию: *yarn*, *mapred*, *hdfs* и *bin*;

``allowed.system.users`` -- разделенный запятыми список имен пользователей, которым следует разрешать запуск приложений, даже если их UID ниже настроенного минимума. Если пользователь указан в ``allowed.system.users`` и ``banned.users``, он считается забаненным;

``feature.tc.enabled`` -- значение должно быть *true* или *false*, чтобы включить или отключить команды управления движением (traffic control commands).

Фрагмент *container-executor.cfg*, который позволяет запускать docker-контейнеры:

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


Требования Docker-образа
-------------------------

Для работы с **YARN** существует два требования к docker-образам.

Во-первых, docker-контейнер явно запускается с владельцем приложения в качестве пользователя контейнера. Если владелец приложения не является валидным пользователем в docker-образе, приложение завершается ошибкой. Пользователь контейнера указывается в UID. Если UID пользователя в **NodeManager** и в docker-образе отличается, контейнер может быть запущен как неправильный пользователь или может не запуститься вовсе, так как UID не существует (подробнее в `<Управление пользователями>`_).

Во-вторых, docker-образ должен иметь то, что ожидает приложение для выполнения. В случае **Hadoop** (**MapReduce** или **Spark**) Docker-образ должен содержать библиотеки *JRE* и *Hadoop* и иметь набор необходимых переменных окружения: *JAVA_HOME*, *HADOOP_COMMON_PATH*, *HADOOP_HDFS_HOME*, *HADOOP_MAPRED_HOME*, *HADOOP_YARN_HOME*, *HADOOP_CONF_DIR*. Важно обратить внимание, что доступные в docker-образе версии компонентов **Java** и **Hadoop** должны быть совместимы с тем, что установлено в кластере, и с любыми другими docker-образами, используемыми для других задач того же задания. В противном случае компоненты **Hadoop**, запущенные в docker-контейнере, не смогут взаимодействовать с внешними компонентами **Hadoop**.

Если docker-образ имеет набор команд `command <https://docs.docker.com/engine/reference/builder/#cmd>`_, поведение зависит от того, установлено ли значение параметра ``YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE`` в *true*. Если это так, то команда  переопределяется, когда **LCE** запускает образ с помощью скрипта запуска контейнера **YARN**.

Если для docker-образа задана точка входа и для параметра ``YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE`` установлено значение *true*, команда *launch_command* передается в программу *ENTRYPOINT* в качестве параметров CMD в Docker. Формат *launch_command* выглядит следующим образом: ``param1,param2``, что приводит к CMD ``[ “param1”,“param2” ]`` в Docker.

Если приложение запрашивает docker-образ, который еще не загружен Docker-демоном на хосте, где он должен выполняться, Docker-демон неявно выполняет pull-команду. **MapReduce** и **Spark** предполагают, что задачи, для отчета о которых требуется более 10 минут, остановились, поэтому указание большого Docker-образа может привести к сбою приложения.


Отправка приложения
-----------------------

Перед запуском docker-контейнера необходимо убедиться, что конфигурация **LCE** работает для приложений, запрашивающих обычные YARN-контейнеры. Если после включения **LCE** не удается запустить один или несколько **NodeManager**, скорее всего причина в том, что владение и/или разрешения для бинарного файла *container-executer* неверны. Тогда следует проверить журналы.

Для запуска приложения в docker-контейнере необходимо установить следующие переменные среды в среде приложения (первые два обязательны, остальная часть может быть установлена по мере необходимости):

``YARN_CONTAINER_RUNTIME_TYPE`` -- определяет, будет ли приложение запущено в Docker-контейнере. Если значение установлено на *docker*, приложение запускается в Docker-контейнере. В противном случае используется обычный контейнер дерева процессов;

``YARN_CONTAINER_RUNTIME_DOCKER_IMAGE`` -- имена, образ которых используется для запуска Docker-контейнера. Можно использовать любое имя образа, которое можно передать команде запуска Docker-клиента. Имя образа может включать repo-префикс;

``YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE`` -- управляет переопределением команды по умолчанию Docker-контейнера. При установленном значении *true* команда Docker-контейнера является ``bash path_to_launch_script``. Если параметр не задан или установлено *false*, используется команда по умолчанию;

``YARN_CONTAINER_RUNTIME_DOCKER_CONTAINER_NETWORK`` -- устанавливает тип сети для использования Docker-контейнером. Это должно быть валидное значение, определенное свойством ``yarn.nodemanager.runtime.linux.docker.allowed-container-networks``;

``YARN_CONTAINER_RUNTIME_DOCKER_PORTS_MAPPING`` -- позволяет пользователю указать маппинг портов для сетевого моста Docker-контейнера. Значением переменной среды должен быть разделенный запятыми список портов. Аналогично опции ``-p`` для команды запуска Docker. Если значение не установлено, указывается ``-P``;

``YARN_CONTAINER_RUNTIME_DOCKER_CONTAINER_PID_NAMESPACE`` -- определяет, какое пространство имен PID используется Docker-контейнером. По умолчанию каждый Docker-контейнер имеет свое собственное пространство имен PID. Для совместного использования пространства имен на хосте необходимо установить для свойства ``yarn.nodemanager.runtime.linux.docker.host-pid-namespace.allowed`` значение *true*. При разрешенном пространстве имен PID на хосте и заданном значении для данной переменной среды *host* Docker-контейнер использует пространство имен PID хоста. Другие значения не допускаются, поэтому при необходимости переменную следует оставить неустановленной, а не задавать ей значение *false*;

``YARN_CONTAINER_RUNTIME_DOCKER_RUN_PRIVILEGED_CONTAINER`` -- определяет, является ли Docker-контейнер привилегированным контейнером. Чтобы использовать привилегированные контейнеры, для свойства ``yarn.nodemanager.runtime.linux.docker.privileged-containers.allowed`` должно быть установлено значение *true*, а владелец приложения должен отображаться в значении ``yarn.nodemanager.runtime.linux.docker.privileged-containers.acl``. Если для данной переменной среды задано значение *true*, то используется привилегированный Docker-контейнер, если это разрешено. Другие значения не допускаются, поэтому при необходимости переменную окружения следует оставить неустановленной, а не задавать ей значение *false*;

``YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS`` -- добавляет дополнительный том в Docker-контейнер. Значением переменной среды должен быть список точек монтирования через запятую. Все такие монтирования должны быть указаны как ``source:dest[:mode]``, а чтобы указать тип запрашиваемого доступа режим должен быть ``ro`` (read-only) или ``rw`` (read-write). Если ни то, ни другое не указано, принимается режим чтение-запись. Режим может включать опцию распространения привязки (bind propagation). В этом случае режим должен иметь вид ``[option]``, ``rw+[option]`` или ``ro+[option]``. Допустимые варианты распространения привязки: *shared*, *rshared*, *slave*, *rslave*, *private* и *rprivate*. Запрашиваемые монтирования проверяются на основе значений, установленных в *container-executor.cfg* для ``docker.allowed.ro-mounts`` и ``docker.allowed.rw-mounts``;

``YARN_CONTAINER_RUNTIME_DOCKER_TMPFS_MOUNTS`` -- добавляет дополнительные *tmpfs* в docker-контейнер. Значением переменной среды должен быть список разделенных запятыми абсолютных точек монтирования в контейнере;

``YARN_CONTAINER_RUNTIME_DOCKER_DELAYED_REMOVAL`` -- позволяет пользователю запрашивать отложенное удаление Docker-контейнера на основе каждого контейнера. Если установлено значение *true*, docker-контейнеры не удаляются до тех пор, пока не истечет время, определенное параметром ``yarn.nodemanager.delete.debug-delay-sec``. Администраторы могут отключить эту функцию через yarn-site свойство ``yarn.nodemanager.runtime.linux.docker.delayed-removal.allowed``. По умолчанию функция отключена. При отключенной функции или при значении параметра *false* контейнер удаляется, как только он выйдет.

Когда приложение отправляется для запуска в Docker-контейнере, оно ведет себя точно так же, как и любое другое приложение **YARN**. Журналы агрегируются и сохраняются на соответствующем сервере истории. Жизненный цикл приложения остается таким же, как и для приложения, не являющегося Docker.


Использование Docker Bind Mounted Volumes
-------------------------------------------

.. important:: Включение доступа к каталогам, таким как /, /etc, /run или /home, не рекомендуется и может привести к тому, что контейнеры негативно повлияют на хост или приведут к утечке конфиденциальной информации

Файлы и каталоги с хоста обычно необходимы в Docker-контейнерах, которые Docker предоставляет через тома `volumes <https://docs.docker.com/engine/tutorials/dockervolumes/>`_. Примеры включают локализованные ресурсы, бинарные файлы **Apache Hadoop** и сокеты. Чтобы облегчить эту потребность, в *YARN-6623* добавлена возможность для администраторов устанавливать белый список каталогов хоста, который выполняет *bind mounted* в виде томов в контейнерах. В *YARN-5534* добавлена возможность предоставления пользователям списка монтирований в контейнеры, если это разрешено белым списком администратора.

Для использования этой функции необходимо:

+ Администратор должен определить белый список томов в *container-executor.cfg*, установив ``docker.allowed.ro-mounts`` и ``docker.allowed.rw-mounts`` в список родительских каталогов, которые могут быть монтированы;

+ Отправитель приложения запрашивает необходимые тома во время отправки приложения, используя переменную среды ``YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS``.

Предоставленный администратором белый список определяется как разделенный запятыми список каталогов, которые разрешено монтировать в контейнеры. Исходный каталог, предоставленный пользователем, должен совпадать или быть дочерним по отношению к указанному каталогу.

Предоставленный пользователем список монтирования определяется как разделенный запятыми список в форме ``source:destination`` или ``source:destination:mode``. Источником является файл или каталог на хосте. Пункт назначения -- это путь через контейнер, по которому осуществляется *bind mounted*. Режим определяет режим, который пользователь ожидает для монтирования, который может быть ``ro`` (read-only) или ``rw`` (read-write). Если ни то, ни другое не указано, принимается режим чтение-запись. Режим может включать опцию распространения привязки (bind propagation). Допустимые варианты: *shared*, *rshared*, *slave*, *rslave*, *private* и *rprivate*. В этом случае режим должен иметь вид ``option``, ``rw+option`` или ``ro+option``.

Далее показано, как использовать эту функцию для монтирования обычно необходимого каталога */sys/fs/cgroup* в запущенный на **YARN** контейнер.

Администратор устанавливает ``docker.allowed.ro-mounts`` в *container-executor.cfg* в *"/sys/fs/cgroup"*. После этого приложения могут запросить монтирование *"/sys/fs/cgroup"* с хоста в контейнер в read-only режиме. Во время отправки приложения можно установить переменную среды ``YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS`` для запроса этого монтирования. В данном примере переменная окружения устанавливается на *"/sys/fs/cgroup:/sys/fs/cgroup:ro"*, при этом путь назначения не ограничен, и *"/sys/fs/cgroup:/cgroup:ro"* также валиден с учетом приведенного в пример белого списка администратора.


Управление пользователями
--------------------------

Поддержка docker-контейнеров **YARN** запускает контейнерные процессы с использованием идентификатора пользователя *uid:gid*, определенного на хосте **NodeManager**. Несоответствие имени пользователя и группы между хостом **NodeManager** и контейнером может привести к проблемам с разрешениями, неудачным запускам контейнера или даже к пробелам в безопасности. Централизованное управление пользователями и группами как для хостов, так и для контейнеров значительно снижает эти риски. При запуске контейнерных приложений в **YARN** необходимо понимать, какая пара *uid:gid* будет использоваться для запуска процесса контейнера.

По умолчанию в небезопасном режиме non-secure **YARN** запускает процессы как пользователь *nobody*. В системах на базе **CentOS** uid пользователя *nobody* равен *99*, и группы *nobody* тоже *99*. В результате **YARN** вызывает ``docker run`` с ``--user 99:99``. Если у пользователя *nobody* нет *uid 99* в контейнере, запуск может завершиться неудачей или привести к неожиданным результатам.

Единственным исключением из этого правила является использование Docker-контейнеров Privileged. Привилегированные контейнеры не устанавливают пару *uid:gid* при запуске контейнера и учитывают записи *USER* и *GROUP* в Dockerfile. Это позволяет запускать привилегированные контейнеры как любой пользователь, но имеет последствия для безопасности. 

Есть много способов управления пользователями и группами. По умолчанию Docker аутентифицирует пользователей по */etc/passwd* (и */etc/shadow*) внутри контейнера. Но использование */etc/passwd*, представленного в docker-образе, вряд ли содержит соответствующие записи пользователя и скорее приведет к сбоям запуска. Поэтому настоятельно рекомендуется централизовать управление пользователями и группами. Несколько подходов к управлению пользователями и группами описано далее.


Статическое управление
^^^^^^^^^^^^^^^^^^^^^^^^

Основным подходом к управлению пользователями и группами является изменение пользователя и группы в Docker-образе. Этот подход возможен только в небезопасном режиме, когда все контейнерные процессы запускаются как один известный пользователь, например, *nobody*. В этом случае единственным требованием является соответствие пары *uid:gid* пользователя и группы *nobody* между хостом и контейнером. В системе на базе **CentOS** это означает, что пользователю *nobody* в контейнере нужен *UID 99*, а группе *nobody* в контейнере нужен *GID 99*.

Один из подходов к изменению UID и GID заключается в использовании *usermod* и *groupmod*. Установка правильных UID и GID для пользователя/группы *nobody*:

::

 usermod -u 99 nobody
 groupmod -g 99 nobody

Данный подход не рекомендуется использовать после тестирования, учитывая негибкость добавления пользователей.


Bind mounting
^^^^^^^^^^^^^^^

Когда в компании уже имеется автоматизация для создания локальных пользователей в каждой системе, может быть целесообразно выполнить bind mount */etc/passwd* и */etc/group* в контейнер в качестве альтернативы непосредственному измененю образа контейнера. Для подключения возможности bind mount */etc/passwd* и */etc/group* необходимо обновить ``docker.allowed.ro-mounts`` в *container-executor.cfg*, чтобы включить эти пути. Затем при отправке приложения ``YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS`` должен содержать */etc/passwd:/etc/passwd:ro* и */etc/group:/etc/group:ro*.

У данного подхода bind mount есть пара проблем, которые необходимо учитывать:

+ Любые пользователи и группы, определенные в образе, перезаписываются пользователями и группами хоста;

+ После запуска контейнера нельзя добавлять пользователей и группы, так как */etc/passwd* и */etc/group* неизменны в контейнере. Не рекомендуется монтировать эти файлы для чтения и записи, так как это может привести к неработоспособности хоста.

Данный подход не рекомендуется использовать после тестирования, учитывая негибкость модификации запущенных контейнеров.


SSSD
^^^^^^

Альтернативным подходом, позволяющим централизованно управлять пользователями и группами, является SSSD -- System Security Services Daemon, предоставляющий доступ к различным поставщикам аутентификации, таким как **LDAP** и **Active Directory**.

Традиционная схема для аутентификации **Linux**:

::

 application -> libpam -> pam_authenticate -> pam_unix.so -> /etc/passwd

При использовании SSSD для user-lookup схема принимает вид:

::

 application -> libpam -> pam_authenticate -> pam_sss.so -> SSSD -> pam_unix.so -> /etc/passwd

Можно выполнить bind-mount UNIX-сокетов к контейнеру через SSSD коммуникации. Это позволяет библиотекам на стороне клиента SSSD проходить аутентификацию на SSSD, запущенном на хосте. В результате пользовательская информация не должна существовать в */etc/passwd* docker-образа, а вместо этого обслуживается SSSD.

Пошаговая настройка хоста и контейнера:

1. Конфигурация хоста:

+ Установка пакетов:

::

 # yum -y install sssd-common sssd-proxy

+ Создание PAM-сервиса для контейнера:

::

 # cat /etc/pam.d/sss_proxy
 auth required pam_unix.so
 account required pam_unix.so
 password required pam_unix.so
 session required pam_unix.so

+ Создание концигурационного файла SSSD */etc/sssd/sssd.conf*. Важно обратить внимание, что разрешения должны быть *0600*, а файл должен принадлежать пользователю *root:root*:

::

 # cat /etc/sssd/sssd/conf
 [sssd]
 services = nss,pam
 config_file_version = 2
 domains = proxy
 [nss]
 [pam]
 [domain/proxy]
 id_provider = proxy
 proxy_lib_name = files
 proxy_pam_target = sss_proxy

+ Запуск SSSD:

::
 
 # systemctl start sssd

+ Проверка, что пользователь может быть извлечен с помощью SSSD:

::

 # getent passwd -s sss localuser

2. Настройка контейнера. Важно выполнить bind-mount каталога */var/lib/sss/pipes* от хоста к контейнеру, так как SSSD UNIX сокеты находятся там:

::

 -v /var/lib/sss/pipes:/var/lib/sss/pipes:rw

3. Конфигурация контейнера. Все шаги выполнются на самом контейнере:

+ Установка только клиентских библиотек sss:

::

 # yum -y install sssd-client

+ Проверка, что sss настроена для баз данных *passwd* и *group*:

::

 /etc/nsswitch.conf

+ Настройка PAM-сервиса, используемого приложением для вызова в SSSD:

::

 # cat /etc/pam.d/system-auth
 #%PAM-1.0
 # This file is auto-generated.
 # User changes will be destroyed the next time authconfig is run.
 auth        required      pam_env.so
 auth        sufficient    pam_unix.so try_first_pass nullok
 auth        sufficient    pam_sss.so forward_pass
 auth        required      pam_deny.so
 
 account     required      pam_unix.so
 account     [default=bad success=ok user_unknown=ignore] pam_sss.so
 account     required      pam_permit.so
 
 password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
 password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
 password    sufficient    pam_sss.so use_authtok
 password    required      pam_deny.so
 
 session     optional      pam_keyinit.so revoke
 session     required      pam_limits.so
 -session     optional      pam_systemd.so
 session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
 session     required      pam_unix.so
 session     optional      pam_sss.so

+ Сохранение docker-образа и последущее использование его в качестве базового образа приложений.

+ Тестирование Docker-образа, запущенного в среде YARN:

::

 $ id
 uid=5000(localuser) gid=5000(localuser) groups=5000(localuser),1337(hadoop)



Безопасность привилегированного контейнера
--------------------------------------------

Docker-контейнер Privileged может взаимодействовать с устройствами хост-системы, но без надлежащей осторожности это может нанести вред операционной системе хоста. Чтобы снизить риск запуска привилегированного контейнера в кластере **Hadoop**, внедрен управляемый процесс для песочницы неавторизованных привилегированных Docker-образов.

Поведение по умолчанию запрещает любые docker-контейнеры Privileged. Когда для ``docker.privileged-containers.enabled`` установлено значение *enabled*, docker-образ может запускаться с правами *root* в docker-контейнере, но доступ к устройствам уровня хоста отключен. Это позволяет разработчикам и тестировщикам запускать docker-образы из Интернета, не причиняя вреда операционной системе хоста.

В случае когда docker-образы сертифицированы разработчиками и тестировщиками как заслуживающие доверия, такие образы могут быть переведены в реестр доверенных докеров (trusted docker registry). И системный администратор может определить ``docker.trusted.registries`` и настроить частный сервер docker-registry для поддержки таких доверенных образов.

Доверенные образы могут монтироваться к внешним устройствам, таким как **HDFS**, через протокол **NFS gateway** или конфигурацию **Hadoop** на уровне хоста. Если системные администраторы разрешают запись на внешние тома с помощью директивы ``docker.allow.rw-mounts``, docker-контейнер Privileged может иметь полный контроль над файлами уровня хоста в предопределенных томах.


Требования к перезапуску контейнера
-------------------------------------

При рестарте **NodeManager**, как часть процесса восстановления, удостоверяет, что контейнер все еще запущен, проверив наличие PID-каталога контейнера в файловой системе */proc*. В целях безопасности администратор операционной системы может включить параметр монтирования *hidepid* для файловой системы */proc*. Если опция включена, основную YARN-группу пользователя необходимо внести в белый список, установив флаг монтирования *gid*, как показано далее. Иначе повторное получение контейнера (container reacquisition) завершается неудачей, и контейнер уничтожается при перезапуске **NodeManager**.

::

 proc     /proc     proc     nosuid,nodev,noexec,hidepid=2,gid=yarn     0 0


Подключение к безопасному Docker-репозиторию
---------------------------------------------

Клиентская команда Docker извлекает свою конфигурацию из местоположения по умолчанию *$HOME/.docker/config.json* на хосте **NodeManager**. В конфигурации Docker хранятся учетные данные репозитория Secure, поэтому использование **LCE** совместно с безопасными репозиториями Docker не рекомендуется.

В YARN-5428 добавлена поддержка **Distributed Shell** для безопасного предоставления конфигурации Docker-клиента.

В качестве обходного пути можно вручную зарегистрировать Docker-демон на каждом хосте **NodeManager** в безопасном репозитории, используя команду входа:

::

 docker login [OPTIONS] [SERVER]

 Register or log in to a Docker registry server, if no server is specified
 "https://index.docker.io/v1/" is the default.

 -e, --email=""       Email
 -p, --password=""    Password
 -u, --username=""    Username

.. important:: При данном подходе все пользователи имеют доступ к безопасному репозиторию


Пример: MapReduce
-------------------

В примере предполагается, что **Hadoop** установлен в */usr/local/hadoop*. А так же ``docker.allowed.ro-mounts`` в *container-executor.cfg* обновлен и содержит каталоги: */usr/local/hadoop*, */etc/passwd*, */etc/group*.

Чтобы отправить задание *pi* для запуска в docker-контейнерах, необходимо выполнить команды:

::
 
 HADOOP_HOME=/usr/local/hadoop
 YARN_EXAMPLES_JAR=$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar
 MOUNTS="$HADOOP_HOME:$HADOOP_HOME:ro,/etc/passwd:/etc/passwd:ro,/etc/group:/etc/group:ro"
 IMAGE_ID="library/openjdk:8"

 export YARN_CONTAINER_RUNTIME_TYPE=docker
 export YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE_ID
 export YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS

 yarn jar $YARN_EXAMPLES_JAR pi \
   -Dmapreduce.map.env.YARN_CONTAINER_RUNTIME_TYPE=docker \
   -Dmapreduce.map.env.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
   -Dmapreduce.map.env.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE_ID \
   -Dmapreduce.reduce.env.YARN_CONTAINER_RUNTIME_TYPE=docker \
   -Dmapreduce.reduce.env.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
   -Dmapreduce.reduce.env.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE_ID \
   1 40000


Важно обратить внимание, что application master, map tasks и reduce tasks настраиваются независимо. В данном примере используется образ *openjdk:8* для всех трех.


Пример: Spark
---------------

В примере предполагается, что **Hadoop** установлен в */usr/local/hadoop*, а **Spark** -- в */usr/local/spark*. А так же ``docker.allowed.ro-mounts`` в *container-executor.cfg* обновлен и содержит каталоги: */usr/local/hadoop*, */etc/passwd*, */etc/group*.

Чтобы запустить оболочку **Spark** в docker-контейнерах, необходимо выполнить команды:

::

 HADOOP_HOME=/usr/local/hadoop
 SPARK_HOME=/usr/local/spark
 MOUNTS="$HADOOP_HOME:$HADOOP_HOME:ro,/etc/passwd:/etc/passwd:ro,/etc/group:/etc/group:ro"
 IMAGE_ID="library/openjdk:8"

 $SPARK_HOME/bin/spark-shell --master yarn \
   --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
   --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE_ID \
   --conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS \
   --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker \
   --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$IMAGE_ID \
   --conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_MOUNTS=$MOUNTS

Важно обратить внимание, что application master и executors настраиваются независимо. В данном примере используется образ *openjdk:8* для обоих.


Поддержка ENTRYPOINT Docker-контейнера
---------------------------------------

В **Hadoop 2.x** введена поддержка Docker, платформа разработана для запуска существующих программ **Hadoop** внутри docker-контейнера, перенаправление журнала и настройка среды интегрированы с **Node Manager**. В **Hadoop 3.x** поддержка  Docker выходит за рамки выполнения рабочей нагрузки **Hadoop** и поддерживает Docker-контейнер в собственной форме Docker, используя *ENTRYPOINT* из *dockerfile*. Приложение может принять поддержку режима *YARN* или режима *Docker* по умолчанию, задав переменную среды ``YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE``. Системный администратор также может установить для кластера настройку по умолчанию, чтобы сделать *ENTRY_POINT* в качестве режима работы по умолчанию.

В *yarn-site.xml* необходимо добавить ``YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE`` в белый список среды **Node Manager**:

::

 <property>
        <name>yarn.nodemanager.env-whitelist</name>
         <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME,YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE</value>
 </property>


В *yarn-env.sh* определить:

::

 export YARN_CONTAINER_RUNTIME_DOCKER_RUN_OVERRIDE_DISABLE=true


