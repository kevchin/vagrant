# Change the CRAN respository to something closer to you
#
local({r <- getOption("repos"); r["CRAN"] <- "http://ftp.osuosl.org/pub/cran/"; options(repos=r)})

# These R packages are dependencies for the Revolution Analytics 
# Hadoop libraries: rmr, plyrmr, rhdfs
#
install.packages(c("rJava", "Rcpp", "RJSONIO", "bitops", "digest", 
                   "functional", "stringr", "plyr", "reshape2", "dplyr", "quickcheck",
                   "R.methodsS3", "caTools", "Hmisc", "memoise", "rjson"))


cat("RScript done installing packages\n")
# The below tries to dynamically determine the name of the hadoop streaming jar file
#
hdDir <- "/usr/local/hadoop/share/hadoop/tools/lib"
hds <- list.files(path=hdDir, pattern="^hadoop-streaming-.*\\.jar$")
if (length(hds) == 1) {
        hdLocation<- paste(hdDir, "/", hds, sep='')
	Sys.setenv("HADOOP_STREAMING"=hdLocation)
} else {
        cat("Error: HADOOP_STREAMING not set\n")
}
Sys.getenv("HADOOP_STREAMING")

Sys.setenv("HADOOP_PREFIX"="/usr/local/hadoop")
Sys.setenv("HADOOP_CMD"="/usr/local/hadoop/bin/hadoop")
Sys.getenv("HADOOP_PREFIX")

Sys.setenv("JAVA_HOME"="/usr/lib/jvm/java-openjdk/jre")


cat("RScript starting installing Revolution packages\n")
cat("RScript starting RMR packages\n")
lf <- list.files(path=".", pattern="^rmr.*\\.tar\\.gz$")
if (!length(lf)==1) cat ("Error: File not found\n") else install.packages(lf, repos = NULL, type="source")

cat("RScript starting RHDFS packages\n")
lf <- list.files(path=".", pattern="^rhdfs.*\\.tar\\.gz$")
if (!length(lf)==1) cat ("Error: File not found\n") else install.packages(lf, repos = NULL, type="source")

cat("RScript starting PLYMR packages\n")
lf <- list.files(path=".", pattern="^plyrmr.*\\.tar\\.gz$")
if (!length(lf)==1) cat ("Error: File not found\n") else install.packages(lf, repos = NULL, type="source")

cat("RScript done installing Revolution packages\n")
