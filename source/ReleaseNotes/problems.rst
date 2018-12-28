Известные проблемы
------------------

*Apache HDFS:*

+ При активации NFS Gateway возможно появление ошибки "service: no such service nfs-kernel-server";

*Apache Oozie:*

+ Возможно возникновение ошибки при проверке сервиса (Service Check) из-за недостатка ресурсов, возникает, как правило, при установке множества сервисов на одном узле;

*Apache Slider:*

+ Не поддерживается корректная работа в Kerberos окружении https://issues.apache.org/jira/browse/SLIDER-993

*Apache Hive LLAP:*

+ Не поддерживается корректная работа в Kerberos окружении в связи с оганичениями Slider (SLIDER-993)

*Apache Atlas:*

+ Возможны проблемы при запуске Apache Atlas в Kerberos окружении с созданием топиков Kafka и таблицами HBase. Для решения данной проблемой воспользуйтесь следующими рекомендациями: https://support.arenadata.io/kb/faq.php?id=19
