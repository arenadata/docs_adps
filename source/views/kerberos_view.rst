Настройка Kerberos для Files View
---------------------------------

Перед настройкой Kerberos для Files View, необходимо сначала настроить Kerberos для Ambari, настроив для демона Ambari Server принципал Kerberos и таблицу ключей.

После настройки Kerberos для Ambari в разделе Settings настраиваемого View введите следующие свойства:

.. csv-table::
   :header: "Параметр", "Описание", "Значение"
   :widths: 33, 33, 33

   "WebHDFS Username", "Имя пользователя, под которым View будет обращаться к HDFS.", "``${username}``"
   "WebHDFS Authorization", "Строка аутентификации для доступа к WebHDFS", "``auth=KERBEROS;proxyuser=ambari-server``"

При настройке Kerberos настройка прокси-пользователя должна быть основным значением принципала Kerberos для Ambari Server. Например, если вы настроили сервер Ambari для приницпала ``ambari-server@EXAMPLE.COM``, то это значение будет ``ambari-server``.
