#!/bin/bash
#author:
#create:
#modify author:
#modify date:
#

#==== ============== ================== ============= #
#set -x 
SCRIPT=zabbix-agent-inst.sh
BASEPATH=$(cd `dirname $0`; pwd)
trap 'rm ${BASEPATH}/${SCRIPT} -Rf; echo Process INTERRUPTED' EXIT INT 

source_code=''
binary_status=''
os_type=''
os_type_release=''
function os_type_release_get(){
arr_os_type=('Red' 'Ubuntu' 'SUSE')
for((i=0;i<=${#arr_os_type[@]};i++))
do
   retnum=$(cat /proc/version |grep -i "${arr_os_type[i]}"|wc -l)
   if [ $retnum -gt 0 ];then
      if [ "${arr_os_type[i]}" == "Red" ];then
          if [ $(cat /etc/redhat-release |grep -i "Centos" |wc -l) -gt 0 ];then
              os_type=centos
			  #os_type_release=$(cat /etc/redhat-release |awk '{print $4}'|awk -F. '{print $1}')
			  os_type_release=$(uname -r |awk -F'el' '{print $2}' |awk -F. '{print $1}')
              echo -e "\n\033[0;32m=== system :centos and release :$os_type_release ====\033[0m\n"
            else
              os_type=redhat
			  os_type_release=$(uname -r |awk -F'el' '{print $2}' |awk -F. '{print $1}')
              echo -e "\n\033[0;32m=== system :redhat and release :$os_type_release  ====\033[0m\n"
          fi
          break 
       fi
       if [ "${arr_os_type[i]}" == "Ubuntu" ];then
           os_type=ubuntu
           echo -e "\n=== system :Ubuntu ====\n"
           break
        fi
        if [ "${arr_os_type[i]}" == "SUSE" ];then
           os_type=suse
           echo -e "\n=== system :SUSE ====\n"
           break
        fi
   fi
done
}


agent_status=2
function zabx_agent_run_status(){
  retval=$(ps aux |grep zabbix_agentd.conf|grep -v grep|wc -l)
  if [ $retval -eq 1 ];then
   echo -e "\n\033[0;32mzabbix_agent status: running!\033[0m\n" 
   agent_status=0 #agent is running
   else 
   echo -e "\n\033[0;32mzabbix_agent status: stopping!\033[0m\n" 
   agent_status=1 #agent don't running
  fi
  return ${agent_status}
}

function zabx_agent_stop(){
  zabx_agent_run_status
  os_type_release_get
  if [ $agent_status -eq 0 ];then
     if  [ -x /etc/init.d/zabbix-agent ] && [ $os_type_release -ne 7 ];then
        echo -e "\nbegin to stop zabbix_agent!!!!\n" 
        /etc/init.d/zabbix-agent stop
        if [ $? -ne 0 ];then
          echo "\n\033[0;31;1mCan't stop this zabbix_agent process,Pls check init.d/zabbix-agent!!!\033[0m\n" && exit 1
        fi
      elif [ $os_type_release -eq 7 ];then
        systemctl stop zabbix-agent.service
        if [ $? -ne 0 ];then
          echo "\n\033[0;31;1mCan't stop this zabbix_agent process,Pls check systemctl status zabbix-agent.service!!!\033[0m\n" && exit 1
        fi
      else
        echo -e "\n\033[0;31;1mkill -9 zabbix_agent process !!!\033[0m\n"
        mainpid=$(ps -ef |grep zabbix_agentd.conf |grep -v grep|awk '{print $2}')
        kill -9  ${mainpid}
      fi	 
  fi
}
  
function create_zabx_user(){
  userid=$(cat /etc/passwd |grep zabbix| cut -d':' -f 3|head -1)
  zabx_agent_stop
  zabx_agent_run_status
  if [ $agent_status -eq 0 ];then
     echo -e "\n\033[0;31;1mCan't delete zabbix user OR must stop zabbix_agent process !\033[0m\n" && exit 1
  else
     if [ ${userid} -ne 9009 ];then
     echo -e "\n==== Begin to delete user zabbix ====\n"
     userdel zabbix  #删除zabbix用户
     #groupdel zabbix
     fi
     idnum=$(cat /etc/passwd |grep zabbix|wc -l)
     if [ ${idnum} -eq 0 ];then
     echo -e "\n==== Create zabbix(uid:9009) user ====\n"
     groupadd -g 9009 zabbix
     useradd -u 9009 -g zabbix -G zabbix zabbix;
     sed -i '/zabbix/s/bin\/bash/sbin\/nologin/g' /etc/passwd
     fi
  fi
}

function zabx_file_delete(){
  zabx_agent_stop
  if [ $agent_status -eq 1 ] && [ "$os_type" = "redhat" ] ;then
     echo -e "\n==== begin to delete redhat rpm ====\n"
     rpm -e --nodeps zabbix-agent-3.2.3
     echo -e "\n==== finish delete redhat rpm ====\n"
  fi
  if [ $agent_status -eq 1 ] && [ "$os_type" = "centos" ] ;then
     echo -e "\n==== begin to delete centos rpm  ====\n"
     rpm -e --nodeps zabbix-agent-3.2.3
     echo -e "\n==== finish delete centos rpm ====\n"
  fi

  if [ $agent_status -eq 1 ];then 
     echo -e "\n\033[0;32m==== begin to delete all files and dirs ====\033[0m\n"
     if [ -f /etc/zabbix_agentd.conf ];then
        rm /etc/zabbix_agentd.conf -Rf
     fi
     if [ -f /etc/zabbix_agentd.conf ];then
        rm /etc/zabbix_agentd.conf -Rf
     fi
     if [ -d /etc/zabbix ];then
        rm /etc/zabbix -Rf
     fi
     if [ -f /usr/sbin/zabbix_agentd ];then
	    rm /usr/sbin/zabbix_agentd -Rf
	 fi
     if [ -f /etc/init.d/zabbix-agent ];then
	    rm /etc/init.d/zabbix-agent -Rf
	 fi
     if [ -f /etc/logrotate.d/zabbix-agent ];then
            rm /etc/logrotate.d/zabbix-agent -Rf
         fi
     if [ -d /var/log/zabbix ];then
	    rm /var/log/zabbix -Rf
     fi
     if [ -d /var/run/zabbix ];then
	    rm /var/run/zabbix -Rf
     fi
     if [ -d /usr/sbin/zabbix ];then
	    rm /usr/sbin/zabbix -Rf
	 fi
     if [ -d /usr/local/zabbix ];then
	    rm /usr/local/zabbix -Rf
	 fi
     echo -e "\n\033[0;32m==== finish delete all files ====\033[0m\n"
  fi
}


function install_binary_agent()
{  
  zabx_agent_stop
  zabx_file_delete
  zabx_agent_run_status
  if [ $agent_status -eq 0 ];then
   echo -e "\n\033[0;31;1m zabbix_agent running,Can't install agent!!!\033[0m" && exit 1
  else
    mkdir -p /root/zabbix_agent
	cd /root/zabbix_agent
    if [ ! -f /root/zabbix_agent/zabbix_agents_3.2.0.linux2_6_23.amd64.tar.gz ];then
        wget http://10.101.10.129:8090/software/zabbix/agent/zabbix_agents_3.2.0.linux2_6_23.amd64.tar.gz
        tar xvfz /root/zabbix_agent/zabbix_agents_3.2.0.linux2_6_23.amd64.tar.gz
	cp  sbin/zabbix_agentd  /usr/sbin/
    fi
  fi
}


function install_source_package()
{  
  zabx_agent_stop
  zabx_file_delete
  zabx_agent_run_status
  if [ $agent_status -eq 0 ];then
   echo -e "\n\033[0;31;1m zabbix_agent running,Can't install agent!!!\033[0m" && exit 1
  else
    mkdir -p /root/zabbix_agent
    cd /root/zabbix_agent
    if [ ! -f /root/zabbix_agent/zabbix-3.2.3.tar.gz ];then
      wget http://10.101.10.129:8090/software/zabbix/zabbix-3.2.3.tar.gz
      tar xvfz /root/zabbix_agent/zabbix-3.2.3.tar.gz
      cd /root/zabbix_agent/zabbix-3.2.3
      ./configure --sbindir=/usr/sbin/ --bindir=/bin/ --enable-agent --sysconfdir=/etc/zabbix &&  make &&  make install
    fi
  fi
}


function download_zabx_agent_rpm()
{ 
 if [ "${os_type}" == "redhat" ] || [ "${os_type}" == "centos" ];then
   mkdir -p /root/zabbix_agent
   cd  /root/zabbix_agent
   if [ $(ls /root/zabbix_agent/zabbix-agent-3.2.3-1*.rpm |wc -l) -gt 0 ];then
     rm /root/zabbix_agent/zabbix-agent-3.2.3-1*.rpm -Rf
   fi
   echo -e "\n=== Begin download rpm package : $(date)====\n"
   case ${os_type_release} in
    "5")
    wget http://10.101.10.129:8090/software/zabbix/agent/linux/zabbix-agent-3.2.3-1.el5.x86_64.rpm
    ;;
    "6")
    wget http://10.101.10.129:8090/software/zabbix/agent/linux/zabbix-agent-3.2.3-1.el6.x86_64.rpm
    ;;
    "7")
    wget http://10.101.10.129:8090/software/zabbix/agent/linux/zabbix-agent-3.2.3-1.el7.x86_64.rpm
    ;;
    "*")
    echo -e "\n\033[0;31;1mCan't download this install PRM package, exit now !\033[0m"
    exit 1
    ;;
   esac
   echo -e "\n=== finishing download rpm package: $(date) ====\n"
 fi
}

function install_zabx_agent_rpm()
{
  if [ "${os_type}" == "redhat" ] || [ "${os_type}" == "centos" ];then
   cd  /root/zabbix_agent
   zabx_agent_stop
   zabx_file_delete
   if [ $(ls /root/zabbix_agent/zabbix-agent-3.2.3-1*.rpm |wc -l) -gt 0 ];then
    echo -e "\n==== Begin install rpm  package: $(date) ====\n"
    case ${os_type_release} in
    "5")
     rpm -ivh zabbix-agent-3.2.3-1.el5.x86_64.rpm || exit 1
    ;;
    "6")
    rpm -ivh zabbix-agent-3.2.3-1.el6.x86_64.rpm || exit 1
    ;;
    "7")
    rpm -ivh zabbix-agent-3.2.3-1.el7.x86_64.rpm || exit 1
    ;;
    "*")
    rpm -ivh zabbix-agent-3.2.3-1.*.rpm || exit 1
    ;;
   esac
   echo -e "\n=== finishing  install rpm  package: $(date) ====\n"
   else
    echo -e "\n\033[0;31;1mCan't find this install PRM package, exit now\033[0m\n" && exit 1
  fi
 fi
 }

function config_zabx_agent(){
  if [ ! -d /var/log/zabbix ];then
   mkdir -p /var/log/zabbix/
   chown -R zabbix:zabbix /var/log/zabbix
  fi
  if [ ! -d /var/run/zabbix ];then
    mkdir -p /var/run/zabbix
    chown -R zabbix:zabbix /var/run/zabbix
  fi
  if [ ! -d /etc/zabbix/zabbix_agentd.conf.d ];then
    mkdir -p /etc/zabbix/zabbix_agentd.conf.d
  fi
  echo "Hostname=" > /etc/zabbix/zabbix_agentd.conf
  echo "ListenIP="  >> /etc/zabbix/zabbix_agentd.conf
  echo "Include=/etc/zabbix/zabbix_agentd.conf.d"  >> /etc/zabbix/zabbix_agentd.conf
  echo "LogFileSize=0"  >> /etc/zabbix/zabbix_agentd.conf
  echo "LogFile=/var/log/zabbix/zabbix_agentd.log"  >> /etc/zabbix/zabbix_agentd.conf
  echo "PidFile=/var/run/zabbix/zabbix_agentd.pid"  >> /etc/zabbix/zabbix_agentd.conf
  echo "Server=10.101.10.146,10.101.10.147,10.101.10.116,10.0.77.88"  >> /etc/zabbix/zabbix_agentd.conf
  echo "ServerActive=10.101.10.146,10.101.10.147,10.101.10.116,10.0.77.88"  >> /etc/zabbix/zabbix_agentd.conf
  echo "StartAgents=3"  >> /etc/zabbix/zabbix_agentd.conf
  chown -R zabbix:zabbix /usr/sbin/zabbix_agentd
  chown -R zabbix:zabbix /etc/zabbix/
  #IPADDR=$(hostname -i)
  IPADDR=$(ip addr s|grep 10. |grep -v mtu|awk '{print $2}'|awk -F/ '{print $1}'|head -1)
  sed -i "/Hostname/s/=.*$/=${IPADDR}/g"  /etc/zabbix/zabbix_agentd.conf
  sed -i "/ListenIP/s/=.*$/=${IPADDR}/g"  /etc/zabbix/zabbix_agentd.conf
 }

function start_zabx_agent(){ 
  zabx_agent_run_status
  if [ $agent_status = 1 ];then
    echo -e "\n==== Starting zabbix-agent Service ====" 
    if [ ${os_type_release} -ge  7 ];then
      systemctl enable zabbix-agent.service
      systemctl restart zabbix-agent.service
    else
      if [ -x /etc/init.d/zabbix-agent ];then
        chkconfig zabbix-agent on
        service zabbix-agent restart
      fi
    fi
  fi
} 
 
function check_zabx_status()
{
  echo -e "\n==== Check agent install info =======\n"
  id zabbix
  cat /etc/zabbix/zabbix_agentd.conf
  psnum=$(ps aux |grep -i "zabbix_agentd"|grep -v grep|wc -l)
  if [ ${psnum} -eq 0 ];then
     echo -e "\n\033[0;31;1mzabbix_agent can't starting ,Pls check this configure now !!!\033[0m\n"
  else
     ps aux |grep -i "zabbix_agentd"|grep -v grep 
  fi
  echo -e "\n==== finish check install =======\n"
}

function clean_zabbix_rpm()
{ 
  echo -e "\n====== Begin clean work ======\n"
  if [ -d /root/zabbix_agent ];then
    rm /root/zabbix_agent -Rf
  fi
  echo -e "\n====== finishing clean work ======\n"
 }
 
function get_zabbix_logrotate(){
  if [ ! -f /etc/logrotate.d/zabbix-agent ];then
   cd /etc/logrotate.d/
   wget http://10.101.10.129:8090/software/zabbix/agent/zabbix-agent.logrotate
   mv /etc/logrotate.d/zabbix-agent.logrotate /etc/logrotate.d/zabbix-agent
   chmod 644 /etc/logrotate.d/zabbix-agent
   chown -R root:root /etc/logrotate/zabbix-agent
  fi
}  

function get_zabbix_initd(){
  if [ -f /etc/init.d/zabbix-agent ];then
   rm /etc/init.d/zabbix-agent -Rf
  fi 
  cd  /etc/init.d
  wget http://10.101.10.129:8090/software/zabbix/agent/zabbix-agent
  chmod 755 /etc/init.d/zabbix-agent
  chown -R root:root /etc/init.d/zabbix-agent
}

function install_source_list(){
 if [ "${source_code}" == "TRUE" ];then
      install_source_package
      create_zabx_user
      get_zabbix_initd
      get_zabbix_logrotate
      config_zabx_agent
      start_zabx_agent
      check_zabx_status
      clean_zabbix_rpm
 
 fi
}

#start select model
function select_option(){
read -n1 -p "Need Source code install ? Enter [y/n]" ANSWER
case $ANSWER in
 Y|y|yes|Yes)
   source_code='TRUE'
 ;;
 *)
   echo -e "\n\033[0;31;1mPls input y/n again  \033[0m"; exit 1
esac
}
   
############## Start control function list ##############

function start_control_function_list()
{ 
  #select_option
  if [ "${source_code}" == "TRUE" ];then
     install_source_list   
  else
     create_zabx_user
     os_type_release_get
     if [ "${os_type}" == "redhat" ] || [ "${os_type}" == "centos" ];then
        download_zabx_agent_rpm
        install_zabx_agent_rpm
     else
        install_binary_agent
        get_zabbix_initd
        get_zabbix_logrotate
     fi
      
     config_zabx_agent
     start_zabx_agent
     check_zabx_status
     clean_zabbix_rpm 
  fi
}



echo -e "\n\033[0;32m############ Start process ###################\033[0m\n"

start_control_function_list

echo -e "\n\033[0;32m############ end  process ###################\033[0m\n"
