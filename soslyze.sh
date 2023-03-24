#!/bin/bash

if [ $# -gt 0 ]; then 	
	SOS_DIR=${1%/}   	# remove trailing slash
else
    echo "${YELLOW}${BOLD}Missing path to extracted sosreport directory.${RESET}"
    echo "${YELLOW}${BOLD}Example: ./soslyze /path/to/sosreport${RESET}"
    exit
fi


if [ ! -d $SOS_DIR/sos_reports ]; then
    echo -e "\n\n${YELLOW}${BOLD}This is not a valid sosreport archive. Exiting..${RESET}\n\n"
    exit
fi


GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[01;33m'
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[01;36m'

cd $SOS_DIR


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
echo -e "${RED}${BOLD}Hostname:${RESET}\n$HOSTNAME\n"
echo -e "${RED}${BOLD}IPs:${RESET}\n$IP\n"
echo -e "${RED}${BOLD}Time and Date:${RESET}\n$DATE\n"
echo -e "${RED}${BOLD}Release:${RESET}\n$RELEASE\n"
echo -e "${RED}${BOLD}Memory:${RESET}\n$RAM\n"
echo -e "${RED}${BOLD}CPU:${RESET}\n$CPU\n"
echo -e "${RED}${BOLD}Show filesystems with more than 90% usage:${RESET}\n$FULL_FS\n"
echo -e "${RED}${BOLD}SELinux:${RESET}\n$SELINUX\n"


## Subscription Management

SUB_PLATFORM=$(egrep "^hostname|^baseurl|^port" ./etc/rhsm/rhsm.conf)
SUB_PROXY=$(grep -e ^proxy ./etc/rhsm/rhsm.conf)
SUB_SCA=$(rct cat-cert ./etc/pki/entitlement/*[0-9].pem | grep content_access)
SUB_CONSUMED=$(cat ./sos_commands/subscription_manager/subscription-manager_list_--consumed | egrep "Subscription Name|Subskriptionsname|SKU|Starts|Ends")
SUB_RPMS=$(grep -v 'Red Hat' ./sos_commands/rpm/package-data | awk {'print $1,$8,$9'})
SUB_FACTS=$(cat ./etc/rhsm/facts/*)
SUB_LFCE=$(cat ./sos_commands/subscription_manager/subscription-manager_identity)
SUB_ENABLED=$(cat ./sos_commands/yum/yum_-C_repolist)
SUB_URLS=$(egrep "enabled=1|enabled= 1|enabled = 1|enabled =1" ./etc/yum.repos.d/redhat.repo -B 12 | egrep "\[|enabled[^_]|baseurl")
SUB_UUID=$(grep -i uuid ./dmidecode)

echo -e "\n"
echo -e "${CYAN}${BOLD}### SUBSCRIPTIONS & REPOSITORIES ###${RESET}\n"
echo -e "${RED}${BOLD}Where is the system registered:${RESET}\n$SUB_PLATFORM\n"
echo -e "${RED}${BOLD}Proxy information:${RESET}\n$SUB_PROXY\n"
echo -e "${RED}${BOLD}SCA enabled or disabled (no output means disabled):${RESET}\n$SUB_SCA\n"
echo -e "${RED}${BOLD}Subscriptions attached:${RESET}\n$SUB_CONSUMED\n"
echo -e "${RED}${BOLD}Packages from 3rd party repositories:${RESET}\n$SUB_RPMS\n"
echo -e "${RED}${BOLD}Enabled repositories:${RESET}\n$SUB_ENABLED\n"
echo -e "${RED}${BOLD}Repo URLs:${RESET}\n$SUB_URLS\n"
echo -e "${RED}${BOLD}CV, LFCE and organization:${RESET}\n$SUB_LFCE\n"
echo -e "${RED}${BOLD}Custom RHSM facts:${RESET}\n$SUB_FACTS\n"
echo -e "${RED}${BOLD}RHSM UUID:${RESET}\n$SUB_UUID\n"


## Insights

if [ $(grep -c ^insights-client ./installed-rpms) -eq 1 ]; then
    INSIGHTS_CLIENT=$(grep insights-client ./installed-rpms)
    INSIGHTS_CONFIG=$(egrep -v '^\s*(#|$)' ./etc/insights-client/insights-client.conf)
    INSIGHTS_NETWORK=$(cat ./sos_commands/insights/insights-client_--test-connection_--net-debug)

    echo -e "\n"
    echo -e "${CYAN}${BOLD}### INSIGHTS ###${RESET}\n"
    echo -e "${RED}${BOLD}Version of insights-client:${RESET}\n$INSIGHTS_CLIENT\n"
    echo -e "${RED}${BOLD}Insights configuration (shows only non-default settings):${RESET}\n$INSIGHTS_CONFIG\n"
    echo -e "${RED}${BOLD}Insights network check:${RESET}\n$INSIGHTS_NETWORK\n"

else
    echo -e "${YELLOW}${BOLD}Insights not configured. Skipping..${RESET}"
fi


## SATELLITE

if [ $(grep -c ^satellite-6 ./installed-rpms) -eq 1 ]; then

    SAT_RELEASE=$(egrep "satellite-6|capsule" ./installed-rpms)
    SAT_HEALTH_CHECK=$(cat ./sos_commands/foreman/hammer_ping)
    SAT_CERTS=$(egrep -i 'server_key|server_cert_req|server_ca_cert|server_cert' ./etc/foreman-installer/scenarios.d/satellite-answers.yaml)
    #SAT_PORTS=$(head -2 ./netstat && grep LISTEN ./netstat | grep "tcp")
    SAT_HIERA=$(egrep -v '^\s*(#|$)' ./etc/foreman-installer/custom-hiera.yaml)
    SAT_CAPSULES=$(cat ./sos_commands/foreman/smart_proxies)
    SAT_TUN_PUMA=$(cat ./sos_commands/foreman/foreman-puma-status)
    SAT_TUN_DYNFLOW=$(cat ./sos_commands/foreman/dynflow_units)
    SAT_TUN_HTTPD=$(cat ./etc/httpd/conf.modules.d/prefork.conf)
    SAT_TUN_PUPPET=$(grep JAVA_ARGS ./etc/sysconfig/puppetserver)
    SAT_TUN_PGSQL=$(egrep 'max_connections|shared_buffers|work_mem|autovacuum_vacuum_cost_limit' ./var/lib/pgsql/data/postgresql.conf)
    SAT_TUN_QDROUTERD=$(grep LimitNOFILE ./etc/systemd/system/qdrouterd.service.d/*)
    SAT_TUN_QPIDD=$(grep LimitNOFILE ./etc/systemd/system/qpidd.service.d/*)
    #SAT_TRAFFIC=$(awk '{ print $1 }' ./var/log/httpd/foreman-ssl_access_ssl.log | sort | uniq -c | sort -nr -k 1 | head -n 10)
    SAT_YUM_HISTORY=$(cat ./sos_commands/yum/yum_history)
    SAT_TASKS_RUNNING=$(grep running ./sos_commands/foreman/foreman_tasks_tasks)
    SAT_TASKS_PAUSED=$(grep paused ./sos_commands/foreman/foreman_tasks_tasks)
    SAT_SETTINGS=$(head -1 ./sos_commands/foreman/foreman_settings_table && egrep 'http_proxy|allow_auto_inventory_upload|destroy_vm_on_host_delete|foreman_tasks_proxy_batch_trigger|foreman_tasks_proxy_batch_size|remote_execution_ssh_user|remote_execution_effective_user|foreman_ansible_proxy_batch_size|content_default_http_proxy|subscription_connection_enabled|default_download_policy|default_redhat_download_policy' ./sos_commands/foreman/foreman_settings_table)

    echo -e "\n"
    echo -e "${CYAN}${BOLD}### SATELLITE INFORMATION ###${RESET}\n"
    echo -e "${RED}${BOLD}Satellite version:${RESET}\n$SAT_RELEASE\n"
    echo -e "${RED}${BOLD}Hammer ping:${RESET}\n$SAT_HEALTH_CHECK\n"
    #echo -e "${RED}${BOLD}Opened ports:${RESET}\n$SAT_PORTS\n"
    echo -e "${RED}${BOLD}Custom or default certificates (no value means default cert):${RESET}\n$SAT_CERTS\n"
    echo -e "${RED}${BOLD}Custom hiera:${RESET}\n$SAT_HIERA\n"
    #echo -e "${RED}${BOLD}Content Hosts with highest https traffic:${RESET}\n$SAT_TRAFFIC\n"
    echo -e "${RED}${BOLD}Capsule overview:${RESET}\n$SAT_CAPSULES\n"
    echo -e "${RED}${BOLD}Yum history:${RESET}\n$SAT_YUM_HISTORY\n"
    echo -e "${RED}${BOLD}Running tasks:${RESET}\n$SAT_TASKS_RUNNING\n"
    echo -e "${RED}${BOLD}Paused tasks:${RESET}\n$SAT_TASKS_PAUSED\n"
    echo -e "${RED}${BOLD}Satellite settings (no value means default setting):${RESET}\n$SAT_SETTINGS\n"
    echo -e "${RED}${BOLD}Puma status:${RESET}\n$SAT_TUN_PUMA\n"
    echo -e "${RED}${BOLD}Dynflow sidekiq status:${RESET}\n$SAT_TUN_DYNFLOW\n"
    echo -e "${RED}${BOLD}Httpd tuning:${RESET}\n$SAT_TUN_HTTPD\n"
    echo -e "${RED}${BOLD}Puppet tuning:${RESET}\n$SAT_TUN_PUPPET\n"
    echo -e "${RED}${BOLD}Postgresql tuning:${RESET}\n$SAT_TUN_PGSQL\n"
    echo -e "${RED}${BOLD}Qdrouterd tuning:${RESET}\n$SAT_TUN_QDROUTERD\n"
    echo -e "${RED}${BOLD}Qpidd tuning:${RESET}\n$SAT_TUN_QPIDD\n"




else
    echo -e "${YELLOW}${BOLD}Not a satellite server. Skipping..${RESET}"

fi
