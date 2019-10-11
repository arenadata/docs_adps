Import Checkpoint
==================

В случае потери всех копий образа и файлов правок в NameNode может быть импортирована последняя контрольная точка. Для этого необходимо:

* Создать пустой каталог, указанный в переменной конфигурации *dfs.namenode.name.dir*;
* Указать местоположение каталога контрольных точек в переменной конфигурации *dfs.namenode.checkpoint.dir*;
* Запустить NameNode с параметром ``-importCheckpoint``.

При этом NameNode загружает контрольную точку из каталога *dfs.namenode.checkpoint.dir*, а затем сохраняет ее в каталог NameNode, заданный в *dfs.namenode.name.dir*. Если в *dfs.namenode.name.dir* содержится допустимый образ, NameNode выдает сбой. NameNode проверяет согласованность изображения в *dfs.namenode.checkpoint.dir*, но не изменяет его каким-либо образом.

Пример использования приведен в главве :ref:`Checkpoint Node <usage_checkpoint>`.
