#!/bin/bash


# define variables
os=`cat /etc/os-release | grep  "^ID="`
osversion=`echo $os |  sed 's/"//g' | sed 's/ID=//g'`
get_service_docker=`systemctl status docker | grep "docker.service" | awk 'NR==1{print $2}'`

install_docker_compose () {

    #install docker-compose
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    sleep 2
    systemctl enable docker.socket && systemctl start docker.socket
    sleep 2
    systemctl enable containerd && systemctl start containerd 
    sleep 2
    systemctl enable docker && systemctl start docker

}


install_docker_ubuntu () {
    
    #install docker-ce
    apt-get -y update
    apt-get -y install ca-certificates curl gnupg lsb-release make
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt -y update
    apt-get -y install docker-ce docker-ce-cli containerd.io
    
   

}


install_docker_rhel_yum(){

    #install docker-ce
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yes | yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   
     

}

docker_rockyos(){

    #install docker-ce
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    yes | dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   
    

}



remove_docker_ubuntu () {
    
    #remove docker-ce
    apt-get -y remove docker-ce docker-ce-cli containerd.io docker-compose-plugin
    apt-get -y autoremove
    rm -rf /var/lib/docker
    rm -rf /etc/docker

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
            install_docker_rhel_yum
        else
            echo "OS not supported"
        fi


}


main (){


    useradd docker
    usermod -aG docker $USER

    if [ $get_service_docker == "docker.service" ]; then
        if [ $osversion == "ubuntu" ]; then
            remove_docker_ubuntu
        elif [ $osversion == "centos" ]; then
            remove_docker_rhel_yum
        elif [ $osversion == "rocky" ]; then
           remove_docker_rockyos
        elif [ $osversion == "debian" ]; then
            remove_docker_ubuntu
        elif [ $osversion == "fedora" ]; then
            install_docker_rhel_yum
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
            install_docker_rhel_yum
        else
            echo "OS not supported"
        fi
    fi

    install_docker_compose
    echo "Docker installed!"

}

main