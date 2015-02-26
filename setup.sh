!/bin/bash
export JAVA_HOME=/usr/local/java
export HADOOP_PREFIX=/usr/local/hadoop
HADOOP_ARCHIVE=hadoop-2.3.0.tar.gz
JAVA_ARCHIVE=jdk-7u51-linux-x64.gz
#JAVA_ARCHIVE=java-1.7.0-openjdk-1.7.0.65-2.5.1.2.el6_5.x86_64.rpm
#yum install -y java-1.7.0-openjdk.x86_64
HADOOP_MIRROR_DOWNLOAD=https://archive.apache.org/dist/hadoop/core/hadoop-2.3.0/hadoop-2.3.0.tar.gz

RSTUDIO_SERVER=rstudio-server-0.98.1102-x86_64.rpm
PLYRMR_SRC=plyrmr_0.6.0.tar.gz
PLYRMR_SRC_DOWNLOAD=https://github.com/RevolutionAnalytics/plyrmr/releases/download/0.6.0/$PLYRMR_SRC
RMR_SRC=rmr2_3.3.1.tar.gz
RMR_SRC_DOWNLOAD=https://github.com/RevolutionAnalytics/rmr2/releases/download/3.3.1/$RMR_SRC
RHDFS_SRC=rhdfs_1.0.8.tar.gz
RHDFS_SRC_DOWNLOAD=https://github.com/RevolutionAnalytics/rhdfs/blob/master/build/$RHDFS_SRC?raw=true
	
function fileExists {
	FILE=/vagrant/resources/$1
	if [ -e $FILE ]
	then
		return 0
	else
		return 1
	fi
}

function installRlang {
	echo "install R language"
	su -c 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
	yum update
	yum install -y R
}

function installRstudioLocal {
	echo "install LOCAL R studio Server"
	yum install -y --nogpgcheck /vagrant/resources/$RSTUDIO_SERVER
}

function installRstudioRemote {
	echo "install REMOTE R studio Server"
	curl -o /home/vagrant/$RSTUDIO_SERVER -O -L http://download2.rstudio.org/$RSTUDIO_SERVER
	yum install -y --nogpgcheck $RSTUDIO_SERVER
}

function disableFirewall {
	echo "disabling firewall"
	service iptables save
	service iptables stop
	chkconfig iptables off
}

function installLocalJava {
### Doesn't work as dependencies may be needed beyond a single file
	echo "installing LOCAL oracle jdk"
	FILE=/vagrant/resources/$JAVA_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteJava {
	echo "install REMOTE open jdk"
	yum install -y java-1.7.0-openjdk.x86_64
}

function installLocalHadoop {
	echo "install hadoop from local file"
	FILE=/vagrant/resources/$HADOOP_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteHadoop {
	echo "install hadoop from remote file"
	curl -o /home/vagrant/hadoop-2.3.0.tar.gz -O -L $HADOOP_MIRROR_DOWNLOAD
	tar -xzf /home/vagrant/hadoop-2.3.0.tar.gz -C /usr/local
}

function setupJava {
	echo "setting up java"
	if fileExists $JAVA_ARCHIVE; then
		ln -s /usr/local/jdk1.7.0_51 /usr/local/java
	else
		ln -s /usr/lib/jvm/jre /usr/local/java
	fi
}

function setupHadoop {
	echo "creating hadoop directories"
	mkdir /tmp/hadoop-namenode
	mkdir /tmp/hadoop-logs
	mkdir /tmp/hadoop-datanode
	ln -s /usr/local/hadoop-2.3.0 /usr/local/hadoop
	echo "copying over hadoop configuration files"
	cp -f /vagrant/resources/core-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hdfs-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/mapred-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/slaves /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hadoop-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-daemon.sh /usr/local/hadoop/sbin
	cp -f /vagrant/resources/mr-jobhistory-daemon.sh /usr/local/hadoop/sbin
	echo "modifying permissions on local file system"
	chown -fR vagrant /tmp/hadoop-namenode
    chown -fR vagrant /tmp/hadoop-logs
    chown -fR vagrant /tmp/hadoop-datanode
	mkdir /usr/local/hadoop-2.3.0/logs
	chown -fR vagrant /usr/local/hadoop-2.3.0/logs
}

function setupEnvVars {
	echo "creating java environment variables"
	#if fileExists $JAVA_ARCHIVE; then
	#	echo export JAVA_HOME=/usr/local/jdk1.7.0_51 >> /etc/profile.d/java.sh
	#else
	#	echo export JAVA_HOME=/usr/lib/jvm/jre >> /etc/profile.d/java.sh
	#fi
	echo export JAVA_HOME=/usr/local/java >> /etc/profile.d/java.sh
	echo export PATH=\${JAVA_HOME}/bin:\${PATH} >> /etc/profile.d/java.sh
	
	echo "creating hadoop environment variables"
	cp -f /vagrant/resources/hadoop.sh /etc/profile.d/hadoop.sh
}

function setupHadoopService {
	echo "setting up hadoop service"
	cp -f /vagrant/resources/hadoop /etc/init.d/hadoop
	chmod 777 /etc/init.d/hadoop
	chkconfig --level 2345 hadoop on
}

function setupNameNode {
	echo "setting up namenode"
	/usr/local/hadoop-2.3.0/bin/hdfs namenode -format myhadoop
}

function startHadoopService {
	echo "starting hadoop service"
	service hadoop start
}

function installHadoop {
	if fileExists $HADOOP_ARCHIVE; then
		installLocalHadoop
	else
		installRemoteHadoop
	fi
}

function installEPEL {
	#wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
	yum install -y epel-release-6-8.noarch.rpm
}

function installRStudioServer {
	yum install -y openssl098e
	if fileExists $RSTUDIO_SERVER; then
		installRstudioLocal
	else
		installRstudioRemote
	fi
}

function installJava {
	if fileExists $JAVA_ARCHIVE; then
		installLocalJava
	else
		installRemoteJava
	fi
}

function initHdfsTempDir {
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -mkdir /tmp
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -chmod -R 777 /tmp
}

function setupRlibraries {
	echo "setting up R libraries"
	if fileExists $RHDFS_SRC; then
		cp -f /vagrant/resources/$RHDFS_SRC /home/vagrant/
	else
		curl -o /home/vagrant/$RHDFS_SRC -O -L $RHDFS_SRC_DOWNLOAD
	fi
	if fileExists $RMR_SRC; then
		cp -f /vagrant/resources/$RMR_SRC /home/vagrant/
	else
		curl -o /home/vagrant/$RMR_SRC -O -L $RMR_SRC_DOWNLOAD
	fi
	if fileExists $PLYRMR_SRC; then
		cp -f /vagrant/resources/$PLYRMR_SRC /home/vagrant/
	else
		curl -o /home/vagrant/$PLYRMR_SRC -O -L $PLYRMR_SRC_DOWNLOAD
	fi
	cp -f /vagrant/resources/installPkg.R /home/vagrant/
	cp -f /vagrant/resources/simpleMR.R /home/vagrant/
	cd /home/vagrant
	sudo Rscript installPkg.R
}

function checkURLExists {
	curl --ssl --stderr - -I $HADOOP_MIRROR_DOWNLOAD | grep "Not Found" > /dev/null && echo "May Fail - Not Found: " $HADOOP_MIRROR_DOWNLOAD
	curl --ssl --stderr - -I $PLYRMR_SRC_DOWNLOAD | grep "Not Found" > /dev/null && echo "May Fail - Not Found: " $PLYRMR_SRC_DOWNLOAD
	curl --ssl --stderr - -I $RMR_SRC_DOWNLOAD | grep "Not Found" > /dev/null && echo "May Fail - Not Found: " $RMR_SRC_DOWNLOAD
	curl --ssl --stderr - -I $RHDFS_SRC_DOWNLOAD | grep "Not Found" > /dev/null && echo "May Fail - Not Found: " $RHDFS_SRC_DOWNLOAD
}

checkURLExists
disableFirewall
installJava
installHadoop
setupJava
setupHadoop
setupEnvVars
setupNameNode
setupHadoopService
startHadoopService
initHdfsTempDir
installRlang 
installEPEL
setupRlibraries 
installRStudioServer 
