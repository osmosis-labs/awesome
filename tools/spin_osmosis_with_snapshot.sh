#! /bin/bash -x 
set -e 

#PEERS=""
OSMOSIS_VERSION="$2"

main() {
	version_check
        basic_setup
        install_go
        osmosis
        get_snapshot
#       get_peers
#       spin_up
}

version_check() {
         if [ -z "$OSMOSIS_VERSION" ]; then
                echo "--osmosis vX.Y.Z' is required"
                exit 1
         fi
}

basic_setup() {
       sudo apt-get update -y && sudo apt-get upgrade -y
       sudo apt-get install build-essential wget -y
}


install_go() {
        #sudo rm -rf /usr/local/go
        wget https://dl.google.com/go/go1.17.1.linux-amd64.tar.gz
        tar -xvf go1.17.1.linux-amd64.tar.gz
        sudo mv go /usr/local
        GOROOT=/usr/local/go
        PATH=$GOROOT/bin:$PATH
}


osmosis(){
        git clone https://github.com/osmosis-labs/osmosis
        cd osmosis
        git fetch && git checkout $OSMOSIS_VERSION
        make build
        ./build/osmosisd init --chain-id osmosis-1 BestDEX
}


# get snapshot from ChainLayer QuickSync
get_snapshot() {
        sudo apt-get install aria2 liblz4-tool -y
        DATE=$(date +%Y%m%d) && ((DATE-= 1))
        FILENAME=osmosis-1-default.$DATE.0510.tar.lz4
        echo "snapshot date : $DATE"

        cd /$HOME/.osmosisd
        if [[ ! -f $FILENAME || -f $FILENAME.aria2 ]]; then
                aria2c -x5 https://getsin.quicksync.io/$FILENAME
        fi

        lz4 -d $FILENAME | tar xf -
}


get_peers() {
        sed -i "s/persistent_peers = \"\"persistent_peers = \"$PEERS\"/g" $HOME/.osmosisd/config/config.toml
}


spin_up() {
        ./$HOME/osmosis/build/osmosisd start
}

main; exit
