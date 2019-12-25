Модуль Hadoop-AWS: интеграция с Amazon Web Services
====================================================

.. important:: В Hadoop коннекторы s3: и s3n: удалены. В качестве коннектора для данных, размещенных в S3 с Apache Hadoop, используется s3a:

Как перейти на клиент **S3A**:

1. Сохранить hadoop-aws JAR в classpath.

2. Добавить JAR-бандл aws-java-sdk-bundle.jar, который поставляется с Hadoop, в classpath.

3. Изменить ключи аутентификации:

+ ``fs.s3n.awsAccessKeyId`` --> ``fs.s3a.access.key``;

+ ``fs.s3n.awsSecretAccessKey`` --> ``fs.s3a.secret.key``;

Важно убедиться, что имена свойств верны. Для **S3A** это *fs.s3a.access.key* и *fs.s3a.secret.key* -- нельзя просто скопировать свойства **S3N** и заменить *s3n* на *s3a*.

4. Заменить все URL, которые начинаются с ``s3n://`` на ``s3a://``.

5. Удалить jets3t JAR, так как он больше не нужен.

Модуль **Apache Hadoop** -- **hadoop-aws**, обеспечивает поддержку интеграции с **AWS** (**Amazon Web Services**). 

Для включения клиента **S3A** в classpath **Apache Hadoop** по умолчанию необходимо:

1. Убедиться, что ``HADOOP_OPTIONAL_TOOLS`` в *hadoop-env.sh* включает hadoop-aws в свой список дополнительных модулей для добавления в classpath.

2. Для взаимодействия на стороне клиента можно объявить, что соответствующие JAR-файлы должны быть загружены в файл *~/.hadooprc*:

::

 hadoop_add_to_classpath_tools hadoop-aws

Параметры в этом файле не распространяются на развернутые приложения, но работают для локальных клиентов, таких как команда ``hadoop fs``.

Клиент **S3A** предлагает высокопроизводительный ввод-вывод по сравнению с хранилищем объектов **Amazon S3** и совместимыми реализациями:

+ Непосредственно читает и пишет S3-объекты;

+ Совместим со стандартными S3-клиентами;

+ Совместим с файлами, созданными более старым клиентом *s3n://* и клиентом Amazon EMR *s3://*;

+ Поддерживает партиционированную загрузку для объектов размером в несколько ГБ;

+ Предлагает высокопроизводительный режим случайного ввода-вывода для работы со столбчатыми данными, такими как файлы Apache ORC и Apache Parquet;

+ Использует Java S3 SDK от Amazon с поддержкой новейших функций S3 и схем аутентификации;

+ Поддерживает аутентификацию с помощью переменных среды, свойств конфигурации Hadoop, хранилища ключей Hadoop и ролей IAM;

+ Поддерживает конфигурацию для каждого сегмента;

+ С помощью S3Guard добавляет высокопроизводительные и согласованные операции чтения метаданных/каталогов, что обеспечивает последовательность и скорость;

+ Поддерживает S3 "Server Side Encryption" для чтения и записи: SSE-S3, SSE-KMS и SSE-C;

+ Инструментирован с метриками Hadoop;

+ Активно поддерживается сообществом открытого исходного кода.

Есть и другие Hadoop-коннекторы для S3, но только **S3A** активно поддерживается самим проектом **Hadoop**:

1. Оригинальный s3:// клиент Apache Hadoop. Больше не входит в Hadoop.

2. Клиент Amazon EMR s3://. Из команды Amazon EMR, которая активно поддерживает его.

3. Клиент файловой системы Apache Hadoop s3n:. Коннетор больше недоступен.


Начало работы
---------------

**S3A** зависит от двух JAR-файлов, а также от *hadoop-common* и его зависимостей:

+ hadoop-aws JAR;
+ aws-java-sdk-bundle JAR.

.. important:: Версии hadoop-common и hadoop-aws должны быть идентичны

Для импорта библиотеки в сборку Maven, необходимо добавить JAR **hadoop-aws** и в зависимости от сборки он вытянет совместимый JAR-файл *aws-sdk*.

JAR **hadoop-aws** не декларирует никаких зависимостей, кроме AWS SDK JAR. Это упрощает исключение/настройку JAR-зависимостей **Hadoop** в имеющихся приложениях. Зависимость *hadoop-client* или *hadoop-common* должна быть объявлена.

::

 <properties>
  <!-- Your exact Hadoop version here-->
   <hadoop.version>3.0.0</hadoop.version>
 </properties>
 
 <dependencies>
   <dependency>
     <groupId>org.apache.hadoop</groupId>
     <artifactId>hadoop-client</artifactId>
     <version>${hadoop.version}</version>
   </dependency>
   <dependency>
     <groupId>org.apache.hadoop</groupId>
     <artifactId>hadoop-aws</artifactId>
     <version>${hadoop.version}</version>
   </dependency>
 </dependencies>


Предупреждения
---------------

**Amazon S3** является примером "хранилища объектов". Чтобы добиться масштабируемости и особенно высокой доступности, **S3**, как и многие другие хранилища облачных объектов, ослабил некоторые ограничения, которые обещают классические файловые системы "POSIX".

Функция *S3Guard* пытается решить некоторые из них, но не обеспечивает этого полностью. 

#1: Несогласованность модели
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. Файлы, созданные из API-интерфейсов файловой системы Hadoop, могут быть не сразу видны.

2. Операции удаления и обновления файлов могут не сразу распространяться. Старые копии файла могут существовать в течение неопределенного периода времени.

3. Операции с каталогами: ``delete()`` и ``rename()`` реализуются с помощью рекурсивных файловых операций file-by-file. Они занимают время по меньшей мере пропорциональное количеству файлов, в течение которого могут быть видны частичные обновления. Если операции прерываются, файловая система остается в промежуточном состоянии.

#2: Имитация директорий
^^^^^^^^^^^^^^^^^^^^^^^^

Клиенты **S3A** имитируют каталоги:

1. Создание записи-заглушки после вызова ``mkdirs``, удаление ее при добавлении файла в любом месте внизу.

2. При листинге директории выполняется поиск всех объектов, путь которых начинается с пути к каталогу, и возвращает их в виде списка.

3. При переименовании каталога берется листинг и запрашивается S3 на копирование отдельных объектов в новые объекты с назначенными именами файлов.

4. При удалении каталога берется листинг и удаляются записи в пакетном режиме.

5. При переименовании или удалении каталогов берется листинг и осуществляется работа с отдельными файлами.

Некоторые из последствий:

+ В каталогах может отсутствовать время модификации. Полагающиеся на него части Hadoop могут иметь неожиданное поведение. Например, ``AggregatedLogDeletionService`` из YARN не удалит соответствующие лог-файлы;

+ Листинг директории может быть медленным. По возможности рекомендуется использовать ``listFiles(path, recursive)`` для высокопроизводительных рекурсивных списков;

+ Можно создать файлы под файлами, если очень постараться;

+ Время переименования каталога пропорционально количеству файлов в нем (прямых и косвенных) и их размеру. Копии выполняются внутри хранилища S3, поэтому время не зависит от пропускной способности клиент-S3;

+ Переименования каталога не являются атомарными: они могут частично потерпеть неудачу, и вызывающие объекты не могут безопасно полагаться на атомарные переименования как на часть алгоритма коммита;

+ Удаление каталога не является атомарным и может частично завершиться ошибкой.

Последние три проблемы всплывают при использовании **S3** в качестве непосредственного места назначения работы, в отличие от **HDFS** или другой "реальной" файловой системы.

Коммиттеры **S3A** являются единственным доступным механизмом для безопасного сохранения выходных данных запросов непосредственно в хранилище объектов **S3** через файловую систему **S3A**.

#3: Разные модели авторизации у хранилищ объектов
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Модель авторизации объектов **S3** сильно отличается от модели авторизации файлов **HDFS** и традиционных файловых систем. Клиент **S3A** просто сообщает информацию о заглушке от запрашивающего метаданные API:

+ Владелец файла указывается как текущий пользователь;

+ Файловая группа также сообщается как текущий пользователь;

+ Права доступа к каталогу указываются как *777*.

+ Права доступа к файлам указываются как *666*.

**S3A** на самом деле не применяет никаких проверок авторизации для этих заглушек. Пользователи проходят аутентификацию в S3-bucket, используя учетные данные **AWS**. Возможно, что объектные списки ACL определены для обеспечения авторизации на стороне **S3**, но это происходит полностью внутри сервиса **S3**, а не в реализации **S3A**.

#4: Ценность данных 
^^^^^^^^^^^^^^^^^^^^

Учетные данные **AWS** не только оплачивают сервисы, но и предоставляют доступ для чтения и записи данных. Любой пользователь с учетными данными может не только читать наборы данных, но и удалять их.

Крайне не рекомендуется распространять учетные данные целенаправленно или непреднамеренно через такие средства, как:

+ Регистрация в SCM любых секретных файлов конфигурации;
+ Логгирование секретных файлов конфигурации в консоли, поскольку они всегда в конечном итоге видны;
+ Определение URI файловой системы с учетными данными в URL-адресе, таком как *s3a://AK0010:secret@landsat-pds/*. В итоге все оказывается в журналах и сообщениях об ошибках.

.. important:: Если какое-либо действие было допущено, следует немедленно изменить учетные данные


Аутентификация S3
------------------

За исключением случаев взаимодействия с общедоступными сегментами **S3**, клиенту **S3A** требуются учетные данные.

Клиент поддерживает несколько механизмов аутентификации и может быть настроен относительно применяемых механизмов и их порядка использования. Также можно сконфигурировать индивидуальные реализации *com.amazonaws.auth.AWSCredentialsProvider*.

Свойства аутентификации:

::

 <property>
   <name>fs.s3a.access.key</name>
   <description>AWS access key ID.
    Omit for IAM role-based or provider-based authentication.</description>
 </property>
 
 <property>
   <name>fs.s3a.secret.key</name>
   <description>AWS secret key.
    Omit for IAM role-based or provider-based authentication.</description>
 </property>
 
 <property>
   <name>fs.s3a.aws.credentials.provider</name>
   <description>
     Comma-separated class names of credential provider classes which implement
     com.amazonaws.auth.AWSCredentialsProvider.
 
     These are loaded and queried in sequence for a valid set of credentials.
     Each listed class must implement one of the following means of
     construction, which are attempted in order:
     1. a public constructor accepting java.net.URI and
         org.apache.hadoop.conf.Configuration,
     2. a public static method named getInstance that accepts no
        arguments and returns an instance of
        com.amazonaws.auth.AWSCredentialsProvider, or
     3. a public default constructor.
 
     Specifying org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider allows
     anonymous access to a publicly accessible S3 bucket without any credentials.
     Please note that allowing anonymous access to an S3 bucket compromises
     security and therefore is unsuitable for most use cases. It can be useful
     for accessing public data sets without requiring AWS credentials.
 
     If unspecified, then the default list of credential provider classes,
     queried in sequence, is:
     1. org.apache.hadoop.fs.s3a.BasicAWSCredentialsProvider: supports
         static configuration of AWS access key ID and secret access key.
         See also fs.s3a.access.key and fs.s3a.secret.key.
     2. com.amazonaws.auth.EnvironmentVariableCredentialsProvider: supports
         configuration of AWS access key ID and secret access key in
         environment variables named AWS_ACCESS_KEY_ID and
         AWS_SECRET_ACCESS_KEY, as documented in the AWS SDK.
     3. com.amazonaws.auth.InstanceProfileCredentialsProvider: supports use
         of instance profile credentials if running in an EC2 VM.
   </description>
 </property>
 
 <property>
   <name>fs.s3a.session.token</name>
   <description>
     Session token, when using org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider
     as one of the providers.
   </description>
 </property>


Аутентификация через переменные среды AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**S3A** поддерживает настройку через `стандартные переменные среды AWS <http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment>`_.

Основные переменные среды предназначены для ключа доступа и связанного секрета:

::

 export AWS_ACCESS_KEY_ID=my.aws.key
 export AWS_SECRET_ACCESS_KEY=my.secret.key

Эти переменные среды могут использоваться для установки учетных данных аутентификации вместо свойств в конфигурации Hadoop:

::

 export AWS_SESSION_TOKEN=SECRET-SESSION-TOKEN
 export AWS_ACCESS_KEY_ID=SESSION-ACCESS-KEY
 export AWS_SECRET_ACCESS_KEY=SESSION-SECRET-KEY

Если установлена переменная среды ``AWS_SESSION_TOKEN``, аутентификация сессии с использованием "временных учетных данных безопасности" ("Temporary Security Credentials") включена. Идентификатор ключа и секретный ключ должны быть установлены для учетных данных этой конкретной сессии.

.. important:: Эти переменные среды обычно не передаются от клиента к серверу при запуске приложений YARN. Это означает, что установка переменных среды AWS при запуске приложения не позволит запущенному приложению получить доступ к ресурсам S3. Переменные среды должны каким либо образом быть установлены на хостах/процессах, где выполняется работа.


Смена провайдеров аутентификации
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Стандартный способ аутентификации -- с помощью ключа доступа и секретного ключа, используя свойства в файле конфигурации.

Клиент **S3A** придерживается следующей цепочки проверки подлинности:

1. Если данные для входа предоставляются в URI файловой системы, выводится предупреждение, а затем извлекаются имя пользователя и пароль  для ключа и секрета AWS.

2. Файлы *fs.s3a.access.key* и *fs.s3a.secret.key* ищутся в конфигурации Hadoop XML.

3. Затем ищутся `переменные среды AWS <http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment>`_.

4. Предпринимается попытка запросить сервис Amazon EC2 Instance Metadata Service для получения учетных данных, опубликованных на виртуальных машинах EC2.

**S3A** можно настроить для получения провайдеров проверки подлинности клиента из классов, которые интегрируются с **AWS SDK**, путем реализации интерфейса *com.amazonaws.auth.AWSCredentialsProvider*. Это делается путем перечисления классов реализации в порядке предпочтения в параметре конфигурации ``fs.s3a.aws.credentials.provider``.

.. important:: AWS Credential Providers отличаются от Hadoop Credential Providers. Как показано далее, Hadoop Credential Providers позволяют хранить и передавать пароли и секреты более безопасно, чем в файлах конфигурации XML. AWS Credential Providers -- это классы, которые могут использоваться Amazon AWS SDK для получения регистрации AWS из другого источника в системе, включая переменные среды, свойства JVM и файлы конфигурации

В JAR ``hadoop-aws`` есть три провайдера учетных данных **AWS**:

+ ``org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider`` -- учетные данные сессии;

+ ``org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider`` -- имя/секрет;

+ ``org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider`` -- анонимный вход.

В **Amazon SDK** также есть много провайдеров и в частности два, автоматически устанавливающихся в цепочке аутентификации:

+ ``com.amazonaws.auth.InstanceProfileCredentialsProvider`` -- учетные данные EC2 Metadata;

+ ``com.amazonaws.auth.EnvironmentVariableCredentialsProvider`` -- переменные окружения AWS.


Аутентификация EC2 IAM Metadata 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Приложения, работающие в **EC2**, могут связать роль *IAM* с виртуальной машиной и запросить у `EC2 Instance Metadata Service <http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html>`_ учетные данные для доступа к **S3**. В **AWS SDK** эта функциональность обеспечивается ``InstanceProfileCredentialsProvider``, который применяет внутреннее принудительное использование одноэлементного инстанса для предотвращения проблемы регулирования.


Использование учетных данных сессии
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Временные учетные данные безопасности (`Temporary Security Credentials <http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html>`_) можно получить в **Amazon Security Token Service**. Они состоят из ключа доступа, секретного ключа и токена сессии.

Для использования аутентификации:

1. Объявить ``org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider`` в качестве провайдера.

2. Установить ключ сессии в свойстве ``fs.s3a.session.token``, а свойства доступа и секретного ключа -- для свойств этой временной сессии.

Пример:

::

 <property>
   <name>fs.s3a.aws.credentials.provider</name>
   <value>org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider</value>
 </property>
 
 <property>
   <name>fs.s3a.access.key</name>
   <value>SESSION-ACCESS-KEY</value>
 </property>
 
 <property>
   <name>fs.s3a.secret.key</name>
   <value>SESSION-SECRET-KEY</value>
 </property>
 
 <property>
   <name>fs.s3a.session.token</name>
   <value>SECRET-SESSION-TOKEN</value>
 </property>

Срок действия учетных данных сессии фиксируется при их выдаче. После истечения этого срока действия приложение больше не может проходить аутентификацию в **AWS**.


Анонимный вход
^^^^^^^^^^^^^^^

Указание ``org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider`` разрешает анонимный доступ к общедоступным сегментам **S3** без каких-либо учетных данных:

::

 <property>
   <name>fs.s3a.aws.credentials.provider</name>
   <value>org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider</value>
 </property>

Как только это будет сделано, пропадает необходимость указывать какие-либо учетные данные в конфигурации **Hadoop** или через переменные среды.

Эту опцию можно использовать для проверки того, что хранилище объектов не разрешает доступ без аутентификации: то есть, если попытка составить список сегментов осуществляется с использованием анонимного входа, то она должна завершиться неудачей (в том случае, если сегменты явно не открыты для широкого доступа).

::

 hadoop fs -ls \
  -D fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider \
  s3a://landsat-pds/


.. important:: Разрешение анонимного доступа к сегменту S3 ставит под угрозу безопасность и поэтому не подходит для большинства случаев использования

Если список провайдеров учетных данных указан в ``fs.s3a.aws.credentials.provider``, то *Anonymous Credential provider* должен стоять последним в перечне. В противном случае провайдеры учетных данных, перечисленные после него, игнорируются.

-----------

``SimpleAWSCredentialsProvider`` -- это стандартный провайдер учетных данных, который поддерживает значения секретного ключа в ``fs.s3a.access.key`` и токена в ``fs.s3a.secret.key``. Он не поддерживает аутентификацию с учетными данными, указанными в URL-адресах.

::

 <property>
   <name>fs.s3a.aws.credentials.provider</name>
   <value>org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider</value>
 </property>


Помимо отсутствия поддержки пользователя, сведения о пароле включаются в URL файловой системы (опасная практика, которая настоятельно не рекомендуется), этот провайдер действует точно в соответствии с базовым аутентификатором, используемым в цепочке аутентификации по умолчанию.

Это означает, что цепочка аутентификации **S3A** по умолчанию может быть определена как:

::

 <property>
   <name>fs.s3a.aws.credentials.provider</name>
   <value>
   org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider,
   com.amazonaws.auth.EnvironmentVariableCredentialsProvider,
   com.amazonaws.auth.InstanceProfileCredentialsProvider
   </value>
 </property>


Защита учетных данных AWS
----------------------------

Крайне важно никогда не передавать учетные данные **AWS**. Утечка учетных данных может привести к потере всех данных. Поэтому следует:

1. Никогда не делиться секретами.

2. Никогда не передавать секреты в хранилище SCM. Помочь с этим могут `git secrets <https://github.com/awslabs/git-secrets>`_.

3. Избегать использования URL-адресов s3a, в которых есть ключ и секрет. Это опасно, поскольку секреты просачиваются в логи.

4. Никогда не включать учетные данные AWS в отчеты об ошибках, прикрепленные к ним файлы и т.п.

5. При использовании переменных среды ``AWS_``, список переменных среды одинаково уязвим.

6. Никогда не использовать учетные данные *root*, заместо этого использовать учетные записи пользователей IAM, причем каждый пользователь/приложение должны иметь свой собственный набор учетных данных.

7. Использовать разрешения IAM для ограничения прав доступа отдельных пользователей и приложений. Лучше всего это делать с помощью ролей, а не с помощью настройки отдельных пользователей.

8. Не передавать секреты приложениям/командам Hadoop в командной строке. Командная строка любой запущенной программы видна всем пользователям в Unix-системе (через ``ps``) и сохраняется в истории команд.

9. Изучить использование предполагаемых ролей IAM для управления разрешениями: определенное соединение S3A может быть выполнено с другой предполагаемой ролью и разрешениями от основной учетной записи пользователя.

10. Рассмотреть рабочий процесс, в котором пользователям и приложениям выдаются кратковременные учетные данные сессии, с настройкой S3A для их использования через ``TemporaryAWSCredentialsProvider``.

11. Иметь безопасный процесс для отмены и повторной выдачи учетных данных для пользователей и приложений. Регулярно его проверять, используя обновленные данные.

При запуске в **EC2** провайдер учетных данных инстанса IAM автоматически получает учетные данные, необходимые для доступа к сервисам **AWS** в той роли, в которой развернута виртуальная машина **EC2**. Этот провайдер включен в **S3A** по умолчанию.

Самый безопасный способ сохранить ключи входа в **AWS** в секрете от **Hadoop** -- это использовать учетные данные **Hadoop**.


Хранение секретов с помощью Hadoop Credential Providers
---------------------------------------------------------

**Hadoop Credential Provider Framework** позволяет "провайдерам учетных данных" держать секреты вне файлов конфигурации **Hadoop**, хранить их в зашифрованных файлах локально или в файловой системе **Hadoop**, включая их в запросы.

Параметры конфигурации **S3A** с конфиденциальными данными (*fs.s3a.secret.key*, *fs.s3a.access.key*, *fs.s3a.session.token* и *fs.s3a.server-side-encryption.key*) могут сохранять свои данные в двоичном файле, при этом значения считываются, когда URL-адрес файловой системы **S3A** используется для доступа к данным. Ссылка на этого поставщика учетных данных объявляется в конфигурации *hadoop*.

Следующие параметры конфигурации могут быть сохранены в хранилищах **Hadoop Credential Provider**:

::

 fs.s3a.access.key
 fs.s3a.secret.key
 fs.s3a.session.token
 fs.s3a.server-side-encryption.key
 fs.s3a.server-side-encryption-algorithm

Первые три предназначены для аутентификации, а последние два -- для шифрования. Из последних только ключ шифрования можно считать "чувствительным". Однако возможность включить алгоритм в учетные данные позволяет файлу *JCEKS* содержать все параметры, необходимые для шифрования новых данных для записи в **S3**.

Шаг 1. Создание файла учетных данных
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Файл учетных данных может быть создан в любой файловой системе **Hadoop**. При создании файла в **HDFS** или **Unix** разрешения  устанавливаются автоматически на сохранение конфиденциальности файла для читателя, хотя, несмотря на то, что права доступа к каталогу не затрагиваются, необходимо проверить, что содержащий файл каталог доступен для чтения только текущему пользователю.

::

 hadoop credential create fs.s3a.access.key -value 123 \
     -provider jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks
 
 hadoop credential create fs.s3a.secret.key -value 456 \
     -provider jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks

Можно увидеть, какие записи хранятся внутри файла учетных данных:

::

 hadoop credential list -provider jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks
 
 Listing aliases for CredentialProvider: jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks
 fs.s3a.secret.key
 fs.s3a.access.key

На этом этапе учетные данные готовы к использованию.


Шаг 2. Настройка свойства пути
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

URL-адрес провайдера должен быть задан в свойстве конфигурации ``hadoop.security.credential.provider.path`` либо в командной строке, либо в файлах конфигурации XML.

::

 <property>
   <name>hadoop.security.credential.provider.path</name>
   <value>jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks</value>
   <description>Path to interrogate for protected credentials.</description>
 </property>

Поскольку это свойство предоставляет только путь к файлу секретов, сам параметр конфигурации не является конфиденциальным элементом.

Свойство ``hadoop.security.credential.provider.path`` является глобальным для всех файловых систем и секретов. Есть еще одно свойство, ``fs.s3a.security.credential.provider.path``, в котором перечислены только провайдеры учетных данных для файловых систем **S3A**. Эти два свойства объединяются в одно со списком провайдеров в *fs.s3a*. Свойство имеет приоритет над списком *hadoop.security *(т.е. они добавляются в общий список).

::

 <property>
   <name>fs.s3a.security.credential.provider.path</name>
   <value />
   <description>
     Optional comma separated list of credential providers, a list
     which is prepended to that set in hadoop.security.credential.provider.path
   </description>
 </property>

Это было сделано для поддержки привязки различных провайдеров учетных данных для каждого сегмента без добавления альтернативных секретов в список учетных данных. Однако некоторые приложения (например, **Hive**) не позволяют пользователям динамически обновлять список провайдеров. Поскольку теперь поддерживаются секреты для каждого сегмента, лучше включать ключи для каждого сегмента в файлы *JCEKS* и другие источники учетных данных.


Использование секретов от провайдеров учетных данных
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Как только провайдер настроен в конфигурации **Hadoop**, команды *hadoop* работают точно так же, как если бы секреты были в файле XML.

::

 hadoop distcp \
     hdfs://nn1.example.com:9001/user/backup/007020615 s3a://glacier1/
 
 hadoop fs -ls s3a://glacier1/

Путь к провайдеру также можно указать в командной строке:

::

 hadoop distcp \
     -D hadoop.security.credential.provider.path=jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks \
     hdfs://nn1.example.com:9001/user/backup/007020615 s3a://glacier1/
 
 hadoop fs \
   -D fs.s3a.security.credential.provider.path=jceks://hdfs@nn1.example.com:9001/user/backup/s3.jceks \
   -ls s3a://glacier1/

Поскольку путь провайдера сам по себе не является конфиденциальным секретом, нет риска декларировать его в командной строке.


Общая конфигурация клиента S3A
-------------------------------

Все параметры клиента **S3A** настроены с префиксом ``fs.s3a``.

Клиент поддерживает конфигурацию для каждого сегмента, чтобы разные сегменты могли переопределять общие параметры. Это обычно используется для изменения конечной точки, механизмов шифрования и аутентификации сегментов, опций *S3Guard* и различных других мелких опций.

::

 <property>
   <name>fs.s3a.connection.maximum</name>
   <value>15</value>
   <description>Controls the maximum number of simultaneous connections to S3.</description>
 </property>
 
 <property>
   <name>fs.s3a.connection.ssl.enabled</name>
   <value>true</value>
   <description>Enables or disables SSL connections to S3.</description>
 </property>
 
 <property>
   <name>fs.s3a.endpoint</name>
   <description>AWS S3 endpoint to connect to. An up-to-date list is
     provided in the AWS Documentation: regions and endpoints. Without this
     property, the standard region (s3.amazonaws.com) is assumed.
   </description>
 </property>

 <property>
   <name>fs.s3a.path.style.access</name>
   <value>false</value>
   <description>Enable S3 path style access ie disabling the default virtual hosting behaviour.
     Useful for S3A-compliant storage providers as it removes the need to set up DNS for virtual hosting.
   </description>
 </property>
 
 <property>
   <name>fs.s3a.proxy.host</name>
   <description>Hostname of the (optional) proxy server for S3 connections.</description>
 </property>
 
 <property>
   <name>fs.s3a.proxy.port</name>
   <description>Proxy server port. If this property is not set
     but fs.s3a.proxy.host is, port 80 or 443 is assumed (consistent with
     the value of fs.s3a.connection.ssl.enabled).</description>
 </property>

 <property>
   <name>fs.s3a.proxy.username</name>
   <description>Username for authenticating with proxy server.</description>
 </property>

 <property>
   <name>fs.s3a.proxy.password</name>
   <description>Password for authenticating with proxy server.</description>
 </property>
 
 <property>
   <name>fs.s3a.proxy.domain</name>
   <description>Domain for authenticating with proxy server.</description>
 </property>
 
 <property>
   <name>fs.s3a.proxy.workstation</name>
   <description>Workstation for authenticating with proxy server.</description>
 </property>
 
 <property>
   <name>fs.s3a.attempts.maximum</name>
   <value>20</value>
   <description>How many times we should retry commands on transient errors.</description>
 </property>
 
 <property>
   <name>fs.s3a.connection.establish.timeout</name>
   <value>5000</value>
   <description>Socket connection setup timeout in milliseconds.</description>
 </property>

 <property>
   <name>fs.s3a.connection.timeout</name>
   <value>200000</value>
   <description>Socket connection timeout in milliseconds.</description>
 </property>
 
 <property>
   <name>fs.s3a.paging.maximum</name>
   <value>5000</value>
   <description>How many keys to request from S3 when doing
      directory listings at a time.</description>
 </property>
 
 <property>
   <name>fs.s3a.threads.max</name>
   <value>10</value>
   <description> Maximum number of concurrent active (part)uploads,
   which each use a thread from the threadpool.</description>
 </property>
 
 <property>
   <name>fs.s3a.socket.send.buffer</name>
   <value>8192</value>
   <description>Socket send buffer hint to amazon connector. Represented in bytes.</description>
 </property>

 <property>
   <name>fs.s3a.socket.recv.buffer</name>
   <value>8192</value>
   <description>Socket receive buffer hint to amazon connector. Represented in bytes.</description>
 </property>
 
 <property>
   <name>fs.s3a.threads.keepalivetime</name>
   <value>60</value>
   <description>Number of seconds a thread can be idle before being
     terminated.</description>
 </property>
 
 <property>
   <name>fs.s3a.max.total.tasks</name>
   <value>5</value>
   <description>Number of (part)uploads allowed to the queue before
   blocking additional uploads.</description>
 </property>

 <property>
   <name>fs.s3a.multipart.size</name>
   <value>100M</value>
   <description>How big (in bytes) to split upload or copy operations up into.
     A suffix from the set {K,M,G,T,P} may be used to scale the numeric value.
   </description>
 </property>
 
 <property>
   <name>fs.s3a.multipart.threshold</name>
   <value>2147483647</value>
   <description>How big (in bytes) to split upload or copy operations up into.
     This also controls the partition size in renamed files, as rename() involves
     copying the source file(s).
     A suffix from the set {K,M,G,T,P} may be used to scale the numeric value.
   </description>
 </property>
 
 <property>
   <name>fs.s3a.multiobjectdelete.enable</name>
   <value>true</value>
   <description>When enabled, multiple single-object delete requests are replaced by
     a single 'delete multiple objects'-request, reducing the number of requests.
     Beware: legacy S3-compatible object stores might not support this request.
   </description>
 </property>
 
 <property>
   <name>fs.s3a.acl.default</name>
   <description>Set a canned ACL for newly created and copied objects. Value may be Private,
     PublicRead, PublicReadWrite, AuthenticatedRead, LogDeliveryWrite, BucketOwnerRead,
     or BucketOwnerFullControl.</description>
 </property>
 
 <property>
   <name>fs.s3a.multipart.purge</name>
   <value>false</value>
   <description>True if you want to purge existing multipart uploads that may not have been
      completed/aborted correctly</description>
 </property>

 <property>
   <name>fs.s3a.multipart.purge.age</name>
   <value>86400</value>
   <description>Minimum age in seconds of multipart uploads to purge</description>
 </property>
 
 <property>
   <name>fs.s3a.signing-algorithm</name>
   <description>Override the default signing algorithm so legacy
     implementations can still be used</description>
 </property>
 
 <property>
   <name>fs.s3a.server-side-encryption-algorithm</name>
   <description>Specify a server-side encryption algorithm for s3a: file system.
     Unset by default. It supports the following values: 'AES256' (for SSE-S3), 'SSE-KMS'
      and 'SSE-C'
   </description>
 </property>

 <property>
     <name>fs.s3a.server-side-encryption.key</name>
     <description>Specific encryption key to use if fs.s3a.server-side-encryption-algorithm
     has been set to 'SSE-KMS' or 'SSE-C'. In the case of SSE-C, the value of this property
     should be the Base64 encoded key. If you are using SSE-KMS and leave this property empty,
     you'll be using your default's S3 KMS key, otherwise you should set this property to
     the specific KMS key id.</description>
 </property>
 
 <property>
   <name>fs.s3a.buffer.dir</name>
   <value>${hadoop.tmp.dir}/s3a</value>
   <description>Comma separated list of directories that will be used to buffer file
     uploads to.</description>
 </property>
 
 <property>
   <name>fs.s3a.block.size</name>
   <value>32M</value>
   <description>Block size to use when reading files using s3a: file system.
   </description>
 </property>

 <property>
   <name>fs.s3a.user.agent.prefix</name>
   <value></value>
   <description>
     Sets a custom value that will be prepended to the User-Agent header sent in
     HTTP requests to the S3 back-end by S3AFileSystem.  The User-Agent header
     always includes the Hadoop version number followed by a string generated by
     the AWS SDK.  An example is "User-Agent: Hadoop 2.8.0, aws-sdk-java/1.10.6".
     If this optional property is set, then its value is prepended to create a
     customized User-Agent.  For example, if this configuration property was set
     to "MyApp", then an example of the resulting User-Agent would be
     "User-Agent: MyApp, Hadoop 2.8.0, aws-sdk-java/1.10.6".
   </description>
 </property>
 
 <property>
   <name>fs.s3a.impl</name>
   <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
   <description>The implementation class of the S3A Filesystem</description>
 </property>
 
 <property>
   <name>fs.AbstractFileSystem.s3a.impl</name>
   <value>org.apache.hadoop.fs.s3a.S3A</value>
   <description>The implementation class of the S3A AbstractFileSystem.</description>
 </property>
 
 <property>
   <name>fs.s3a.readahead.range</name>
   <value>64K</value>
   <description>Bytes to read ahead during a seek() before closing and
   re-opening the S3 HTTP connection. This option will be overridden if
   any call to setReadahead() is made to an open stream.</description>
 </property>
 
 <property>
   <name>fs.s3a.list.version</name>
   <value>2</value>
   <description>Select which version of the S3 SDK's List Objects API to use.
   Currently support 2 (default) and 1 (older API).</description>
 </property>


Повтор и восстановление
------------------------

Клиент **S3A** прилагает все усилия для восстановления после сбоев сети.

**S3A** разделяет исключения, возвращаемые **AWS SDK**, на различные категории и выбирает другую политику повторных попыток в зависимости от их типа и того, является ли сбойная операция идемпотентной.


Неустранимые проблемы: Fail Fast
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Следующие проблемы считаются неустранимыми, **S3A** не пытается восстановить их:

+ Нет объекта/сегмента: ``FileNotFoundException``;
+ Нет прав доступа: ``AccessDeniedException``;
+ Неисправные сетевые ошибки (``UnknownHostException``, ``NoRouteToHostException``, ``AWSRedirectException``);
+ Прерывания: ``InterruptedIOException``, ``InterruptedException``;
+ Отклоненные HTTP-запросы: ``InvalidRequestException``.


Возможные проблемы восстановления: повторная попытка
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+ Время соединения вышло: ``ConnectTimeoutException``. Время ожидания перед настройкой соединения с конечной точкой S3 (или прокси-сервером);
+ Код состояния ответа HTTP 400, "Bad Request".

Код состояния 400, "Bad Request" обычно означает, что запрос не подлежит восстановлению. Но иногда восстановление возможно, поэтому проблема относится к данной категории, а не к неисправимым сбоям.

Сбои повторяются с фиксированным интервалом ожидания, установленным в ``fs.s3a.retry.interval``, до предела, установленного в ``fs.s3a.retry.limit``.


Повтор идемпотентных операций
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Некоторые сетевые сбои считаются повторяемыми, если они происходят при идемпотентных операциях; при этом нет никакого способа узнать, происходят они до или после того, как запрос обрабатывается **S3**.

+ ``SocketTimeoutException``: общий сбой сети;
+ ``EOFException``: соединение разорвано во время чтения данных;
+ "No response from Server" (443, 444) сервер не отвечает;
+ Исключение другого AWS-клиента, сервиса или S3.

Эти сбои повторяются с фиксированным интервалом ожидания, установленным в ``fs.s3a.retry.interval``, вплоть до предела, заданного в ``fs.s3a.retry.limit``.

*DELETE* считается идемпотентным, поэтому: ``FileSystem.delete()`` и ``FileSystem.rename()`` повторяют свои запросы на удаление при любом из перечисленных сбоев.

Вопрос о том, должно ли удаление быть идемпотентным, был источником исторических противоречий в **Hadoop**:

1. При отсутствии каких-либо других изменений в хранилище объектов повторный запрос *DELETE* в конечном итоге приводит к удалению именованного объекта; и при повторной обработке он не будет работать. Как, впрочем, и ``Filesystem.delete()``.
2. Если другой клиент создает файл под этим путем, он будет удален.
3. Любая файловая система, поддерживающая атомарную операцию ``FileSystem.create(path, overwrite=false)`` для отклонения создания файла при наличии существующего пути, *не должна* считать удаление идемпотентным, поскольку операция ``create(path, false)`` может стать успешной только в том случае, если первый вызов ``delete()`` уже успешно завершен.
4. Второй повторный вызов ``delete()`` может удалить новые данные.






Configuring different S3 buckets with Per-Bucket Configuration
How S3A writes data to S3
Metrics
Other Topics
