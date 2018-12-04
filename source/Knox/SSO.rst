Настройка Knox SSO для Ambari
===============================


В разделе описывается, как настроить **Ambari** на использование в шлюзе **Knox** технологии единого входа для аутентифицированного пользователя (SSO, Single Sign-on). При такой конфигурации не прошедшие проверку подлинности пользователи, которые пытаются получить доступ к **Ambari**, перенаправляются на страницу авторизации.

Настройка **Knox SSO** для **Ranger** выполняется следующими действиями:

1. Выполнить вход в систему под пользователем *root*.

2. Выполнить команду:

  ::
  
   ambari-server setup-sso

3. На выпадающий запрос ответить *y*.

4. Ввести URL-адрес:

  ::
  
   https://<hostname>:8443/gateway/knoxsso/api/v1/websso

5. Выполнить следующую команду CLI для экспорта сертификата **Knox**:

  ::
  
   JAVA_HOME/bin/keytool -export -alias gateway-identity -rfc -file <cert.pem> -keystore /usr/hdp/current/knox-server/data/security/keystores/gateway.jks

При появлении запроса ввести пароль мастера **Knox**. Обратить внимание на место сохранения файла *cert.pem*.

6. При появлении запроса на настройку дополнительных свойств ответить *n*.

7. Оставить поля *JWT Cookie name (hadoop-jwt)* и *JWT audiences list* пустыми. Запрос возвращает успешное завершение *Ambari Server 'setup-sso' completed successfully*.

8. Перезапустить **Ambari Server**: ``ambari-server restart``.


Пример Knox SSO для Ambari
-----------------------------

  ::
  
   ambari-server setup-sso
   Setting up SSO authentication properties...
   Do you want to configure SSO authentication [y/n] (y)?y
   Provider URL [URL] (http://example.com):https://c6402.ambari.apache.org:8443/gateway/knoxsso/api/v1/websso
   Public Certificate pem (empty) (empty line to finish input):
   MIICYTCCAcqgAwIBAgIIHd3j94bX9IMwDQYJKoZIhvcNAQEFBQAwczELMAkGA1UEBhMCVVMxDTAL
   BgNVBAgTBFRlc3QxDTALBgNVBAcTBFRlc3QxDzANBgNVBAoTBkhhZG9vcDENMAsGA1UECxMEVGVz
   dDEmMCQGA1UEAxMda25veHNzby1za29uZXJ1LTItMi5ub3ZhbG9jYWwwHhcNMTYwMzAxMTEzMTQ0
   WhcNMTcwMzAxMTEzMTQ0WjBzMQswCQYDVQQGEwJVUzENMAsGA1UECBMEVGVzdDENMAsGA1UEBxME
   VGVzdDEPMA0GA1UEChMGSGFkb29wMQ0wCwYDVQQLEwRUZXN0MSYwJAYDVQQDEx1rbm94c3NvLXNr
   b25lcnUtMi0yLm5vdmFsb2NhbDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAlV0Jtd8zmzVZ
   UZRbqxXvK9MV5OYIOWTX9/FMthwr99eClHp3JdZ1x3utYr9nwdZ6fjZaUIihzu8a8SGoipbW2ZVU
   TShGZ/5VKtu96YcSAoB3VTyc3WWRDGERRs7aKAlEqnURDkQz7KRs2tvItJpBBjrTXZpHKFTOecL4
   hCkaalUCAwEAATANBgkqhkiG9w0BAQUFAAOBgQAqvPfl4fivozd+4QI4ZBohFHHvf1z4Y7+DxlY7
   iNAnjnau4W3wgwTt6CQ1B9fSx3zVTlhu2PfDJwvumBbuKuth/M+KXpG28AbKIojrL2Odlv+cftrJ
   YeJC6Qjee+5Pf2P9G2wd9fahWF+aQpr50YlMZSU+VMiTO2a2FSAXvOdjvA==
   
   Do you want to configure advanced properties [y/n] (n) ?y
   JWT Cookie name (hadoop-jwt):
   JWT audiences list (comma-separated), empty for any ():
   Ambari Server 'setup-sso' completed successfully.
   
   ambari-server restart
