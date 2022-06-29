#!/bin/bash



install_docker_compose () {

    #install docker-compose
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    systemctl status docker

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
    systemctl enable docker
    systemctl start docker

}


install_docker_rhel_yum(){

    #install docker-ce
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yes | yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl start docker
    systemctl enable docker 

}

docker_rockyos(){

    #install docker-ce
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    yes | dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl start docker
    systemctl enable docker

}




main (){


    os=`cat /etc/os-release | grep  "^ID="`
    osversion=`echo $os |  sed 's/"//g' | sed 's/ID=//g'`
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

main
install_docker_compose
