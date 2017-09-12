Настройка HDFS Compression
--------------------------

.. |br| raw:: html

   <br />

В данном разделе описывается, как настроить **HDFS Compression** на **Linux**.

**Linux** поддерживает **GzipCodec**, **DefaultCodec**, **BZip2Codec**, **LzoCodec** и **SnappyCodec**. Как правило, для **HDFS Compression** используется **GzipCodec**. 

Для **GzipCodec** необходимо выполнить следующие инструкции:

+ Вариант I: использовать GzipCodec для одноразовых заданий:

  :command:`hadoop jar hadoop-examples-1.1.0-SNAPSHOT.jar sort sbr"-Dmapred.compress.map.output=true" sbr"-Dmapred.map.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec"sbr "-Dmapred.output.compress=true" sbr"-Dmapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec"sbr -outKey org.apache.hadoop.io.Textsbr -outValue org.apache.hadoop.io.Text input output` |br| 
  
  |br|
  
+ Вариант II: включить GzipCodec в качестве сжатия по умолчанию:  

  + Отредактировать файл *core-site.xml* на главной машине NameNode:
  
    :command:`<property>` |br| 
      :command:`<name>io.compression.codecs</name>` |br| 
      :command:`<value>org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.` |br| 
      :command:`compress.DefaultCodec,com.hadoop.compression.lzo.LzoCodec,org.apache.` |br| 
      :command:`hadoop.io.compress.SnappyCodec</value>` |br| 
      :command:`<description>A list of the compression codec classes that can be used` |br| 
      :command:`for compression/decompression.</description>` |br| 
    :command:`</property>` |br| 
|br|
  + Изменить файл *mapred-site.xml* на главной машине JobTracker:
  
    :command:`<property>` |br| 
      :command:`<name>mapred.compress.map.output</name>` |br| 
      :command:`<value>true</value>` |br| 
    :command:`</property>`  
 |br|
    :command:`<property>` |br|     
      :command:`<name>mapred.map.output.compression.codec</name>` |br| 
      :command:`<value>org.apache.hadoop.io.compress.GzipCodec</value>` |br| 
    :command:`</property>` 
|br|  
    :command:`<property>` |br| 
      :command:`<name>mapred.output.compression.type</name>` |br|         
      :command:`<value>BLOCK</value>` |br| 
    :command:`</property>` |br| 
|br|
  + (Опционально) Задать следующие два параметра конфигурации для включения сжатия задания. Изменить файл *mapred-site.xml* на главной машине Resource Manager:
  
    :command:`<property>` |br|      
      :command:`<name>mapred.output.compress</name>` |br| 
      :command:`<value>true</value>` |br|    
    :command:`</property>`     
|br|
    :command:`<property>` |br|      
      :command:`<name>mapred.output.compression.codec</name>` |br| 
      :command:`<value>org.apache.hadoop.io.compress.GzipCodec</value>` |br|    
    :command:`</property>` |br| 
|br|
  + Перезапустить кластер.   






















