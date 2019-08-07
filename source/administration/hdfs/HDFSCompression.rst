HDFS Compression
=================

В главе описывается настройка **HDFS Compression** на **Linux**.

**Linux** поддерживает **GzipCodec**, **DefaultCodec**, **BZip2Codec**, **LzoCodec** и **SnappyCodec**. Как правило, для **HDFS Compression** используется **GzipCodec**. 

Существует два варианта использования **GzipCodec**:

1. GzipCodec для одноразовых заданий:

::

 hadoop jar hadoop-examples-1.1.0-SNAPSHOT.jar sort sbr"-Dmapred.compress.map.output=true" sbr"-Dmapred.map.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec"sbr "-Dmapred.output.compress=true" sbr"-Dmapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec"sbr -outKey org.apache.hadoop.io.Textsbr -outValue org.apache.hadoop.io.Text input output 
  
  
2. GzipCodec в качестве сжатия по умолчанию:  

+ Отредактировать файл *core-site.xml* на главной машине NameNode:

::

 <property>
   <name>io.compression.codecs</name>    <value>org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,com.hadoop.compression.lzo.LzoCodec,org.apache.hadoop.io.compress.SnappyCodec</value>
   <description>A list of the compression codec classes that can be used for compression/decompression.</description>
 </property>


+ Изменить файл *mapred-site.xml* на главной машине JobTracker:

::    

 <property>
   <name>mapred.compress.map.output</name>
   <value>true</value>
 </property>  
  
 <property>     
    <name>mapred.map.output.compression.codec</name>
    <value>org.apache.hadoop.io.compress.GzipCodec</value>   
 </property> 
   
 <property>     
    <name>mapred.output.compression.type</name>        
    <value>BLOCK</value>
 </property> 
 
      
+ (Опционально) Задать следующие два параметра конфигурации для включения сжатия задания. Изменить файл *mapred-site.xml* на главной машине Resource Manager:

::

 <property>     
   <name>mapred.output.compress</name>
   <value>true</value>   
 </property>   
 
 <property>     
    <name>mapred.output.compression.codec</name>
    <value>org.apache.hadoop.io.compress.GzipCodec</value>   
 </property> 
      

+ Перезапустить кластер.   


