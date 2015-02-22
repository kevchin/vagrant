Sys.setenv("HADOOP_PREFIX"="/usr/local/hadoop")
Sys.setenv("HADOOP_CMD"="/usr/local/hadoop/bin/hadoop")
hdDir <- "/usr/local/hadoop/share/hadoop/tools/lib"
hds <- list.files(path=hdDir, pattern="^hadoop-streaming-.*\\.jar$")
if (length(hds) == 1) {
        hdLocation<- paste(hdDir, "/", hds, sep='')
	Sys.setenv("HADOOP_STREAMING"=hdLocation)
} else {
        cat("Error: HADOOP_STREAMING not set\n")
}
Sys.getenv("HADOOP_STREAMING")

Sys.setenv("JAVA_HOME"="/usr/lib/jvm/java-openjdk/jre")

library(plyrmr)
library(rhdfs)
library(rmr2)

hdfs.init()

# Mapreduce from rmr2
#
ints = to.dfs(1:100)
calc = mapreduce(input = ints,
                 map = function(k, v) cbind(v, 2*v))

from.dfs(calc)

# write the mtcars dataframe to Hadoop File system (serialize)
model <- mtcars
myFilename <- "mtcars.out"
# can verify hdfs file via shell: # hdfs dfs -ls /user/vagrant/mtcars.out
modelfile <- hdfs.file(myFilename, "w")
hdfs.write(model, modelfile)
hdfs.close(modelfile)

# read the mtcars dataframe from Hadoop File system (deserialize)
modelfile = hdfs.file(myFilename, "r")
m <- hdfs.read(modelfile)
model <- unserialize(m)
hdfs.close(modelfile)
