Аутентификация Apache Shiro для Apache Zeppelin
================================================

+ `Обзор`_
+ `Настройка безопасности`_
+ `Группы и разрешения (опционально)`_
+ `Настройка Realm (опционально)`_
  
  + `Active Directory`_
  + `LDAP`_
  + `РАМ`_
  + `ZeppelinHub`_

+ `Безопасность Cookie в сессиях Zeppelin (опционально)`_
+ `Защита информации Zeppelin (опционально)`_
+ `Альтернативные методы аутентификации`_


Обзор
--------

`Apache Shiro <http://shiro.apache.org/>`_ -- это мощный и простой в использовании **Java** фреймворк безопасности, плозволяющий  выполнить аутентификацию, авторизацию, криптографию и управление сессиями. В данном разделе объясняется, как **Shiro** работает для аутентификации на сервер **Zeppelin**.

При подключении к **Apache Zeppelin** необходимо ввести учетные данные. После входа в систему появляется доступ ко всем блокнотам, включая блокноты других пользователей.


Настройка безопасности
-----------------------
  
Настройка аутентификации на сервер **Zeppelin** осуществляется несколькими простыми шагами:
  
**1. Права Shiro**

По умолчанию в *conf* находится файл *shiro.ini.template*. Данный файл используется в качестве примера, и настоятельно рекомендуется создать файл *shiro.ini*, выполнив следующую команду:

  :command:`cp conf/shiro.ini.template conf/shiro.ini`

Дополнительная информация о формате файла *shiro.ini* находится по ссылке `Shiro Configuration <http://shiro.apache.org/configuration.html#Configuration-INISections>`_.


**2. Безопасность канала Websocket**

Для свойства *zeppelin.anonymous.allowed* необходимо установить значение *false* в *conf/zeppelin-site.xml*. В случае если данного файла  нет, следует просто скопировать файл *conf/zeppelin-site.xml.template* в *conf/zeppelin-site.xml*.


**3. Запуск Zeppelin**

Для запуска **Zeppelin** необходимо выполнить команду:

  :command:`bin/zeppelin-daemon.sh start (or restart)`

После чего можно обратиться к **Zeppelin** по адресу *http://localhost:8080*. 


**4. Авторизация**

Теперь можно войти в систему, используя комбинацию имени и пароля пользователя (:numref:`Рис.%s.<zeppelin_authentication_login>`).

.. _zeppelin_authentication_login:

.. figure:: ../../imgs/zeppelin_authentication_login.*
   :align: center

   Авторизация в Apache Zeppelin

После пароля через запятую можно указать роли для каждого пользователя:

   ::
   
    [users]

    admin = password1, admin
    user1 = password2, role1, role2
    user2 = password3, role3
    user3 = password4, role2



Группы и разрешения (опционально)
----------------------------------

Для использования групп пользователей и прав для них необходимо применить одну из нижеприведенных конфигураций для **LDAP** или **AD** в разделе *[main]* в файле *shiro.ini*:

   ::
    
    activeDirectoryRealm = org.apache.zeppelin.realm.ActiveDirectoryGroupRealm
    activeDirectoryRealm.systemUsername = userNameA
    activeDirectoryRealm.systemPassword = passwordA
    activeDirectoryRealm.searchBase = CN=Users,DC=SOME_GROUP,DC=COMPANY,DC=COM
    activeDirectoryRealm.url = ldap://ldap.test.com:389
    activeDirectoryRealm.groupRolesMap = "CN=aGroupName,OU=groups,DC=SOME_GROUP,DC=COMPANY,DC=COM":"group1"
    activeDirectoryRealm.authorizationCachingEnabled = false
    activeDirectoryRealm.principalSuffix = @corp.company.net

    ldapRealm = org.apache.zeppelin.server.LdapGroupRealm
    # search base for ldap groups (only relevant for LdapGroupRealm):
    ldapRealm.contextFactory.environment[ldap.searchBase] = dc=COMPANY,dc=COM
    ldapRealm.contextFactory.url = ldap://ldap.test.com:389
    ldapRealm.userDnTemplate = uid={0},ou=Users,dc=COMPANY,dc=COM
    ldapRealm.contextFactory.authenticationMechanism = simple


И определить роли/группы, которые необходимо иметь в системе, например:

   ::
    
    [roles]
    admin = *
    hr = *
    finance = *
    group1 = *


Настройка Realm (опционально)
------------------------------

**Realms** отвечают за аутентификацию и авторизацию в **Apache Zeppelin**. По умолчанию **Apache Zeppelin** использует `IniRealm <https://shiro.apache.org/static/latest/apidocs/org/apache/shiro/realm/text/IniRealm.html>`_ (пользователи и группы настраиваются в файле *conf/shiro.ini* в разделах *[user]* и *[group]*). Также можно использовать **Shiro Realms**, такие как `JndiLdapRealm <https://shiro.apache.org/static/latest/apidocs/org/apache/shiro/realm/ldap/JndiLdapRealm.html>`_, `JdbcRealm <https://shiro.apache.org/static/latest/apidocs/org/apache/shiro/realm/jdbc/JdbcRealm.html>`_ или `создать собственный <https://shiro.apache.org/static/latest/apidocs/org/apache/shiro/realm/AuthorizingRealm.html>`_. Подробная документация о **Apache Shiro Realm** представлена по `ссылке <http://shiro.apache.org/realm.html>`_.


Active Directory
^^^^^^^^^^^^^^^^^

   ::
   
    activeDirectoryRealm = org.apache.zeppelin.realm.ActiveDirectoryGroupRealm
    activeDirectoryRealm.systemUsername = userNameA
    activeDirectoryRealm.systemPassword = passwordA
    activeDirectoryRealm.hadoopSecurityCredentialPath = jceks://file/user/zeppelin/conf/zeppelin.jceks
    activeDirectoryRealm.searchBase = CN=Users,DC=SOME_GROUP,DC=COMPANY,DC=COM
    activeDirectoryRealm.url = ldap://ldap.test.com:389
    activeDirectoryRealm.groupRolesMap = "CN=aGroupName,OU=groups,DC=SOME_GROUP,DC=COMPANY,DC=COM":"group1"
    activeDirectoryRealm.authorizationCachingEnabled = false
    activeDirectoryRealm.principalSuffix = @corp.company.net


Кроме того, вместо указания *systemPassword* в виде текста в *shiro.ini* администратор может указать то же самое, что и в *hadoop credential*. Необходимо создать keystore-файл, используя командную строку *hadoop credential*, для этого *hadoop* должен быть прописан в *classpath*:

   ::
   
    hadoop credential create activeDirectoryRealm.systempassword -provider jceks://file/user/zeppelin/conf/zeppelin.jceks

Далее следует изменить следующие значения в файле *Shiro.ini* и раскомментировать строку:

   ::
   
    activeDirectoryRealm.hadoopSecurityCredentialPath = jceks://file/user/zeppelin/conf/zeppelin.jceks


LDAP
^^^^^

Для настройки **LDAP Realm** существует два способа. Проще использовать **LdapGroupRealm**. Однако, он менее гибкий при настройке соответствий между группами **LDAP** и пользователями, а также для авторизации групп пользователей. Далее приведен пример файла с соответствующими настройками:

   ::
   
    ldapRealm = org.apache.zeppelin.realm.LdapGroupRealm
    # search base for ldap groups (only relevant for LdapGroupRealm):
    ldapRealm.contextFactory.environment[ldap.searchBase] = dc=COMPANY,dc=COM
    ldapRealm.contextFactory.url = ldap://ldap.test.com:389
    ldapRealm.userDnTemplate = uid={0},ou=Users,dc=COMPANY,dc=COM
    ldapRealm.contextFactory.authenticationMechanism = simple

Другим более гибким способом является использование **LdapRealm**. Он позволяет сопоставлять *ldapgroups* с ролями, а также допускает проверку подлинности на основе ролей/групп на сервере *zeppelin*. Пример конфигурации приведен ниже:

   ::
   
    ldapRealm=org.apache.zeppelin.realm.LdapRealm

    ldapRealm.contextFactory.authenticationMechanism=simple ldapRealm.contextFactory.url=ldap://localhost:33389  ldapRealm.userDnTemplate=uid={0},ou=people,dc=hadoop,dc=apache,dc=org

**Возможность задать параметр ldap paging. Размер по умолчанию - 100**

   ::
    
    ldapRealm.pagingSize = 200 ldapRealm.authorizationEnabled=true ldapRealm.contextFactory.systemAuthenticationMechanism=simple ldapRealm.searchBase=dc=hadoop,dc=apache,dc=org ldapRealm.userSearchBase = dc=hadoop,dc=apache,dc=org ldapRealm.groupSearchBase = ou=groups,dc=hadoop,dc=apache,dc=org ldapRealm.groupObjectClass=groupofnames

**Возможность  настройки параметра userSearchAttribute**

   ::
    
    ldapRealm.userSearchAttributeName = sAMAccountName ldapRealm.memberAttribute=member

**Возврат имен пользователей из ldap в ниженем регистре  для использования в AD**

   ::
    
    ldapRealm.userLowerCase = true

**Возможность установить парметр searchScopes в одно из трех значений: subtree (по умолчанию), one или base**

   ::
    
    ldapRealm.userSearchScope = subtree; ldapRealm.groupSearchScope = subtree; ldapRealm.memberAttributeValueTemplate=cn={0},ou=people,dc=hadoop,dc=apache,dc=org ldapRealm.contextFactory.systemUsername=uid=guest,ou=people,dc=hadoop,dc=apache,dc=org ldapRealm.contextFactory.systemPassword=S{ALIAS=ldcSystemPassword}

**Включение поддержки вложенных групп при помощи оператора LDAPMATCHINGRULEINCHAIN**

   ::
    
    ldapRealm.groupSearchEnableMatchingRuleInChain = true

**Дополительная настройка соответствий между физическими группами и  логическими ролями приложений**

   ::
    
    ldapRealm.rolesByGroup = LDNUSERS: userrole, NYKUSERS: userrole, HKGUSERS: userrole, GLOBALADMIN: adminrole

**Дополнительный список ролей, которым разрешена аутентификация. В случае если список не представлен, всем ролям разрешается аутентификация (вход)**

**Данные изменения не влияют на специфические права url. Для url будут работать те права, котрые указаны в разделе [urls]**

   ::
    
    ldapRealm.allowedRolesForAuthentication = adminrole,userrole ldapRealm.permissionsByRole= userrole = :ToDoItemsJdo::, *:ToDoItem::*; adminrole = * securityManager.sessionManager = $sessionManager securityManager.realms = $ldapRealm ```


РАМ
^^^^^

Поддержка аутентификации с помощью `PAM <https://en.wikipedia.org/wiki/Pluggable_authentication_module>`_ позволяет повторно использовать существующие модули аутентификации в узле, где запущен **Zeppelin**. В типичных системных модулях, например, *sshd*, *passwd* и других сервис настраивается в */etc/pam.d/*. Можно повторно использовать один из этих сервисов или создать свой собственный для **Zeppelin**. Для активации аутентификации **PAM** требуется два параметра: 1 -- realm: использование **Shiro realm**; 2 -- service: настроенный в */etc/pam.d/* сервис. Название должно совпадать с именем файла в */etc/pam.d/*.

   ::
    
    [main]
     pamRealm=org.apache.zeppelin.realm.PamRealm
     pamRealm.service=sshd


ZeppelinHub
^^^^^^^^^^^^^

`ZeppelinHub <https://www.zeppelinhub.com/>`_ -- это сервис, синхронизурующий блокноты **Apache Zeppelin** и обеспечивающий легкое взаимодействие с ними. Для подключения **ZeppelinHub** необходимо применить следующее изменение в *conf/shiro.ini* в разделе *[main]*:

   ::
    
    ### A sample for configuring ZeppelinHub Realm
    zeppelinHubRealm = org.apache.zeppelin.realm.ZeppelinHubRealm
    ## Url of ZeppelinHub
    zeppelinHubRealm.zeppelinhubUrl = https://www.zeppelinhub.com
    securityManager.realms = $zeppelinHubRealm

.. important:: ZeppelinHub не относится к проекту Apache Zeppelin


Безопасность Cookie в сессиях Zeppelin (опционально)
------------------------------------------------------

**Zeppelin** может быть настроен выставлением флага **HttpOnly** в настройка **cookie** для сессии. С такой конфигурацией cookie-файлы **Zeppelin** не могут быть доступны через скрипты на стороне клиента, тем самым предотвращая большинство атак типа **Cross-Site scripting** (**XSS**).

Чтобы включить безопасную поддержку файлов **cookie** через **Shiro**, необходимо добавить следующие строки в *conf/shiro.ini* в раздел *[main]*, а затем задать *sessionManager*:

   ::
    
    cookie = org.apache.shiro.web.servlet.SimpleCookie
    cookie.name = JSESSIONID
    cookie.secure = true
    cookie.httpOnly = true
    sessionManager.sessionIdCookie = $cookie


Защита информации Zeppelin (опционально)
------------------------------------------

По умолчанию любой пользователь, определенный в *[users]*, может видеть информацию об интерпретаторах, учетных данных и настройках в **Apache Zeppelin**. В случае если данную информацию необходимо скрыть, поскольку **Shiro** обеспечивает защиту на уровне url, следует закомментировать или раскомментировать приведенные ниже строки в *conf/shiro.ini*:

   ::
   
    [urls]

    /api/interpreter/** = authc, roles[admin]
    /api/configurations/** = authc, roles[admin]
    /api/credential/** = authc, roles[admin]

В таком случае информацию об интерпретаторах, учетных данных и настройках в **Apache Zeppelin** могут видеть только пользователи с ролью *admin*. При необходимости предоставления прав другим пользователям следует изменить роли в разделе *[users]*.


Альтернативные методы аутентификации
---------------------------------------

`HTTP аутентификация с помощью NGINX <https://zeppelin.apache.org/docs/0.7.3/security/authentication.html>`_
