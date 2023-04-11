#!/bin/bash


# stop docker 

function stop_docker {
    echo "Stopping docker"
    systemctl stop docker.socket docker 
}


# define variables
deamonpath="/etc/docker/daemon.json"
dockerservicepath="/lib/systemd/system/docker.service"
# create daemon.json
function create_daemon_json {

       if [ -f $deamonpath ]; then
              rm -rf $deamonpath
              echo "Creating daemon.json"
              echo '{' > $deamonpath
              #echo '"data-root": "/data/docker"', > $deamonpath
              #echo '"log-driver": "local"', >> $deamonpath
              echo '        "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"'], >> $deamonpath
              echo '        "tls"': true, >> $deamonpath 
              echo '        "tlscacert": "/etc/docker/certs/ca.pem"', >> $deamonpath
              echo '        "tlscert": "/etc/docker/certs/server-cert.pem"', >> $deamonpath 
              echo '        "tlskey": "/etc/docker/certs/server-key.pem"', >> $deamonpath
              echo '        "tlsverify"': true , >> $deamonpath
              echo '        "log-driver": "json-file"' , >> $deamonpath
              echo '        "log-opts": { "max-size": "1024m",  "max-file": "3" , "tag": "{{.ImageName}}|{{.Name}}|{{.ImageFullID}}|{{.FullID}}"} ' >> $deamonpath
              echo '}' >> $deamonpath


       else

              echo "Creating daemon.json"
              echo '{' > $deamonpath
              #echo '"data-root": "/data/docker"', > $deamonpath
              #echo '"log-driver": "local"', >> $deamonpath
              echo '        "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"'], >> $deamonpath
              echo '        "tls"': true, >> $deamonpath 
              echo '        "tlscacert": "/etc/docker/certs/ca.pem"', >> $deamonpath
              echo '        "tlscert": "/etc/docker/certs/server-cert.pem"', >> $deamonpath 
              echo '        "tlskey": "/etc/docker/certs/server-key.pem"', >> $deamonpath
              echo '        "tlsverify"': true , >> $deamonpath
              echo '        "log-driver": "json-file"' , >> $deamonpath
              echo '        "log-opts": { "max-size": "1024m",  "max-file": "3" , "tag": "{{.ImageName}}|{{.Name}}|{{.ImageFullID}}|{{.FullID}}"} ' >> $deamonpath
              echo '}' >> $deamonpath
       fi




}

# edit docker.service

function edit_docker_service {
       count=`cat /usr/lib/systemd/system/docker.service | sed -n "/#ExecStart/p" | wc -l`
       if [ $count == '1'  ]; then

              echo "add already in docker.service"
       
       else
              stop_docker
              sed -i 's/ExecStart/#ExecStart/g' $dockerservicepath
              sed -i '/#ExecStart/a ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock' $dockerservicepath
              systemctl daemon-reload
              systemctl start docker.socket docker
     
       
       fi

}




function main {

       count=`ls -la /etc/docker | grep  -w "certs" | wc -l`
       if [ $count == '1' ]; then
              create_daemon_json
              edit_docker_service
       else

              read -p "Do you want download generate certificate script? (y/n): " -n 1 -r
              if [[ $REPLY =~ ^[Yy]$ ]]
              then
                     wget https://raw.githubusercontent.com/jakkreerat2540/docker-ohmyzsh/main/gencerts.sh -O gencerts.sh
              fi

              echo "pls generate certs first"
       fi

       echo "i don't know what to do next"
}

main
