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
           cat << EOF > $deamonpath
           {
           #echo '  "data-root": "/data/docker",
           "log-driver": "local",
           "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
           "tls": true,
           "tlscacert": "/etc/docker/certs/ca.pem",
           "tlscert": "/etc/docker/certs/server-cert.pem",
           "tlskey": "/etc/docker/certs/server-key.pem",
           "tlsverify": true
           }
EOF

       else
               echo "Creating daemon.json"
               cat << EOF > $deamonpath
               {
               #echo '  "data-root": "/data/docker",
               "log-driver": "local",
               "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
               "tls": true,
               "tlscacert": "/etc/docker/certs/ca.pem",
               "tlscert": "/etc/docker/certs/server-cert.pem",
               "tlskey": "/etc/docker/certs/server-key.pem",
               "tlsverify": true
                }
EOF    
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
