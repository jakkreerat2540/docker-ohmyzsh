#!/bin/bash

# define variables
os=`cat /etc/os-release | grep  "^ID="`
osversion=`echo $os |  sed 's/"//g' | sed 's/ID=//g'`
get_service_docker=`systemctl status docker | awk 'NR==1{print $2}'`
not_found="Unit"

install_docker_compose () {

    rm -rf /usr/local/bin/docker-compose
    #install docker-compose
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    ln -s $DOCKER_CONFIG/cli-plugins/docker-compose /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    # show version docker compose
    docker compose version
    systemctl enable docker.socket 
    systemctl start docker.socket
    systemctl enable containerd 
    systemctl start containerd 
    systemctl enable docker
    systemctl start docker

}


install_docker_ubuntu () {
    
    #install docker-ce
    apt-get -y update && apt-get -y upgrade
    apt-get -y install ca-certificates curl gnupg lsb-release make
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo  gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt -y update && apt -y install docker-ce docker-ce-cli containerd.io
    
   

}

install_docker_fedora(){

    dnf -y install dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

}

install_docker_rhel_yum(){

    #install docker-ce
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   
     

}

docker_rockyos(){

    #install docker-ce
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    yes | dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin


    

}


remove_docker_fedora(){

    dnf remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd

}

remove_docker_ubuntu () {
    
    #remove docker-ce
    
    apt-get -y remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    apt-get -y autoremove
    apt-get -y clean
    rm -rf /var/lib/docker
    rm -rf /etc/docker
    rm -rf /var/run/docker.sock

}

remove_docker_rhel_yum () {
    
    #remove docker-ce
    yum -y remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    yum -y autoremove
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd

}


remove_docker_rockyos () {
    
    #remove docker-ce
    dnf -y remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    dnf -y autoremove
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm -rf /var/run/docker.sock
    dnf -y clean all
    dnf makecache

}

stop_service() {
    
    systemctl stop containerd
    systemctl stop docker.socket 
    systemctl stop docker

}


install_afeter_remove(){
    
    
    if [ $osversion == "ubuntu" ]; then
            install_docker_ubuntu
        elif [ $osversion == "centos" ]; then
            install_docker_rhel_yum
        elif [ $osversion == "rocky" ]; then
            docker_rockyos
        elif [ $osversion == "debian" ]; then
            install_docker_ubuntu
        elif [ $osversion == "fedora" ]; then
            install_docker_fedora
        else
            echo "OS not supported"
        fi


}

check_service() {

    dockers=`systemctl status docker | awk 'NR==3{print $2}'`
    containerds=`systemctl status containerd | awk 'NR==3{print $2}'`
    docker_socket=`systemctl status docker.socket | awk 'NR==3{print $2}'`

    if [ $dockers == "active" ] && [ $containerds == "active" ] && [ $docker_socket == "active" ]; then
        echo "Docker and containerd are running"
    else
        echo "docker status:"$dockers "containerd status:"$containerds "docker.socket status:"$docker_socket
    fi


}


create_docker_daemon() {

    # create docker daemon 
    echo "{
    \"data-root\": \"/var/lib/docker\",
    \"log-driver\": \"json-file\",
    \"log-opts\": {
        \"max-size\": \"100m\",
        \"max-file\": \"3\"
     }
     }
    " > /etc/docker/daemon.json




}



main (){


    #sudo groupadd docker
    #sudo usermod -aG docker $USER # non root user
    #newgrp docker

    if [ $get_service_docker == "docker.service" ]; then
        
        if [ $osversion == "ubuntu" ]; then
            stop_service
            remove_docker_ubuntu
        elif [ $osversion == "centos" ]; then
            stop_service
            remove_docker_rhel_yum
        elif [ $osversion == "rocky" ]; then
            stop_service
           remove_docker_rockyos
        elif [ $osversion == "debian" ]; then
            stop_service
            remove_docker_ubuntu
        elif [ $osversion == "fedora" ]; then
            stop_service
            remove_docker_fedora
        else
            echo "OS not supported"
        fi
        install_afeter_remove    
    else
        if [ $osversion == "ubuntu" ]; then
            install_docker_ubuntu
        elif [ $osversion == "centos" ]; then
            install_docker_rhel_yum
        elif [ $osversion == "rocky" ]; then
            docker_rockyos
        elif [ $osversion == "debian" ]; then
            install_docker_ubuntu
        elif [ $osversion == "fedora" ]; then
            install_docker_fedora
        else
            echo "OS not supported"
        fi
    fi

    
    echo "Docker installed!"

}

main
install_docker_compose
check_service
