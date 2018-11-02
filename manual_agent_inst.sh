if [ ! -f /usr/sbin/zabbix/conf/zabbix_agentd.conf ]
 then
cd /root
wget http://10.101.10.129:8090/software/zabbix/zabbix-3.2.3.tar.gz
tar xvfz /root/zabbix-3.2.3.tar.gz
cd /root/zabbix-3.2.3
./configure --prefix=/usr/sbin/zabbix --enable-agent &&  make &&  make install
mv /usr/sbin/zabbix/etc /usr/sbin/zabbix/conf
cd /etc/init.d
wget http://10.101.10.129:8090/software/zabbix/agent/zabbix-agent
chmod u+x /etc/init.d/zabbix-agent
groupadd -g 9009 zabbix
useradd -u 9009 -g zabbix -G zabbix zabbix;
 
mkdir -p /usr/sbin/zabbix/logs
ln -s /usr/sbin/zabbix/sbin/zabbix_agentd  /usr/sbin/zabbix_agentd
echo "Hostname=" > /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "ListenIP="  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "ListenPort=10050"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "Include=/usr/sbin/zabbix/conf/zabbix_agentd.conf.d"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "LogFileSize=0"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "LogFile=/usr/sbin/zabbix/logs/zabbix_agentd.log"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "PidFile=/usr/sbin/zabbix/logs/zabbix_agentd.pid"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "Server=10.101.10.146,10.101.10.147,10.101.10.116,10.0.77.88"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "ServerActive=10.101.10.146,10.101.10.147,10.101.10.116,10.0.77.88"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
echo "StartAgents=3"  >> /usr/sbin/zabbix/conf/zabbix_agentd.conf
 fi

IPADDR=$(hostname -i)
sed -i "/Hostname/s/=.*$/=${IPADDR}/g"  /usr/sbin/zabbix/conf/zabbix_agentd.conf
sed -i "/ListenIP/s/=.*$/=${IPADDR}/g"  /usr/sbin/zabbix/conf/zabbix_agentd.conf
chown -R zabbix:zabbix /usr/sbin/zabbix

chkconfig zabbix-agent on
service zabbix-agent restart


rm /root/zabbix* -Rf
echo -e "\n#### config.conf #####"
cat /usr/sbin/zabbix/conf/zabbix_agentd.conf
ps aux |grep zabbix_agentd |grep -v grep
