Руководство администратора по WebHDFS
=====================================

.. |br| raw:: html

   <br />

Для настройки **WebHDFS** необходимо использовать следующие настройки:

+ Настроить WebHDFS. Добавить в файл *hdfs-site.xml* следующее свойство:
  ::
   <property>
    <name>dfs.webhdfs.enabled</name>
    <value>true</value>
   </property>

+ (Опционально) При запуске защищенного кластера выполнить следующие действия:

  + Создать пользователя-принципала сервиса HTTP, используя команду:
     
     :command:`kadmin: addprinc -randkey HTTP/$<Fully_Qualified_Domain_Name>@$<Realm_Name>.COM`

     где *Fully_Qualified_Domain_Name* - хост, на котором развертывается NameNode; |br| 
     *Realm_Name* - название сферы Kerberos.

  + Создать файлы *keytab* для принципалов HTTP:
      
      :command:`kadmin: xst -norandkey -k /etc/security/spnego.service.keytab HTTP/$<Fully_Qualified_Domain_Name>`
      
  + Убедиться, что файл *keytab* и принципал связаны с необходимым сервисом:
     
      :command:`klist –k -t /etc/security/spnego.service.keytab`
      
  + Добавить в файл *hdfs-site.xml* следующие свойства:
    ::
     <property>
       <name>dfs.web.authentication.kerberos.principal</name>
       <value>HTTP/$<Fully_Qualified_Domain_Name>@$<Realm_Name>.COM</value>
     </property>
     <property>
       <name>dfs.web.authentication.kerberos.keytab</name>
       <value>/etc/security/spnego.service.keytab</value>
     </property>
      
     где *Fully_Qualified_Domain_Name* - хост, на котором развертывается NameNode; |br| 
     *Realm_Name* - название сферы Kerberos.

+ Перезапустить сервисы NameNode и DataNode с помощью соответствующих команд.














