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


Включить SSL на стороне ambari-server
---------------------------------------


2.1)
> ambari-server stop

2.2)
> scp ca.crt server.local.crt server.local.key root@server.local:/root/
> mv /var/lib/ambari-server/keys /var/lib/ambari-server/keys.bak
> mkdir /var/lib/ambari-server/keys
> ambari-server setup-security (option 1 -- use crt and key from scp step)
> openssl pkcs12 -export -in /root/server.local.crt -inkey /root/server.local.key -certfile /root/server.local.crt -name 1 -out /var/lib/ambari-server/keys/keystore.p12

Утилита потребует пароль для шифрования keystore. Этот пароль необходимо будет также поместить в файл /var/lib/ambari-server/keys/pass.txt:
> echo "keystore_pass" > /var/lib/ambari-server/keys/pass.txt
> keytool -importcert -alias 2 -file /root/ca.crt -keystore /var/lib/ambari-server/keys/keystore.p12 -storepass `cat /var/lib/ambari-server/keys/pass.txt`

Можно удостовериться, что в keystore импортированы нужные сертификаты, а именно сертификаты ambari-server и УЦ:
> keytool -list -v -keystore /var/lib/ambari-server/keys/keystore.p12 -storepass `cat /var/lib/ambari-server/keys/pass.txt`

2.3)
> ambari-server start








