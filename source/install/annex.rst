Приложение 1. Ручная настройка подключения к базе данных
--------------------------------------------------------

.. |br| raw:: html

   <br />



Если в процессе настройки сервера **Ambari** необходимо
отличное от используемого по умолчанию подключение к базе данных
следует в командной строке нажать клавишу *y*:

:command:`Enter advanced database configuration`

Если инстанс **PostgreSQL** настроен на порт, отличный от предлагаемого по
умолчанию, для настройки **Ambari** необходимо выполнить следующие шаги:


+ Открыть в текстовом редакторе конфигурационный файл PostgreSQL
  */var/lib/pgsql/data/pg_hba.conf*. Чтобы позволить пользователю *ambari*
  подключиться к базе данных, необходимо в конце файла добавить
  следующие строки:


    :command:`local all ambari md5`  |br| 
    :command:`host all ambari 0.0.0.0/0 md5` |br| 
    :command:`host all ambari ::/0 md5`
    

+ Чтобы подключить порт, выбранный не по умолчанию, следует открыть
  файл */etc/sysconfig/pgsql/postgresql* и добавить в него строку с
  номером необходимого порта. Например, чтобы подключить порт *10432*
  следует указать:


    :command:`PGPORT=10432`
    

+ Перезапустить базу данных PostgreSQL:


    :command:`service postgresql restart`
    

+ Подключиться к базе данных под *postgres* (супер-пользователь) и
  выполнить следующие настройки:


    :command:`psql -U postgres -p 10432;` |br| 
    :command:`postgres=# CREATE DATABASE ambari;` |br| 
    :command:`postgres=# CREATE USER ambari WITH ENCRYPTED PASSWORD 'bigdata';` |br| 
    :command:`postgres=# \c ambari;` |br| 
    :command:`ambari=# CREATE SCHEMA ambari AUTHORIZATION ambari;` |br| 
    :command:`ambari=# ALTER SCHEMA ambari OWNER TO ambari;` |br| 
    :command:`ambari=# ALTER ROLE ambari SET search_path to 'ambari','public';` |br| 
    :command:`ambari=# \q`
    
   
+ Выполнить команду установки Ambari:


    :command:`ambari-server setup --database=postgres --databasehost=localhost--databaseport=10432 --databasename=ambari --databaseusername=ambari--databasepassword=bigdata`
    

+ Чтобы убедиться, что *postgres* подключен к хосту *databasehost*,
  необходимо использовать следующую команду:

    :command:`netstat -anp | egrep <port>`
    
+ Выполнить файл *Ambari-DDL-Postgres-CREATE.sql* в PostgreSQL для
  завершения настройки:


    :command:`psql -f /var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql -U ambari -p 10432 -d ambari`
    

+ При запросе пароля необходимо ввести значение *bigdata*.
