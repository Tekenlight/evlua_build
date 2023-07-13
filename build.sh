#!/bin/bash

# Init config file
. ./config.env

# Init Utils
source ./utils.sh

# Print platform name
PN=$(platform_name)
rm -rf $BUILD_PATH"platform"

function clone_libraries() {
    build_type=$1
    echo "cloning $build_type"
    if [ $build_type == "foundation" ]; then
        for REPO_URL in "${REPOS[@]}"; do
            clone_repo $REPO_URL $REPO_DIRECTORY
        done
    else
        for REPO_URL in "${EVLUA_REPOS[@]}"; do
            clone_repo $REPO_URL $EVLUA_REPO_DIRECTORY
        done
    fi
}

function build_foundation() {
    # list all the clone directory and build cmake files
    for MODULE in "$REPO_DIRECTORY"/*; do
        echo "Folder: $MODULE"
        DIRECTORY_NAME=$(echo "$MODULE" | awk -F/ '{print $(NF)}')
        echo "Directory name: $DIRECTORY_NAME"
        if [ "$DIRECTORY_NAME" == "evpoco" ] || [ "$DIRECTORY_NAME" == "lua" ]; then
            echo "skipping evpoco/lua..."
        elif [ "$DIRECTORY_NAME" == "lua-5-3-5-build" ]; then
            echo "========== Installing: $DIRECTORY_NAME =========="
            cd $MODULE
            mkdir -p $MODULE"/src"
            cp -r ../lua/* ./src/
            if [ "$SYSTEM_TYPE" == "arm64" ]; then
                echo "Building lua for macosx"
                make macosx
            else
                echo "Building lua for linux"
                make linux
            fi
            mkdir -p $LUA_INSTALLATION_DIR
            make install INSTALL_TOP=$LUA_INSTALLATION_DIR
            echo "========== Done =========="
        elif [ "$DIRECTORY_NAME" == "libev" ] || [ "$DIRECTORY_NAME" == "libxml2" ]; then
            echo "========== Installing: $DIRECTORY_NAME =========="
            cd $MODULE
            if [ "$DIRECTORY_NAME" == "libxml2" ]; then
                configure_and_make false "libxml2"
            else
                configure_and_make true "libev"
            fi
            echo "========== Done =========="
        elif [ "$DIRECTORY_NAME" == "http-parser" ]; then
            echo "========== Installing: $DIRECTORY_NAME =========="
            cd $MODULE
            make install PREFIX=/usr DESTDIR=$INSTALL_DIRECTORY
            echo "========== Done =========="
        else
            echo "===================="
            echo "Creating build directory"
            MODULE_BUILD_DIRECTORY=$BUILD_DIRECTORY"/"$DIRECTORY_NAME
            echo "Module build directory: $MODULE_BUILD_DIRECTORY"
            mkdir -p $MODULE_BUILD_DIRECTORY
            echo "===================="
            cd $MODULE_BUILD_DIRECTORY
            echo "========== Building: $DIRECTORY_NAME =========="
            cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr $REPO_DIRECTORY"/"$DIRECTORY_NAME"/."
            cmake --build .
            echo "========== Installing: $DIRECTORY_NAME =========="
            make install DESTDIR=$INSTALL_DIRECTORY
            echo "========== Done =========="
        fi
    done
}

function install_luarocks_if_not_already() {
    if check_if_directory_is_not_empty "$LUAROCKS_INSTALLATION_DIR"; then
        echo "luarocks already installed..."
    else
        echo "luarocks not installed..."
        mkdir -p $THIRD_PARTY_LIBRARY
        cd $THIRD_PARTY_LIBRARY
        if ! check_if_directory_is_not_empty "$THIRD_PARTY_LIBRARY/luarocks-3.8.0"; then
            wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
            tar xvzf luarocks-3.8.0.tar.gz
        fi
        cd luarocks-3.8.0
        mkdir -p $LUAROCKS_INSTALLATION_DIR
        ./configure  --prefix=$LUAROCKS_INSTALLATION_DIR --rocks-tree=$LUAROCKS_ROOT_INSTALLATION_DIR --with-lua=$LUA_INSTALLATION_DIR
        make
        make install
    fi
}

function install_postgres_if_not_already() {

    if check_if_directory_is_not_empty "$POSTGRES_INSTALL_DIRECTORY"; then
        echo "postgresql already installed..."
    else
        echo "psql not installed..."
        mkdir -p $THIRD_PARTY_LIBRARY
        cd $THIRD_PARTY_LIBRARY
        POSTGRES_DIRECTORY=$THIRD_PARTY_LIBRARY"/postgresql-15.3"

        if ! check_if_directory_is_not_empty "$POSTGRES_DIRECTORY"; then
            wget https://ftp.postgresql.org/pub/source/v15.3/postgresql-15.3.tar.gz
            tar xvzf postgresql-15.3.tar.gz
        fi
        echo "postgres will be installed in $POSTGRES_INSTALL_DIRECTORY"
        cd $POSTGRES_DIRECTORY
        CFLAGS=-fPIC ./configure
        cd $POSTGRES_DIRECTORY/src/interfaces/libpq/
        make
        make install DESTDIR=$POSTGRES_INSTALL_DIRECTORY
        cd $POSTGRES_DIRECTORY/src/bin/pg_config
        make install DESTDIR=$POSTGRES_INSTALL_DIRECTORY
        cd $POSTGRES_DIRECTORY/src/backend
        make generated-headers
        cd $POSTGRES_DIRECTORY/src/include
        make install DESTDIR=$POSTGRES_INSTALL_DIRECTORY
        cd $POSTGRES_DIRECTORY/src/common
        make install DESTDIR=$POSTGRES_INSTALL_DIRECTORY
        cd $POSTGRES_DIRECTORY/src/port
        make install DESTDIR=$POSTGRES_INSTALL_DIRECTORY
    fi
}

function install_evpoco() {
    echo "========== evpoco =========="
    EVPOCO_BUILD_DIRECTORY=$BUILD_DIRECTORY"/evpoco"
    echo "========== Directory name: $EVPOCO_BUILD_DIRECTORY =========="
    mkdir -p $EVPOCO_BUILD_DIRECTORY
    cd $EVPOCO_BUILD_DIRECTORY
    if [ "$SYSTEM_TYPE" == "arm64" ]; then
        echo "Building system for macosx"
        cmake -DPG_BUILD_PATH=$POSTGRES_INSTALL_DIRECTORY -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIRECTORY/usr -DLUA_INSTALL_DIR=$LUA_INSTALLATION_DIR -DTARGET_OS_OSX_HOMEBREW=1 -DCMAKE_OSX_ARCHITECTURES="arm64" $REPO_DIRECTORY/evpoco/.
    else
        echo "Building system for ubuntu"
        cmake -DPG_BUILD_PATH=$POSTGRES_INSTALL_DIRECTORY -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIRECTORY/usr -DLUA_INSTALL_DIR=$LUA_INSTALLATION_DIR $REPO_DIRECTORY/evpoco/.
    fi
    cmake --build .
    make install
}

function build_evlua() {
    echo "clean .luarocks if exists"
    rm -r $LUAROCKS_ROOT_INSTALLATION_DIR

    # list all the clone directory and build cmake files
    for MODULE in "$EVLUA_REPO_DIRECTORY"/*; do
        echo "Folder: $MODULE"
        DIRECTORY_NAME=$(echo "$MODULE" | awk -F/ '{print $(NF)}')
        echo "Directory name: $DIRECTORY_NAME"
        echo "========== Installing: $DIRECTORY_NAME =========="

        if [ $DIRECTORY_NAME == "service_utils" ]; then
            cd $MODULE
            cd ../lua-uri
            $LUAROCKS_INSTALLATION_DIR/bin/luarocks make
        elif [ lua-uri ]; then
            echo "lua-uri will be installed at the time of service utils installation"
        fi
        cd $MODULE
        $LUAROCKS_INSTALLATION_DIR/bin/luarocks make
        echo "========== Done =========="
    done
}

function copy_evlua_libraries() {
    cp -r $LUAROCKS_ROOT_INSTALLATION_DIR/* $INSTALL_DIRECTORY/usr
}

function build_executable() {
    mkdir -p $EXCECUTABLE_PATH
    echo "building executable in $EXCECUTABLE_PATH for $PN"
    if [ "$PN" == "arm64" ]; then
        hdiutil create -format UDRW -srcfolder $INSTALL_DIRECTORY $EXCECUTABLE_PATH/evlua.dmg
    else
        mkdir -p $INSTALL_DIRECTORY/DEBIAN
        cp $BASE_PATH"controlfile" $INSTALL_DIRECTORY/DEBIAN/control
        chmod -R 755 $INSTALL_DIRECTORY/DEBIAN
        chmod -R 755 $INSTALL_DIRECTORY/usr
        dpkg-deb --build $INSTALL_DIRECTORY $EXCECUTABLE_PATH/evlua.deb
    fi
}

clone_libraries foundation; build_foundation; install_luarocks_if_not_already; install_postgres_if_not_already; install_evpoco; clone_libraries evlua; build_evlua; copy_evlua_libraries; build_executable