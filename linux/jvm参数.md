jvm参数说明：
一般将堆的总大小的50%到60%分配给新生成的池
空余堆内存小于40%时,JVM就会增大堆直到-Xmx的最大限制
空余堆内存大于70%时,JVM会减少堆直到-Xms的最小限制

-server     第一个参数,启用JDK的server版本,在多个CPU时性能佳
-Xms512m		java Heap初始分配的内存大小,默认物理内存的1/64
-Xmx512m		java Heap最大分配的内存大小,默认物理内存的1/4。建议设为物理内存的80%,不可超过物理内存
-Xmn        java Heap最小值,一般设置为Xmx的1/4

非堆内存分配(内存的永久保存区)
-XX:PermSize=256m     设定非堆内存初始值,缺省值为64M
-XX:MaxPermSize=512m	设定最大非堆内存的大小,缺省值为64M

-XX:SurvivorRatio=2     生还者池的大小,默认是2
-XX:NewSize             新生成的池的初始大小,缺省值为2M
-XX:MaxNewSize          新生成的池的最大大小,缺省值为32M
+XX:AggressiveHeap		  让jvm忽略Xmx参数,疯狂地吃完1G物理内存,再吃尽1G的swap
-Xss256k                每个线程的Stack大小,建议256k,不然容易造成不够用,特别是程序有比较多的递归行为,比如排序
-verbose:gc             现实垃圾收集信息
-Xloggc:gc.log          指定垃圾收集日志文件
-XX:+UseParNewGC        缩短minor收集的时间
-XX:+UseConcMarkSweepGC	缩短major收集的时间
-XX:userParNewGC 		    可用来设置并行收集(多CPU)
-XX:ParallelGCThreads	  可用来增加并行度(多CPU)
-XX:UseParallelGC		    设置后可以使用并行清除收集器(多CPU)

-XX:+UseConcMarkSweepGC
-XX:CMSInitiatingOccupancyFraction=75
说明：jvm默认老年代采用的是串行回收器,回收效率慢,现在改为并行回收,提高程序的相应速度,并设置触发回收点
