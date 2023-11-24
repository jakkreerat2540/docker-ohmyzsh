#!/bin/bash
# This script prepare environment for Elasticsearch
en_version="8.11.1"
cdir=$(pwd)
# check debian or redhat for download 
os_id=$(cat /etc/os-release | grep -i "ID_LIKE" | awk -F "=" '{print $2}')
function set_sysctl() {
    # Set sysctl for Elasticsearch
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    sysctl -p
    # memory lock
    echo "elasticsearch soft memlock unlimited" >> /etc/security/limits.conf
    echo "elasticsearch hard memlock unlimited" >> /etc/security/limits.conf
    # nofile
    echo "elasticsearch soft nofile 65536" >> /etc/security/limits.conf
    echo "elasticsearch hard nofile 65536" >> /etc/security/limits.conf
    # kibana memory lock
    echo "kibana soft memlock unlimited" >> /etc/security/limits.conf
    echo "kibana hard memlock unlimited" >> /etc/security/limits.conf
    # nofile
    echo "kibana soft nofile 65536" >> /etc/security/limits.conf
    echo "kibana hard nofile 65536" >> /etc/security/limits.conf
}

function create_service() {
    # Create service for Elasticsearch
    if [[ ! -d "/etc/systemd/system/elasticsearch.service.d" ]] || [[ ! -f "/etc/systemd/system/elasticsearch.service.d/override.conf" ]]; then
        mkdir -p /etc/systemd/system/elasticsearch.service.d
        cat > /etc/systemd/system/elasticsearch.service.d/override.conf <<EOF
[Service]
LimitMEMLOCK=infinity
EOF
    systemctl daemon-reload
    systemctl enable elasticsearch.service
    # if exist override.conf
    elif [[ ! -f "/etc/systemd/system/elasticsearch.service.d/override.conf" ]]; then
        echo "override.conf exist"
    fi
}


function download_en() {

    if [[ "$os_id" =~ "debian" ]]; then
        # elasticsearch
        wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${en_version}-amd64.deb
        dpkg -i elasticsearch-${en_version}-amd64.deb
        # kibana
        wget https://artifacts.elastic.co/downloads/kibana/kibana-${en_version}-amd64.deb
        dpkg -i kibana-${en_version}-amd64.deb
    elif [[ "$os_id" =~ "rhel" ]]; then
        # download wget
        yum install -y wget
        # elasticsearch
        wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${en_version}-x86_64.rpm
        rpm -ivh elasticsearch-${en_version}-x86_64.rpm
        # kibana
        wget https://artifacts.elastic.co/downloads/kibana/kibana-${en_version}-x86_64.rpm
        rpm -ivh kibana-${en_version}-x86_64.rpm
    else
        echo "Not support this OS"
    fi


}


function generate_cert_kibana() {
    # generate cert for kibana no password and ca
    if [[ ! -f "/etc/kibana/kibana.crt" ]] || [[ ! -f "/etc/kibana/kibana.key" ]]; then
        cd /etc/kibana
        openssl req -x509 -batch -nodes -days 3650 -newkey rsa:2048 -keyout kibana.key -out kibana.crt
        # convert key to pem and crt to pem
        openssl pkcs8 -in kibana.key -topk8 -nocrypt -out kibana.pem
        openssl x509 -in kibana.crt -out kibana_bundle.pem
        cd $cdir
    else
        echo "kibana.crt and kibana.key exist"
    fi
    
}

function remove_kibana() {
    # check os for remove
    if [[ "$os_id" =~ "debian" ]]; then
        # remove elasticsearch
        dpkg -r elasticsearch
        # remove kibana
        dpkg -r kibana
    elif [[ "$os_id" =~ "rhel" ]]; then
        # remove elasticsearch
        rpm -e elasticsearch
        # remove kibana
        rpm -e kibana
    else
        echo "Not support this OS"
    fi

}

function main() {

    # check service before install
    if [[ ! -f "/etc/systemd/system/elasticsearch.service" ]] || [[ ! -f "/etc/systemd/system/kibana.service" ]]; then
        # set sysctl
        set_sysctl
        # create service
        create_service
        # download elasticsearch and kibana
        download_en
        if [[ -f "/etc/kibana/kibana.yml" ]]; then
            # generate cert for kibana
            generate_cert_kibana
        else
            echo "kibana.yml not exist"
        fi
    else
        echo "Elasticsearch service exist"
        read -p "Do you want to remove Elasticsearch and Kibana? (y/n): " remove_en
        if [[ "$remove_en" =~ "y" ]]; then
            # remove elasticsearch and kibana
            remove_kibana
        elif [[ "$remove_en" =~ "n" ]]; then
            exit 0
        else
            echo "Please enter y or n"
        fi

 
    fi

}

main
