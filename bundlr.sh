#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Request token"
"Run docker"
"Check logs"
"Balance"
"Create validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install curl wget jq libpq-dev libssl-dev \
build-essential pkg-config openssl ocl-icd-opencl-dev \
libopencl-clang-dev libgomp1 -y
apt install docker-compose
install() {
	cd
	if ! docker --version; then
		echo -e "${C_LGn}Docker installation...${RES}"
		sudo apt update && sudo apt upgrade -y
		sudo apt install curl apt-transport-https ca-certificates gnupg lsb-release -y
		. /etc/*-release
		wget -qO- "https://download.docker.com/linux/${DISTRIB_ID,,}/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt update
		sudo apt install docker-ce docker-ce-cli containerd.io -y
		docker_version=`apt-cache madison docker-ce | grep -oPm1 "(?<=docker-ce \| )([^_]+)(?= \| https)"`
		sudo apt install docker-ce="$docker_version" docker-ce-cli="$docker_version" containerd.io -y
	fi
	if ! docker-compose --version; then
		echo -e "${C_LGn}Docker Сompose installation...${RES}"
		sudo apt update && sudo apt upgrade -y
		sudo apt install wget jq -y
		local docker_compose_version=`wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name"`
		sudo wget -O /usr/bin/docker-compose "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`"
		sudo chmod +x /usr/bin/docker-compose
		. $HOME/.bash_profile
	fi
	if [ "$dive" = "true" ] && ! dpkg -s dive | grep -q "ok installed"; then
		echo -e "${C_LGn}Dive installation...${RES}"
		wget https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
		sudo apt install ./dive_0.9.2_linux_amd64.deb
		rm -rf dive_0.9.2_linux_amd64.deb
	fi
}
uninstall() {
	echo -e "${C_LGn}Docker uninstalling...${RES}"
	sudo dpkg -r dive
	sudo systemctl stop docker.service docker.socket
	sudo systemctl disable docker.service docker.socket
	sudo rm -rf `systemctl cat docker.service | grep -oPm1 "(?<=^#)([^%]+)"` `systemctl cat docker.socket | grep -oPm1 "(?<=^#)([^%]+)"` /usr/bin/docker-compose
	sudo apt purge docker-engine docker docker.io docker-ce docker-ce-cli -y
	sudo apt autoremove --purge docker-engine docker docker.io docker-ce -y
	sudo apt autoclean
	sudo rm -rf /var/lib/docker /etc/appasudo rmor.d/docker
	sudo groupdel docker
	sudo rm -rf /etc/docker /usr/bin/docker /usr/libexec/docker /usr/libexec/docker/cli-plugins/docker-buildx /usr/libexec/docker/cli-plugins/docker-scan /usr/libexec/docker/cli-plugins/docker-app /usr/share/keyrings/docker-archive-keyring.gpg
}


$function
echo -e "${C_LGn}Done!${RES}"


curl https://sh.rustup.rs -sSf | sh -s -- -y


source "$HOME/.cargo/env" && \
echo -e "\n$(cargo --version).\n"


curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && \
sudo apt-get install nodejs -y && \
echo -e "\nnodejs > $(node --version).\nnpm  >>> v$(npm --version).\n"


mkdir $HOME/bundlr; cd $HOME/bundlr


git clone \
--recurse-submodules https://github.com/Bundlr-Network/validator-rust.git


cd $HOME/bundlr/validator-rust && \
cargo run --bin wallet-tool create > wallet.json


break
;;

"Request token")

cd $HOME/bundlr/validator-rust && \
cargo run --bin wallet-tool show-address \
--wallet wallet.json | jq ".address" | tr -d '"'

sleep 2

echo "========================================================================================================================"
echo "In order to receive tokens, you need copy the last adress above, go to Bundlr faucet website
and request tokens (https://bundlr.network/faucet)"
echo "========================================================================================================================"

break
;;

"Check logs")

cd $HOME/bundlr/validator-rust && \
docker-compose logs -f --tail 10

break
;;

"Run docker")

PORT=2109
echo "============================================================"
echo "Enter your wallet address"
echo "============================================================"
read ADDRESS
echo export PORT=${PORT} >> $HOME/.bash_profile
echo export ADDRESS=${ADDRESS} >> $HOME/.bash_profile
echo export BUNDLR_PORT=${PORT} >> $HOME/.bash_profile
source $HOME/.bash_profile

sudo tee <<EOF >/dev/null $HOME/bundlr/validator-rust/.env
PORT=${BUNDLR_PORT}
VALIDATOR_KEY=./wallet.json
BUNDLER_URL=https://testnet1.bundlr.network
GW_WALLET=./wallet.json
GW_CONTRACT=RkinCLBlY4L5GZFv8gCFcrygTyd5Xm91CzKlR6qxhKA
GW_ARWEAVE=https://arweave.testnet1.bundlr.network
EOF


cd $HOME/bundlr/validator-rust && \
docker-compose up -d

sleep 2

cd $HOME/bundlr/validator-rust && \
npm i -g @bundlr-network/testnet-cli

sleep 2

echo -e 'To check logs: \e[1m\e[32mcd $HOME/bundlr/validator-rust && \
docker-compose logs -f --tail 10'
echo -e 'Close logs Control+C and continiue install'

break
;;

"Balance")

cd $HOME/bundlr/validator-rust && \
testnet-cli balance $ADDRESS

break
;;

"Create validator")

cd $HOME/bundlr/validator-rust && \
testnet-cli join RkinCLBlY4L5GZFv8gCFcrygTyd5Xm91CzKlR6qxhKA \
-w ./wallet.json \
-u "http://$(wget -qO- eth0.me):${BUNDLR_PORT}" \
-s 25000000000000

break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
