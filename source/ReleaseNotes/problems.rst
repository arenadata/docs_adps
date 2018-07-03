Известные проблемы
------------------

*Apache HDFS:*

+ При активации NFS Gateway возможно появление ошибки "service: no such service nfs-kernel-server";
+ При активации Apache Ranger HDFS Plugin возможно появление ошибки NullPointerException при попытке чтения root директории не под поллзователем HDFS;

*Apache Oozie:*

+ Возможно возникновение ошибки при проверке сервиса (Service Check) из-за недостатка ресурсов, возникает, как правило, при установке множества сервисов на одном узле;

*Apache Hive Interactive Service:*

+ При повторном включении сервиса Hive Interactive возможно появление ошибки о невозможности установки сервиса.
