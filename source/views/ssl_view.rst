Настройка SSL для Hive View
---------------------------

Перед настройкой SSL протокола для Hive View, необходимо сначала настроить Truststore для Ambari Server, импортировав все необзодимые ключи в Truststore.

После настройки SSL для Ambari в разделе Settings настраиваемого View введите следующие свойства:

.. csv-table::
   :header: "Параметр", "Описание", "Значение"
   :widths: 33, 33, 33

   "Hive Session Parameters", "Дополнительные параметры передаваемыее в рамках сессии Hive", "``sslTrustStore=/path_to_ambari_truststore/ambari_truststore_name.jks;trustStorePassword=********``"
