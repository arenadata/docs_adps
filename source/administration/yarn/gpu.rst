YARN on GPU
===========

**YARN** поддерживает **NVIDIA GPU** в качестве ресурса.

.. important:: На данный момент YARN поддерживает только графические процессоры Nvidia. На все YARN NodeManagers должны быть предварительно установлены драйверы Nvidia. В случае использования Docker, необходимо установить nvidia-docker 1.0.

**Fair Scheduler** не поддерживает **Dominant Resource Calculator**. Политика *fairshare*, которую использует **Fair Scheduler**, учитывает только память для расчета *fairShare* и *minShare*, поэтому устройства **GPU** выделяются из общего пула.

Для включения поддержки **GPU** необходимо активировать раздел *advanced* и в нем параметр ``GPU on YARN`` (:numref:`Рис.%s.<gpu_switch>`).

.. _gpu_switch:

.. figure:: ../../imgs/administration/yarn/yarn_gpu_switch.png
   :align: center

   Активация GPU on YARN


Конфигурация
-------------

GPU scheduling
^^^^^^^^^^^^^^^

В *resource-types.xml* необходимо добавить следующие совйства:

::

 <configuration>
   <property>
      <name>yarn.resource-types</name>
      <value>yarn.io/gpu</value>
   </property>
 </configuration>


В *yarn-site.xml* параметр ``DominantResourceCalculator`` должен быть настроен на включение scheduling/isolation графического процессора.

Для **Capacity Scheduler** необходимо использовать свойство для настройки ``DominantResourceCalculator`` (в *capacity-scheduler.xml*):

+ свойство ``yarn.scheduler.capacity.resource-calculator``, значение по умолчанию *org.apache.hadoop.yarn.util.resource.DominantResourceCalculator*.


GPU Isolation
^^^^^^^^^^^^^^

В *yarn-site.xml* для включения модуля **GPU isolation** на стороне **NodeManager**:

::

 <property>
   <name>yarn.nodemanager.resource-plugins</name>
   <value>yarn.io/gpu</value>
 </property>

По умолчанию **YARN** автоматически определяет и настраивает графические процессоры, когда установлен вышеуказанный конфиг. Следующие настройки необходимо устанавливать в *yarn-site.xml*, только если у администратора есть особые требования для этого.

1. Разрешение GPU Devices.

+ ``yarn.nodemanager.resource-plugins.gpu.allowed-gpu-devices``, значение по умолчанию *auto*.

Необходимо указать устройства **GPU**, которыми можно управлять с помощью **YARN NodeManager** (через запятую). Количество устройств с графическим процессором сообщается **Resource Manager** для принятия решений о планировании. Значение по умолчанию *auto* приводит к автоматическому обнаруживанию **YARN** ресурса **GPU** из системы.

В случае если автоопределение не удалось или администратору необходимо подмножество устройств с графическим процессором, управляемых **YARN**, устройства **GPU** указываются вручную. Устройство **GPU** идентифицируется по его минорному номеру и индексу. Распространенным подходом для получения минорного номера устройства на графических процессорах -- это использование ``nvidia-smi -q`` и поиск по *Minor Number*.

Когда минорные номера задаются вручную, администратор должен также включать индекс графических процессоров: ``index:minor_number[,index:minor_number...]``. Например: ``0:0,1:1,2:2,3:4`` -- позволяет **YARN NodeManager** управлять устройствами **GPU** с индексами 0/1/2/3 и минорными номерами 0/1/2/4.

2. Исполняемый файл для обнаружения GPU.

+ ``yarn.nodemanager.resource-plugins.gpu.path-to-discovery-executables``, значение */absolute/path/to/nvidia-smi*.

Когда указано ``yarn.nodemanager.resource-plugins.gpu.allowed-gpu-devices=auto``, **YARN NodeManager** должен запустить бинарный файл обнаружения **GPU** (поддерживает только *nvidia-smi*), чтобы получить связанную с **GPU** информацию. Когда значение параметра пустое (по умолчанию), **YARN NodeManager** самостоятельно пытается найти исполняемый файл обнаружения. Пример значения конфигурации: */usr/local/bin/nvidia-smi*.

3. Подключаемые модули Docker.

Следующие конфигурации могут быть настроены, когда пользователю необходимо запустить приложения **GPU** внутри Docker-контейнера. Данные действия не требуются, если администратор следует установке и настройке *nvidia-docker* по умолчанию.

+ ``yarn.nodemanager.resource-plugins.gpu.docker-plugin``, значение по умолчанию *nvidia-docker-v1*.

Необходимо указать плагин команды docker для **GPU**. По умолчанию используется **Nvidia docker V1.0**, для *V2.x* доступен *nvidia-docker-v2*.

+ ``yarn.nodemanager.resource-plugins.gpu.docker-plugin.nvidia-docker-v1.endpoint``, значение по умолчанию *http://localhost:3476/v1.0/docker/cli*.

Необходимо указать конечную точку *nvidia-docker-plugin* (подробнее в документации `NVIDIA <https://github.com/NVIDIA/nvidia-docker/wiki>`_).

4. CGroups mount.

**GPU isolation** использует `контроллер устройств CGroup <https://www.kernel.org/doc/Documentation/cgroup-v1/devices.txt>`_ для выполнения изоляции устройства для каждого графического процессора. Следующий параметр должен быть добавлен в *yarn-site.xml* для автоматического монтирования подустройств **CGroup**, в противном случае администратору необходимо вручную создать подпапку для устройств, чтобы использовать эту функцию.

+ ``yarn.nodemanager.linux-container-executor.cgroups.mount``, значение по умолчанию *true*.


-------------

В *container-executor.cfg* для включения модуля **GPU isolation** должна быть добавлена следующая конфигурация: 

::

 [gpu]
 module.enabled=true

Когда пользователю необходимо запустить приложения с графическим процессором в среде, отличной от Docker:

::

 [cgroups]
 # This should be same as yarn.nodemanager.linux-container-executor.cgroups.mount-path inside yarn-site.xml
 root=/sys/fs/cgroup
 # This should be same as yarn.nodemanager.linux-container-executor.cgroups.hierarchy inside yarn-site.xml
 yarn-hierarchy=yarn


Когда пользователю необходимо запустить приложения с графическим процессором в среде Docker:

+ Добавить связанные с GPU устройства в docker-раздел (разделенные запятой значения, которые можно получить, запустив */dev/nvidia*):

::

 [docker]
 docker.allowed.devices=/dev/nvidiactl,/dev/nvidia-uvm,/dev/nvidia-uvm-tools,/dev/nvidia1,/dev/nvidia0

+ Добавить nvidia-docker в белый список драйверов томов:

::

 [docker]
 ...
 docker.allowed.volume-drivers

+ Добавить *nvidia_driver_<version>* в белый список монтирования только для чтения:

::

 [docker]
 ...
 docker.allowed.ro-mounts=nvidia_driver_375.66

+ Если в качестве плагина gpu docker используется *nvidia-docker-v2*, необходимо добавить *nvidia* в белый список выполнения:

::

 [docker]
 ...
 docker.allowed.runtimes=nvidia

.. important:: В настоящее время распределенная оболочка поддерживает задание дополнительных типов ресурсов, кроме памяти и vcores


Distributed-shell + GPU without Docker
---------------------------------------

Для запуска распределенной оболочки без использования docker-контейнера (запрашивается 2 задачи, каждая имеет 3 ГБ памяти, 1 vcore, 2  устройства GPU):

::

 yarn jar <path/to/hadoop-yarn-applications-distributedshell.jar> \
   -jar <path/to/hadoop-yarn-applications-distributedshell.jar> \
   -shell_command /usr/local/nvidia/bin/nvidia-smi \
   -container_resources memory-mb=3072,vcores=1,yarn.io/gpu=2 \
   -num_containers 2

Вывод запущенного контейнера:

::

 Tue Dec  5 22:21:47 2017
 +-----------------------------------------------------------------------------+
 | NVIDIA-SMI 375.66                 Driver Version: 375.66                    |
 |-------------------------------+----------------------+----------------------+
 | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
 | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
 |===============================+======================+======================|
 |   0  Tesla P100-PCIE...  Off  | 0000:04:00.0     Off |                    0 |
 | N/A   30C    P0    24W / 250W |      0MiB / 12193MiB |      0%      Default |
 +-------------------------------+----------------------+----------------------+
 |   1  Tesla P100-PCIE...  Off  | 0000:82:00.0     Off |                    0 |
 | N/A   34C    P0    25W / 250W |      0MiB / 12193MiB |      0%      Default |
 +-------------------------------+----------------------+----------------------+
 
 +-----------------------------------------------------------------------------+
 | Processes:                                                       GPU Memory |
 |  GPU       PID  Type  Process name                               Usage      |
 |=============================================================================|
 |  No running processes found                                                 |
 +-----------------------------------------------------------------------------+


Distributed-shell + GPU with Docker
------------------------------------

Запуск распределенной оболочки с использованием docker-контейнера. Для этого должны быть заданы параметры ``YARN_CONTAINER_RUNTIME_TYPE`` и ``YARN_CONTAINER_RUNTIME_DOCKER_IMAGE``:

::

 yarn jar <path/to/hadoop-yarn-applications-distributedshell.jar> \
        -jar <path/to/hadoop-yarn-applications-distributedshell.jar> \
        -shell_env YARN_CONTAINER_RUNTIME_TYPE=docker \
        -shell_env YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=<docker-image-name> \
        -shell_command nvidia-smi \
        -container_resources memory-mb=3072,vcores=1,yarn.io/gpu=2 \
        -num_containers 2
