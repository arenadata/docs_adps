Настройка двухсторонней SSL аутентификации для Ambari
=======================================================

Настройка двухсторонней SSL аутентификации для **Ambari** описана на примере 3 узлов:

+ *server.local* -- ambari-server, изначальная установка;
+ *agent.local* -- ambari-agent, изначальная установка;
+ *agent2.local* -- ambari-agent, добавляется позже.


Создание сертификатов
----------------------

Для создания сертификатов необходимо выполнить следующие действия:

1. Сгенерировать сертификаты для каждого узла:

  ::
  
   > openssl genrsa -out ca.key 2048
   > openssl genrsa -out server.local.key 2048
   > openssl genrsa -out agent.local.key 2048
   > openssl genrsa -out agent2.local.key 2048

2. Сгенерировать самоподписной сертификат для УЦ:

  ::
  
   > openssl req -new -x509 -key ca.key -out ca.crt
   
Параметр *Common name* на усмотрение, не критичен для **ambari**.

3. Сгенерировать *csr* для каждого узла:

  ::
   
   > openssl req -new -key server.local.key -out server.local.csr
   > openssl req -new -key agent.local.key -out agent.local.csr
   > openssl req -new -key agent2.local.key -out agent2.local.csr
   
Параметр *Common name* важен и должен соответстовать **FQDN** узла.

4. Выпустить сертификаты на основе сгенерированных *csr*:

  ::
   
   > openssl x509 -req -in server.local.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.local.crt
   > openssl x509 -req -in agent.local.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out agent.local.crt
   > openssl x509 -req -in agent2.local.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out agent2.local.crt


Включение SSL на стороне ambari-server
---------------------------------------

Для включения SSL на стороне *ambari-server* неообходимо последовательно выполнить шаги:

1. Остановить сервер:

  ::
   
   > ambari-server stop

2. Выполнить набор команд:

  ::
   
   > scp ca.crt server.local.crt server.local.key root@server.local:/root/
   > mv /var/lib/ambari-server/keys /var/lib/ambari-server/keys.bak
   > mkdir /var/lib/ambari-server/keys
   > ambari-server setup-security (option 1 -- use crt and key from scp step)
   > openssl pkcs12 -export -in /root/server.local.crt -inkey /root/server.local.key -certfile /root/server.local.crt -name 1 -out /var/lib/ambari-server/keys/keystore.p12

При этом утилита требует пароль для шифрования keystore. Пароль также необходимо поместить в файл */var/lib/ambari-server/keys/pass.txt*:

  ::
  
   > echo "keystore_pass" > /var/lib/ambari-server/keys/pass.txt
   > keytool -importcert -alias 2 -file /root/ca.crt -keystore /var/lib/ambari-server/keys/keystore.p12 -storepass `cat /var/lib/ambari-server/keys/pass.txt`

Для того, чтобы удостовериться, что в keystore импортированы неообходимые сертификаты, а именно сертификаты *ambari-server* и УЦ, выполнить действие:

  ::
  
   > keytool -list -v -keystore /var/lib/ambari-server/keys/keystore.p12 -storepass `cat /var/lib/ambari-server/keys/pass.txt`

3. Запустить сервер:

  ::
  
   > ambari-server start


Включение двустороннего SSL шифрования
----------------------------------------

Для включения двустороннего SSL шифрования необходимо:

1. На узле с *ambari-server* выполнить команду:

  ::
  
   > ambari-server stop

После чего добавить в файл */etc/ambari-server/conf/ambari.properties* параметр: *security.server.two_way_ssl=true*.

2. На узлах *ambari-agent*:

  ::
  
   > ambari-agent stop
   > scp ca.crt agent.local.crt agent.local.key root@agent.local:/var/lib/ambari-agent/keys/

3. Стартовать *ambari-server* и *ambari-agent*:

  ::
  
   > ambari-server start
   > ambari-agent start


Добавление новых нод
---------------------

Добавление новых нод осуществляется следующим образом:

1. На новых узлах *ambari-agent* выполнить:

  ::
  
   > yum install ambari-agent
   > scp ca.crt agent2.local.crt agent2.local.key root@agent2.local:/var/lib/ambari-agent/keys/

После чего в файле */etc/ambari-agent/conf/ambari-agent.ini* изменить параметр *hostname=server.local* и запустить *ambari-agent*:

  ::
  
   > start ambari-agent

2. В UI *ambari-server* пройти процедуру `добавления нового узла <../administration/cluster.html#adh>`_, выбрав опцию *Perform manual registration on hosts and do not use SSH* и подтвердив регистрацию кнопкой *Register and confirm*.2



