#!/bin/bash

if [ $# -gt 0 ]; then 	
	SOS_DIR=${1%/}   	# remove trailing slash
else
        echo "Missing path to extracted sosreport."
    	echo "Example: ./soslyze /path/to/sosreport"
        exit
fi


if [ ! -d $SOS_DIR/sos_reports ]; then
		echo -e "\n\n${YELLOW}This is not a valid sosreport archive. Exiting..${RESET}\n\n"
		exit
fi


GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[01;33m'
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[01;36m'

cd $DIR


## GENERAL

DATE=$(cat ./date)
IP=$(grep "inet " ./ip_addr | awk -F'[: ]+' '{ print $4 }')
RELEASE=$(cat ./etc/redhat-release)
HOSTNAME=$(cat ./hostname)
RAM=$(cat ./free)
CPU=$(grep -e "^CPU(s)" -e "Socket(s)" -e "Core(s) per socket" ./sos_commands/processor/lscpu)
FULL_FS=$(cat ./df | awk '$5 >=90 {print $5,$6}')
SELINUX=$(egrep -i "SELinux status|Current mode" ./sos_commands/selinux/sestatus)
#CRON=$()
#MEMORY=$()
#MEM_PROCESS=$(head -1 ./ps && sort -nrk6 ./ps | head -n5)
#MEM_USER
#CPU_PROCESS

echo -e "\n"
echo -e "${CYAN}${BOLD}### GENERAL INFORMATION ###${RESET}\n"
echo -e "${RED}Hostname:${RESET}\n$HOSTNAME\n"
echo -e "${RED}IPs:${RESET}\n$IP\n"
echo -e "${RED}Time and Date:${RESET}\n$DATE\n"
echo -e "${RED}Release:${RESET}\n$RELEASE\n"
echo -e "${RED}Memory:${RESET}\n$RAM\n"
echo -e "${RED}CPU:${RESET}\n$CPU\n"
echo -e "${RED}Show filesystems with more than 90% usage:${RESET}\n$FULL_FS\n"
echo -e "${RED}SELinux:${RESET}\n$SELINUX\n"


## Subscription Management

SUBSCRIPTION_PLATFORM=$(egrep "^hostname|^baseurl|^port" ./etc/rhsm/rhsm.conf)
PROXY=$(grep -e ^proxy ./etc/rhsm/rhsm.conf)
SCA=$(rct cat-cert ./etc/pki/entitlement/*[0-9].pem | grep content_access)
CONSUMED_SUBS=$(cat ./sos_commands/subscription_manager/subscription-manager_list_--consumed | egrep "Subscription Name|Subskriptionsname|SKU|Starts|Ends")
THIRD_PARTY_RPMS=$(grep -v 'Red Hat' ./sos_commands/rpm/package-data | awk {'print $1,$8,$9'})
CUSTOM_FACTS=$(cat ./etc/rhsm/facts/*)
CV_LFCE_ORG=$(cat ./sos_commands/subscription_manager/subscription-manager_identity)
ENABLED_REPOS=$(cat ./sos_commands/yum/yum_-C_repolist)
REPO_URLS=$(egrep "enabled=1|enabled= 1|enabled = 1|enabled =1" ./etc/yum.repos.d/redhat.repo -B 12 | egrep "\[|enabled[^_]|baseurl")
RHSM_UUID=$(grep -i uuid ./dmidecode)

echo -e "\n"
echo -e "${CYAN}${BOLD}### SUBSCRIPTIONS & REPOSITORIES ###${RESET}\n"
echo -e "${RED}Where is the system registered:${RESET}\n$SUBSCRIPTION_PLATFORM\n"
echo -e "${RED}Proxy information:${RESET}\n$PROXY\n"
echo -e "${RED}SCA enabled or disabled (no output means disabled):${RESET}\n$SCA\n"
echo -e "${RED}Subscriptions attached:${RESET}\n$CONSUMED_SUBS\n"
echo -e "${RED}Packages from 3rd party repositories:${RESET}\n$THIRD_PARTY_RPMS\n"
echo -e "${RED}Enabled repositories:${RESET}\n$ENABLED_REPOS\n"
echo -e "${RED}Repo URLs:${RESET}\n$REPO_URLS\n"
echo -e "${RED}CV, LFCE and organization:${RESET}\n$CV_LFCE_ORG\n"
echo -e "${RED}Custom RHSM facts:${RESET}\n$CUSTOM_FACTS\n"
echo -e "${RED}RHSM UUID:${RESET}\n$RHSM_UUID\n"


## Insights

if [ $(grep -c ^insights-client ./installed-rpms) -eq 1 ]; then
	INSIGHTS_CLIENT=$(grep insights-client ./installed-rpms)
	INSIGHTS_CONFIG=$(egrep -v '^\s*(#|$)' ./etc/insights-client/insights-client.conf)

	echo -e "\n"
	echo -e "${CYAN}${BOLD}### INSIGHTS ###${RESET}\n"
	echo -e "${RED}Version of insights-client:${RESET}\n$INSIGHTS_CLIENT\n"
	echo -e "${RED}Insights configuration (shows only non-default settings):${RESET}\n$INSIGHTS_CONFIG\n"

else
	echo -e "${YELLOW}Insights not configured. Skipping..${RESET}"

fi


## SATELLITE

if [ $(grep -c ^satellite-6 ./installed-rpms) -eq 1 ]; then

    SAT_RELEASE=$(egrep "satellite-6|capsule" ./installed-rpms)
    HEALTH_CHECK=$(cat ./sos_commands/foreman/hammer_ping)
    CUSTOM_CERTS=$(egrep -i 'server_key|server_cert_req|server_ca_cert|server_cert' ./etc/foreman-installer/scenarios.d/satellite-answers.yaml)
    OPEN_PORTS=$(head -2 ./netstat && grep LISTEN ./netstat | grep "tcp")
	HIERA=$(egrep -v '^\s*(#|$)' ./etc/foreman-installer/custom-hiera.yaml)
	#TUNING_PROFILE=$(grep tuning ./etc/foreman-installer/scenarios.d/satellite.yaml)
	#TUNING_PUMA=$(grep puma ./etc/foreman-installer/scenarios.d/satellite-answers.yaml)
	#TUNING_DYNFLOW=$(grep dynflow_worker ./etc/foreman-installer/scenarios.d/satellite-answers.yaml)
	#TUNING_HTTPD=$(cat ./etc/httpd/conf.modules.d/prefork.conf)
	#TUNING_PUPPET=$(grep JAVA_ARGS ./etc/sysconfig/puppetserver)
	#TUNING_POSTGRESQL=$(egrep 'max_connections|shared_buffers|work_mem|autovacuum_vacuum_cost_limit' ./var/lib/pgsql/data/postgresql.conf)
	#TUNING_QDROUTERD=$(grep LimitNOFILE ./etc/systemd/system/qdrouterd.service.d/*)
	#TUNING_QPIDD=$(grep LimitNOFILE ./etc/systemd/system/qpidd.service.d/*)
	#HTTPS_TRAFFIC=$(awk '{ print $1 }' var/log/httpd/foreman-ssl_access_ssl.log | sort | uniq -c | sort -nr -k 1 | head -n 10)
	#YUM_HISTORY=$(cat ./sos_commands/yum/yum_history)
	#TASKS_RUNNING=$(grep running ./sos_commands/foreman/foreman_tasks_tasks)
	#TASKS_PAUSED=$(grep paused ./sos_commands/foreman/foreman_tasks_tasks)
	#FOREMAN_SETTINGS=$()

    echo -e "\n"
    echo -e "${CYAN}${BOLD}### SATELLITE INFORMATION ###${RESET}\n"
    echo -e "${RED}Satellite version:${RESET}\n$SAT_RELEASE\n"
    echo -e "${RED}Hammer ping:${RESET}\n$HEALTH_CHECK\n"
    echo -e "${RED}Opened ports:${RESET}\n$OPEN_PORTS\n"

	echo -e "${RED}Custom or default certificates (empty values means default certs):${RESET}\n$CUSTOM_CERTS\n"
	echo -e "${RED}Custom hiera:${RESET}\n$HIERA\n"

else
    echo -e "${YELLOW}Not a satellite server. Skipping..${RESET}"

fi
