Архитектура развертывания Knox Gateway
=======================================

Получение доступа к кластеру **Hadoop** извне осуществляется через **Knox**, **REST API** либо через интерфейс командной строки **Hadoop**.

Следующая диаграмма показывает, как **Knox Gateway** вписывается в развертывание **Hadoop**, где *NN = NameNode*, *RM = Resource Manager*, *DN = DataNote*, *NM = NodeManager* (:numref:`Рис.%s.<ADH_Knox_architecture_deployment>`).


.. _ADH_Knox_architecture_deployment:

.. figure:: ../imgs/ADH_Knox_architecture_deployment.*
   :align: center

   Архитектура развертывания Knox в Hadoop
