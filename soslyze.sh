#!/bin/bash

# Define colors

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[01;33m'
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[01;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'

# Check for sosreport archive

if [ $# -gt 0 ]; then
        SOS_DIR=${1%/}          # remove trailing slash
else
    echo -e "\n${YELLOW}${BOLD}Missing path to extracted sosreport directory.${RESET}"
    echo -e "${PURPLE}${BOLD}Example: ./soslyze.sh /path/to/sosreport${RESET}\n"
    exit
fi


if [ ! -d $SOS_DIR/sos_reports ]; then
    echo -e "\n${YELLOW}${BOLD}This is not a valid sosreport archive. Exiting..${RESET}\n"
    exit
fi


cd $SOS_DIR



# Tasks if RHEL 7
rhel_7_tasks() {

    # General
    DATE=$(cat ./date)
    IP=$(grep "inet " ./ip_addr | awk -F'[: ]+' '{ print $4 }')
    RELEASE=$(cat ./etc/redhat-release)
    HOSTNAME=$(cat ./hostname)
    RAM=$(cat ./free)
    CPU=$(grep -e "^CPU(s)" -e "Socket(s)" -e "Core(s) per socket" ./sos_commands/processor/lscpu)
    FULL_FS=$(cat ./df | awk '$5 >=90 {print $5,$6}')
    SELINUX=$(egrep -i "SELinux status|Current mode" ./sos_commands/selinux/sestatus)
    VM=$(egrep 'Vendor|Manufacturer' ./dmidecode | head -3)
    FIPS=$(cat ./proc/sys/crypto/fips_enabled)
    CRYPTO=$(cat ./sos_commands/crypto/update-crypto-policies_--show)

    # Subscription Management
    SUB_PLATFORM=$(egrep "^hostname|^baseurl|^port" ./etc/rhsm/rhsm.conf)
    SUB_PROXY=$(grep -e ^proxy ./etc/rhsm/rhsm.conf)
    SUB_SCA=$(for cert in `ls ./etc/pki/entitlement/`; do rct cat-cert ./etc/pki/entitlement/$cert | grep content_access; done)
    SUB_CONSUMED=$(cat ./sos_commands/subscription_manager/subscription-manager_list_--consumed | egrep "Subscription Name|Subskriptionsname|Nom de l'abonnement|SKU|Starts|Ends|Pool ID|Status Details")
    SUB_RPMS=$(grep -v 'Red Hat' ./sos_commands/rpm/package-data | awk {'print $1,$8,$9'})
    SUB_FACTS=$(cat ./etc/rhsm/facts/*)
    SUB_LFCE=$(cat ./sos_commands/subscription_manager/subscription-manager_identity)
    SUB_ENABLED=$(cat ./sos_commands/yum/yum_-C_repolist)
    SUB_URLS=$(egrep "enabled=1|enabled= 1|enabled = 1|enabled =1" ./etc/yum.repos.d/redhat.repo -B 12 | egrep "\[|enabled[^_]|baseurl")
    SUB_UUID=$(grep -i uuid ./dmidecode)
    SUB_HISTORY=$(head -30 ./sos_commands/yum/yum_history)
    SUB_EXCLUDE=$(grep -i exclude ./etc/yum.conf)
    SUB_VARS=$(ls ./etc/yum/vars/)

    # Print to stdout
    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### GENERAL INFORMATION #####${RESET}\n"
    echo -e "${BLUE}${BOLD}Hostname:${RESET}\n$HOSTNAME\n"
    echo -e "${BLUE}${BOLD}NICs:${RESET}\n$IP\n"
    echo -e "${BLUE}${BOLD}Time and Date:${RESET}\n$DATE\n"
    echo -e "${BLUE}${BOLD}Release:${RESET}\n$RELEASE\n"
    echo -e "${BLUE}${BOLD}Memory:${RESET}\n$RAM\n"
    echo -e "${BLUE}${BOLD}CPU:${RESET}\n$CPU\n"
    echo -e "${BLUE}${BOLD}Filesystems over 90% usage:${RESET}\n$FULL_FS\n"
    echo -e "${BLUE}${BOLD}SELinux:${RESET}\n$SELINUX\n"
    echo -e "${BLUE}${BOLD}VM or physical:${RESET}\n$VM\n"
    echo -e "${BLUE}${BOLD}FIPS mode (0=disabled, 1=enabled):${RESET}\n$FIPS\n"
    echo -e "${BLUE}${BOLD}Crypto policy:${RESET}\n$CRYPTO\n"

    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### SUBSCRIPTIONS & REPOSITORIES #####${RESET}\n"
    echo -e "${BLUE}${BOLD}How is the system registered:${RESET}\n$SUB_PLATFORM\n"
    echo -e "${BLUE}${BOLD}Proxy information:${RESET}\n$SUB_PROXY\n"
    echo -e "${BLUE}${BOLD}SCA (content_access=enabled):${RESET}\n$SUB_SCA\n"
    echo -e "${BLUE}${BOLD}Subscriptions attached:${RESET}\n$SUB_CONSUMED\n"
    echo -e "${BLUE}${BOLD}Packages from 3rd party repositories:${RESET}\n$SUB_RPMS\n"
    echo -e "${BLUE}${BOLD}Enabled repositories:${RESET}\n$SUB_ENABLED\n"
    echo -e "${BLUE}${BOLD}Repo URLs:${RESET}\n$SUB_URLS\n"
    echo -e "${BLUE}${BOLD}CV, LFCE and organization:${RESET}\n$SUB_LFCE\n"
    echo -e "${BLUE}${BOLD}Custom RHSM facts:${RESET}\n$SUB_FACTS\n"
    echo -e "${BLUE}${BOLD}RHSM/DMI UUID:${RESET}\n$SUB_UUID\n"
    echo -e "${BLUE}${BOLD}Yum/dnf history:${RESET}\n$SUB_HISTORY\n"
    echo -e "${BLUE}${BOLD}Excluded packages by yum/dnf:${RESET}\n$SUB_EXCLUDE\n"
    echo -e "${BLUE}${BOLD}Yum/dnf variables:${RESET}\n$SUB_VARS\n"

}


# Tasks if RHEL 8 or RHEL 9
rhel_8_tasks() {

    # General
    DATE=$(cat ./date)
    IP=$(grep "inet " ./ip_addr | awk -F'[: ]+' '{ print $4 }')
    RELEASE=$(cat ./etc/redhat-release)
    HOSTNAME=$(cat ./hostname)
    RAM=$(cat ./free)
    CPU=$(grep -e "^CPU(s)" -e "Socket(s)" -e "Core(s) per socket" ./sos_commands/processor/lscpu)
    FULL_FS=$(cat ./df | awk '$5 >=90 {print $1,$2,$3,$4,$5,$6}')
    SELINUX=$(egrep -i "SELinux status|Current mode" ./sos_commands/selinux/sestatus)
    VM=$(egrep 'Vendor|Manufacturer' ./dmidecode | head -3)
    FIPS=$(cat ./proc/sys/crypto/fips_enabled)
    CRYPTO=$(cat ./sos_commands/crypto/update-crypto-policies_--show)

    # Subscription Management
    SUB_PLATFORM=$(egrep "^hostname|^baseurl|^port|^repo_ca_cert|^ca_cert_dir" ./etc/rhsm/rhsm.conf)
    SUB_PROXY=$(grep -e ^proxy ./etc/rhsm/rhsm.conf)
    SUB_SCA=$(for cert in `ls ./etc/pki/entitlement/`; do rct cat-cert ./etc/pki/entitlement/$cert | grep content_access; done)
    SUB_CONSUMED=$(cat ./sos_commands/subscription_manager/subscription-manager_list_--consumed | egrep "Subscription Name|Subskriptionsname|Nom de l'abonnement|SKU|Starts|Ends|Pool ID|Status Details")
    SUB_RPMS=$(grep -v 'Red Hat' ./sos_commands/rpm/package-data | awk {'print $1,$8,$9'})
    SUB_FACTS=$(cat ./etc/rhsm/facts/*)
    SUB_LFCE=$(cat ./sos_commands/subscription_manager/subscription-manager_identity)
    SUB_ENABLED=$(cat ./sos_commands/dnf/dnf_-C_repolist)
    SUB_URLS=$(egrep "enabled=1|enabled= 1|enabled = 1|enabled =1" ./etc/yum.repos.d/redhat.repo -B 12 | egrep "\[|enabled[^_]|baseurl")
    SUB_UUID=$(grep -i uuid ./dmidecode)
    SUB_HISTORY=$(head -30 ./sos_commands/dnf/dnf_history)
    SUB_EXCLUDE=$(grep -i exclude ./etc/dnf/dnf.conf)
    SUB_VARS=$(ls ./etc/dnf/vars/)

    # Print to stdout
    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### GENERAL INFORMATION #####${RESET}\n"
    echo -e "${BLUE}${BOLD}Hostname:${RESET}\n$HOSTNAME\n"
    echo -e "${BLUE}${BOLD}NICs:${RESET}\n$IP\n"
    echo -e "${BLUE}${BOLD}Time and Date:${RESET}\n$DATE\n"
    echo -e "${BLUE}${BOLD}Release:${RESET}\n$RELEASE\n"
    echo -e "${BLUE}${BOLD}Memory:${RESET}\n$RAM\n"
    echo -e "${BLUE}${BOLD}CPU:${RESET}\n$CPU\n"
    echo -e "${BLUE}${BOLD}Filesystems over 90% usage:${RESET}\n$FULL_FS\n"
    echo -e "${BLUE}${BOLD}SELinux:${RESET}\n$SELINUX\n"
    echo -e "${BLUE}${BOLD}VM or physical:${RESET}\n$VM\n"
    echo -e "${BLUE}${BOLD}FIPS mode (0=disabled, 1=enabled):${RESET}\n$FIPS\n"
    echo -e "${BLUE}${BOLD}Crypto policy:${RESET}\n$CRYPTO\n"

    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### SUBSCRIPTIONS & REPOSITORIES #####${RESET}\n"
    echo -e "${BLUE}${BOLD}How is the system registered:${RESET}\n$SUB_PLATFORM\n"
    echo -e "${BLUE}${BOLD}Proxy information:${RESET}\n$SUB_PROXY\n"
    echo -e "${BLUE}${BOLD}SCA (content_access=enabled):${RESET}\n$SUB_SCA\n"
    echo -e "${BLUE}${BOLD}Subscriptions attached:${RESET}\n$SUB_CONSUMED\n"
    echo -e "${BLUE}${BOLD}Packages from 3rd party repositories:${RESET}\n$SUB_RPMS\n"
    echo -e "${BLUE}${BOLD}Enabled repositories:${RESET}\n$SUB_ENABLED\n"
    echo -e "${BLUE}${BOLD}Red Hat repo URLs:${RESET}\n$SUB_URLS\n"
    echo -e "${BLUE}${BOLD}CV, LFCE and organization:${RESET}\n$SUB_LFCE\n"
    echo -e "${BLUE}${BOLD}Custom RHSM facts:${RESET}\n$SUB_FACTS\n"
    echo -e "${BLUE}${BOLD}RHSM/DMI UUID:${RESET}\n$SUB_UUID\n"
    echo -e "${BLUE}${BOLD}Yum/dnf history:${RESET}\n$SUB_HISTORY\n"
    echo -e "${BLUE}${BOLD}Excluded packages by yum/dnf:${RESET}\n$SUB_EXCLUDE\n"
    echo -e "${BLUE}${BOLD}Yum/dnf variables:${RESET}\n$SUB_VARS\n"

}


# Tasks if Insights

insights_tasks() {
    INSIGHTS_CLIENT=$(grep insights-client ./installed-rpms)
    INSIGHTS_CONFIG=$(egrep -v '^\s*(#|$)' ./etc/insights-client/insights-client.conf)
    INSIGHTS_NETWORK=$(cat ./sos_commands/insights/insights-client_--test-connection_--net-debug)

    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### INSIGHTS #####${RESET}\n"
    echo -e "${BLUE}${BOLD}Version of insights-client:${RESET}\n$INSIGHTS_CLIENT\n"
    echo -e "${BLUE}${BOLD}Insights configuration (shows only non-default settings):${RESET}\n$INSIGHTS_CONFIG\n"
    echo -e "${BLUE}${BOLD}Insights connectivity check:${RESET}\n$INSIGHTS_NETWORK\n"

}


# Tasks if Satellite 6

sat_6_tasks() {
    SAT_RELEASE=$(egrep "satellite-6|capsule" ./installed-rpms)
    SAT_HEALTH_CHECK=$(cat ./sos_commands/foreman/hammer_ping)
    SAT_CERTS=$(egrep -i 'server_key|server_cert_req|server_ca_cert|server_cert' ./etc/foreman-installer/scenarios.d/satellite-answers.yaml)
    SAT_HIERA=$(egrep -v '^\s*(#|$)' ./etc/foreman-installer/custom-hiera.yaml)
    SAT_CAPSULES=$(cat ./sos_commands/foreman/smart_proxies)
    SAT_TUN_PROFILE=$(grep tuning ./etc/foreman-installer/scenarios.d/satellite.yaml)
    SAT_TUN_PUMA_WORKERS=$(egrep "PUMA_THREADS|PUMA_WORKERS" ./etc/systemd/system/foreman.service.d/installer.conf)
    SAT_TUN_PUMA_STAT=$(cat ./sos_commands/foreman/foreman-puma-status)
    SAT_TUN_PUMA_POOL=$(grep pool ./etc/foreman/database.yml)
    SAT_TUN_DYNFLOW=$(cat ./sos_commands/foreman/dynflow_units)
    #SAT_TUN_HTTPD=$(cat ./etc/httpd/conf.modules.d/prefork.conf)
    SAT_TUN_HTTPD=$(cat ./etc/httpd/conf.modules.d/event.conf)
    SAT_TUN_PUPPET=$(grep JAVA_ARGS ./etc/sysconfig/puppetserver)
    SAT_TUN_PGSQL=$(egrep 'max_connections|shared_buffers|work_mem|autovacuum_vacuum_cost_limit' ./var/lib/pgsql/data/postgresql.conf)
    #SAT_TUN_QDROUTERD=$(grep LimitNOFILE ./etc/systemd/system/qdrouterd.service.d/*)
    #SAT_TUN_QPIDD=$(grep LimitNOFILE ./etc/systemd/system/qpidd.service.d/*)
    #SAT_TRAFFIC=$(awk '{ print $1 }' ./var/log/httpd/foreman-ssl_access_ssl.log | sort | uniq -c | sort -nr -k 1 | head -n 10)
    SAT_TASKS_RUNNING=$(head -1 ./sos_commands/foreman/foreman_tasks_tasks && grep running ./sos_commands/foreman/foreman_tasks_tasks)
    SAT_TASKS_PAUSED=$(head -1 ./sos_commands/foreman/foreman_tasks_tasks && grep paused ./sos_commands/foreman/foreman_tasks_tasks)
    SAT_SETTINGS=$(head -1 ./sos_commands/foreman/foreman_settings_table && egrep 'http_proxy|allow_auto_inventory_upload|destroy_vm_on_host_delete|foreman_tasks_proxy_batch_trigger|foreman_tasks_proxy_batch_size|remote_execution_ssh_user|remote_execution_effective_user|foreman_ansible_proxy_batch_size|content_default_http_proxy|subscription_connection_enabled|default_download_policy|default_redhat_download_policy' ./sos_commands/foreman/foreman_settings_table)
    SAT_ANSIBLE=$(egrep "ANSIBLE_ROLES_PATH|ANSIBLE_COLLECTIONS_PATHS|ANSIBLE_SSH_ARGS" ./etc/foreman-proxy/ansible.env)
    SAT_SCA=$(cat ./sos_commands/candlepin/simple_content_access)
    SAT_FS_CP=$(cat ./sos_commands/candlepin/du_-sh_.var.lib.candlepin)
    SAT_FS_PGSQL=$(cat ./sos_commands/postgresql/du_-sh_.var.lib.pgsql)
    SAT_DB_FOREMAN=$(head -12 ./sos_commands/foreman/foreman_db_tables_sizes)
    SAT_DB_CP=$(head -12 ./sos_commands/candlepin/candlepin_db_tables_sizes)
    SAT_DB_FACTS=$(head -10 ./sos_commands/foreman/fact_names_prefixes)

    echo -e "\n"
    echo -e "${CYAN}${BOLD}##### SATELLITE INFORMATION #####${RESET}\n"
    echo -e "${BLUE}${BOLD}Satellite version:${RESET}\n$SAT_RELEASE\n"
    echo -e "${BLUE}${BOLD}Hammer ping:${RESET}\n$SAT_HEALTH_CHECK\n"
    echo -e "${BLUE}${BOLD}Custom or default certificates:${RESET}\n$SAT_CERTS\n"
    echo -e "${BLUE}${BOLD}Custom hiera:${RESET}\n$SAT_HIERA\n"
    #echo -e "${BLUE}${BOLD}Content Hosts with highest https traffic:${RESET}\n$SAT_TRAFFIC\n"
    echo -e "${BLUE}${BOLD}Capsule overview:${RESET}\n$SAT_CAPSULES\n"
    echo -e "${BLUE}${BOLD}Organizations & SCA:${RESET}\n$SAT_SCA\n"
    echo -e "${BLUE}${BOLD}Running tasks:${RESET}\n$SAT_TASKS_RUNNING\n"
    echo -e "${BLUE}${BOLD}Paused tasks:${RESET}\n$SAT_TASKS_PAUSED\n"
    echo -e "${BLUE}${BOLD}Satellite settings (nil=default):${RESET}\n$SAT_SETTINGS\n"
    echo -e "${BLUE}${BOLD}Ansible integration:${RESET}\n$SAT_ANSIBLE\n"
    echo -e "${BLUE}${BOLD}Tuning profile:${RESET}\n$SAT_TUN_PROFILE\n"
    echo -e "${BLUE}${BOLD}Puma status:${RESET}\n$SAT_TUN_PUMA_STAT\n"
    echo -e "${BLUE}${BOLD}Puma workers & threads:${RESET}\n$SAT_TUN_PUMA_WORKERS\n"
    echo -e "${BLUE}${BOLD}Puma DB pool:${RESET}\n$SAT_TUN_PUMA_POOL\n"
    echo -e "${BLUE}${BOLD}Dynflow sidekiq status:${RESET}\n$SAT_TUN_DYNFLOW\n"
    echo -e "${BLUE}${BOLD}Httpd tuning:${RESET}\n$SAT_TUN_HTTPD\n"
    echo -e "${BLUE}${BOLD}Puppet tuning:${RESET}\n$SAT_TUN_PUPPET\n"
    echo -e "${BLUE}${BOLD}Postgresql tuning:${RESET}\n$SAT_TUN_PGSQL\n"
    #echo -e "${BLUE}${BOLD}Qdrouterd tuning:${RESET}\n$SAT_TUN_QDROUTERD\n"
    #echo -e "${BLUE}${BOLD}Qpidd tuning:${RESET}\n$SAT_TUN_QPIDD\n"
    echo -e "${BLUE}${BOLD}/var/lib/candlepin usage:${RESET}\n$SAT_FS_CP\n"
    echo -e "${BLUE}${BOLD}/var/lib/pgsql usage:${RESET}\n$SAT_FS_PGSQL\n"
    echo -e "${BLUE}${BOLD}Foreman db table sizes:${RESET}\n$SAT_DB_FOREMAN\n"
    echo -e "${BLUE}${BOLD}Candlepin db table sizes:${RESET}\n$SAT_DB_CP\n"
    echo -e "${BLUE}${BOLD}Fact names:${RESET}\n$SAT_DB_FACTS\n"

}


# Get RHEL version

if [[ $(grep -c "6." ./etc/redhat-release) -eq 1 ]] || [[ $(grep -c "7." ./etc/redhat-release) -eq 1 ]]; then
    rhel_7_tasks
    
elif [[ $(grep -c "8." ./etc/redhat-release) -eq 1 ]] || [[ $(grep -c "9." ./etc/redhat-release) -eq 1 ]]; then
    rhel_8_tasks

else
    echo -e "${YELLOW}${BOLD}Not a supported RHEL version. Running default ..${RESET}"
    rhel_8_tasks
fi


# Get Insights
if [ $(grep -c ^insights-client ./installed-rpms) -eq 1 ]; then
    insights_tasks
else
    echo -e "${YELLOW}${BOLD}Insights not configured. Skipping..${RESET}"
fi

# Get Satellite version

if [[ $(grep -c "^satellite-6." ./installed-rpms) -eq 1 ]]; then
    sat_6_tasks
else
    echo -e "${YELLOW}${BOLD}Not a satellite server. Skipping..${RESET}"
fi

