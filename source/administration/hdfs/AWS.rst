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





Protecting the AWS Credentials
Storing secrets with Hadoop Credential Providers
General S3A Client configuration
Retry and Recovery
Configuring different S3 buckets with Per-Bucket Configuration
How S3A writes data to S3
Metrics
Other Topics
