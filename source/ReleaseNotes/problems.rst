Известные проблемы
------------------

*Apache HDFS:*

+ При активации NFS Gateway возможно появление ошибки "service: no such service nfs-kernel-server";
+ При активации Apache Ranger HDFS Plugin возможно появление ошибки NullPointerException при попытке чтения root директории не под поллзователем HDFS;

*Apache Oozie:*

+ Возможно возникновение ошибки при проверке сервиса (Service Check) из-за недостатка ресурсов, возникает, как правило, при установке множества сервисов на одном узле;

*Apache Slider:*

+ Не поддерживается корректная работа в Kerberos окружении https://issues.apache.org/jira/browse/SLIDER-993

*Apache Hive LLAP:*

+ Не поддерживается корректная работа в Kerberos окружении в связи с оганичениями Slider (SLIDER-993)
