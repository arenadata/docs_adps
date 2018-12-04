Пример определения сервиса
===========================


При настройке каждого сервиса кластера, который требуется экспонировать, важно тщательно определять их внутренние имена хостов и порты. В следующем примере используются порты по умолчанию и поддерживаемые имена сервисов.

  :: 
  
   <service>
       <role>AMBARI</role>
       <url>http://ambari-host:8080</url>
   </service>
   
   <service>
       <role>AMBARIUI</role>
       <url>http://ambari-host:8080</url>
   </service>
   
   <service>
       <role>ATLAS</role>
       <url>http://atlas-host:8443</url>
   </service>
   
   <service>
       <role>HIVE</role>
       <url>http://hive-host:10001/cliservice</url>
   </service>
   
   <service>
       <role>JOBTRACKER</role>
        <url>rpc://jobtracker-host:8050</url>
   </service>
   
   <service
       <role>NAMENODE</role>
        <url>hdfs://namenode-host:8020</url>
   </service>
   
   <service>
       <role>OOZIE</role>
       <url>http://oozie-host:11000/oozie</url>
   </service>
   
   <service>
       <role>RANGER</role>
       <url>http://ranger-host:6080</url>
   </service>
   
   <service>
       <role>RANGERUI</role>
       <url>http://ranger-host:6080</url>
   </service>
   
   <service>
       <role>RESOURCEMANAGER</role>
       <url>http://hive-host:8088/ws</url>
   </service>
   
   <service>
       <role>WEBHBASE</role>
       <url>http://webhbase-host:60080</url>
   </service>
   
   <service>
       <role>WEBHCAT</role>
       <url>http://webcat-host:50111/templeton</url>
   </service>
   
   <service>
       <role>WEBHDFS</role>
       <url>http://webhdfs-host:50070/webhdfs</url>
   </service>
   
   <service>
       <role>ZEPPELINUI</role>
       <url>http://zeppelin-host:9995</url>
   </service>
   
   <service>
       <role>ZEPPELINWS</role>
       <url>http://zeppelin-host:9995/ws</url>
   </service>
