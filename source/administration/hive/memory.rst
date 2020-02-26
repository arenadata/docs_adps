Настройка памяти для Hive/Tez
=============================

Для корректной работы Hive/Tez, требуется задать соотетствующие значения для tez.am.resource.memory.mb, hive.tez.container.size, hive.tez.java.opts.

* ``tez.am.resource.memory.mb`` -- должно быть равно yarn.scheduler.minimum-allocation-mb
* ``hive.tez.container.size`` -- 1x или 2x yarn.scheduler.minimum-allocation-mb, но не более yarn.scheduler.maximum-allocation-mb

Нужно учитывать также, если у вас 256GB и 16 ядер, размер контейнера не должен быть больше 16GB.

Далее задать tez.runtime.io.sort.mb, tez.runtime.unordered.output.buffer.size-mb, hive.auto.convert.join.noconditionaltask.size

* ``tez.runtime.io.sort.mb`` -- как 40% от hive.tez.container.size. Редко более 2ГБ
* ``hive.auto.convert.join.noconditionaltask`` -- true
* ``hive.auto.convert.join.noconditionaltask.size`` -- 1/3 от hive.tez.container.size
* ``tez.runtime.unordered.output.buffer.size-mb`` -- до 10% от hive.tez.container.size

* ``tez.grouping.min-size=16777216`` -- около 16 MB минимальный сплит
* ``tez.grouping.max-size=1073741824`` -- около 1 ГБ максимальный сплит
