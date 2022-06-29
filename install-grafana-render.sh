#!/bin/sh

install_nodejs_ubuntu() {
    # install nodejs && yarn
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo apt-get install -y npm
    npm install -g yarn
    apt-get -y install curl git
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt-get update && apt-get install -y yarn
    yarn --version 
}

install_nodejs_centos () {
    # install nodejs && yarn
    curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
    sudo yum install -y nodejs
    sudo yum install -y npm
    npm install -g yarn
    yum -y install curl git
    curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
    yum update && yum install -y yarn
    yarn --version
}


download_grafana_render () {
    # download grafana-render
    cd ~
    git clone https://github.com/grafana/grafana-image-renderer.git
    cp -r grafana-image-renderer /usr/local/bin/
    chmod +x /usr/local/bin/grafana-image-renderer
    cd /usr/local/bin/grafana-image-renderer
    yarn install --pure-lockfile 
    yarn run build

}

create_service () {
    # create service
    echo  "[Unit]"  > /etc/systemd/system/grafana-render.service
    echo "Description=Grafana Render" >> /etc/systemd/system/grafana-render.service
    echo "[Service]" >> /etc/systemd/system/grafana-render.service
    echo "WorkingDirectory=/usr/local/bin/grafana-image-renderer" >> /etc/systemd/system/grafana-render.service
    echo "ExecStart=node build/app.js server --port=8081 --port=0.0.0.0" >> /etc/systemd/system/grafana-render.service
    echo "Restart=always" >> /etc/systemd/system/grafana-render.service
    echo "[Install]" >> /etc/systemd/system/grafana-render.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/grafana-render.service
    
    # create service start
    systemctl daemon-reload
    systemctl enable grafana-render.service
    systemctl start grafana-render.service
    systemctl status grafana-render.service

}



create_script () {
    cd /usr/local/bin/grafana-image-renderer
    wget https://raw.githubusercontent.com/jakkreerat2540/docker-ohmyzsh/main/script.sh
}


create_service_centos () {
    # create service
    create_script
    echo  "[Unit]"  > /etc/systemd/system/grafana-render.service
    echo "Description=Grafana Render" >> /etc/systemd/system/grafana-render.service
    echo "[Service]" >> /etc/systemd/system/grafana-render.service
    echo "WorkingDirectory=/usr/local/bin/grafana-image-renderer" >> /etc/systemd/system/grafana-render.service
    echo "ExecStart=/bin/bash /usr/local/bin/grafana-image-renderer/script.sh" >> /etc/systemd/system/grafana-render.service
    echo "Restart=always" >> /etc/systemd/system/grafana-render.service
    echo "[Install]" >> /etc/systemd/system/grafana-render.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/grafana-render.service
    
    # create service start
    systemctl daemon-reload
    systemctl enable grafana-render.service
    systemctl start grafana-render.service
    systemctl status grafana-render.service

}


ubuntu () {

   read -p "Do you want to install nodejs and yarn? (y/n) " -n 1 -r
   if [[ $REPLY =~ ^[Yy]$ ]]
   then
       install_nodejs_ubuntu
   fi

    read -p "Do you want to download grafana-render? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        download_grafana_render
    fi

    read -p "Do you want to create service? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        create_service
    fi

}


centos () {
    read -p "Do you want to install nodejs and yarn? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        install_nodejs_centos
    fi

    read -p "Do you want to download grafana-render? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        download_grafana_render
    fi

    read -p "Do you want to create service? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        create_service_centos
    fi
}


main () {

    
    
    os=`cat /etc/os-release | sed '3!d'`
    osversion=`echo $os |  sed 's/"//g' | sed 's/ID=//g'`
    
    if [ $osversion  == "ubuntu" ]; then
        ubuntu
    elif [ $osversion  == "centos" ]; then
        centos
    elif [ $osversion  == "rocky" ]; then
        centos
    else 
        echo "Sorry, this script is not support your OS "
    fi
    

}

main



