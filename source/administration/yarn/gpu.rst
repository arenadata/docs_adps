YARN on GPU
===========

**YARN** поддерживает **NVIDIA GPU** в качестве ресурса.

.. important:: На данный момент YARN поддерживает только графические процессоры Nvidia. На все YARN NodeManagers должны быть предварительно установлены драйверы Nvidia. В случае использования Docker, необходимо установить nvidia-docker 1.0.

**The Fair Scheduler** не поддерживает **Dominant Resource Calculator**. Политика *fairshare*, которую использует **Fair Scheduler**, учитывает только память для расчета *fairShare* и *minShare*, поэтому устройства **GPU** выделяются из общего пула.

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

2. Исполняемый файл для обнаружения GPU

+ ``yarn.nodemanager.resource-plugins.gpu.path-to-discovery-executables``, значение */absolute/path/to/nvidia-smi*.

Когда указано ``yarn.nodemanager.resource-plugins.gpu.allowed-gpu-devices=auto``, **YARN NodeManager** должен запустить бинарный файл обнаружения **GPU** (поддерживает только *nvidia-smi*), чтобы получить связанную с **GPU** информацию. Когда значение параметра пустое (по умолчанию), **YARN NodeManager** самостоятельно пытается найти исполняемый файл обнаружения. Пример значения конфигурации: */usr/local/bin/nvidia-smi*.

3. Подключаемые модули Docker

Следующие конфигурации могут быть настроены, когда пользователю необходимо запустить приложения **GPU** внутри Docker-контейнера. Данные действия не требуются, если администратор следует установке и настройке *nvidia-docker* по умолчанию.

+ ``yarn.nodemanager.resource-plugins.gpu.docker-plugin``, значение по умолчанию *nvidia-docker-v1*.

Необходимо указать плагин команды docker для **GPU**. По умолчанию используется **Nvidia docker V1.0**, для *V2.x* доступен *nvidia-docker-v2*.

+ ``yarn.nodemanager.resource-plugins.gpu.docker-plugin.nvidia-docker-v1.endpoint``, значение по умолчанию *http://localhost:3476/v1.0/docker/cli*.

Необходимо указать конечную точку *nvidia-docker-plugin* (подробнее в документации `NVIDIA <https://github.com/NVIDIA/nvidia-docker/wiki>`_).

4. CGroups mount

**GPU isolation** использует `контроллер устройств CGroup <https://www.kernel.org/doc/Documentation/cgroup-v1/devices.txt>`_ для выполнения изоляции устройства для каждого графического процессора. Следующий параметр должен быть добавлен в *yarn-site.xml* для автоматического монтирования подустройств **CGroup**, в противном случае администратору необходимо вручную создать подпапку для устройств, чтобы использовать эту функцию.

+ ``yarn.nodemanager.linux-container-executor.cgroups.mount``, значение по умолчанию *true*.




