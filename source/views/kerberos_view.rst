Настройка Kerberos для представления Files
------------------------------------------

Перед настройкой Kerberos для Files View, необходимо сначала настроить Kerberos для Ambari, настроив для демона Ambari Server принципал Kerberos и таблицу ключей.

После настройки Kerberos для Ambari в разделе Files View > Settings введите следующие свойства:

.. csv-table:: Настройка Files View для Kerberos
   :header: "Параметр", "Описание", "Значение"
   :widths: 25, 25, 25

   "WebHDFS Username", "Имя пользователя, под которым представление будет обращаться к HDFS.", "${username}"
   "WebHDFS Authorization", "Строка аутентификации для доступа к WebHDFS", "auth=KERBEROS;proxyuser=ambari-server"

При настройке Kerberos настройка прокси-пользователя должна быть основным значением принципала Kerberos для Ambari Server. Например, если вы настроили сервер Ambari для приницпала ambari-server@EXAMPLE.COM, это значение будет ambari-server.
