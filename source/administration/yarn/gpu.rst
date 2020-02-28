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
