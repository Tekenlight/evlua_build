#!/bin/bash

#set build path
export BASE_PATH=$(pwd)/

# set config file
. ./config.env

# Init Utils
source ./utils.sh

# check if required paths are in the environment
CHECK_LUA_PATH=x$LUA_PATH
CHECK_LUA_CPATH=x$LUA_CPATH
CHECK_LD_LIBRARY_PATH=x$LD_LIBRARY_PATH

if [ "$CHECK_LUA_PATH" = "x" ] || [ "$CHECK_LUA_CPATH" = "x" ] || [ "$CHECK_LD_LIBRARY_PATH" = "x" ]; then
    echo "Please check if all the path set"
    echo "required LUA_PATH: found $LUA_PATH"
    echo "required LUA_CPATH: found $LUA_CPATH"
    echo "required LD_LIBRARY_PATH: found $LD_LIBRARY_PATH"
    exit 1
fi

# check if github params are in the environment
if [ "$GITHUB_USER_NAME" = "" ] || [ "$GITHUB_ACCESS_TOKEN" = "" ]; then
    echo "Please set the github credentails"
    echo "requried field GITHUB_USER_NAME and GITHUB_ACCESS_TOKEN"
    exit 1
fi

function display_usage() {
    echo "Usage: Build type required, possible values are [SUBSCRIBER|ADMIN|XCHANGE]"
}

function validate_build_type() {
    local build_type="$BUILD_TYPE"
    if [[ "$build_type" != "SUBSCRIBER" && "$build_type" != "ADMIN" && "$build_type" != "XCHANGE" ]]; then
        echo "Error: Invalid value for build type. Accepted values are SUBSCRIBER, ADMIN, or XCHANGE."
        exit 1
    fi
    echo "building $build_type"
}

if [ $# -eq 0 ]; then
    display_usage
    exit 1
else
    BUILD_TYPE=$1
    validate_build_type $BUILD_TYPE
fi

function clone_common_libraries() {
    local common_dir=$BIOP_REPO_DIRECTORY/common
    echo "Cloning common libraries into $common_dir"
    mkdir -p $common_dir
    for REPO_URL in "${BIOP_COMMON_REPOS[@]}"; do
        clone_repo $REPO_URL $common_dir
    done
}

function clone_libraries() {
    local build_type="$BUILD_TYPE"
    local prod_dir=$BIOP_REPO_DIRECTORY/$build_type
    echo "Cloning $build_type libraries into $prod_dir"
    mkdir -p $prod_dir
    if [ "$build_type" = "SUBSCRIBER" ]; then
        for REPO_URL in "${BIOP_SUBSCRIBER_REPOS[@]}"; do
            echo "cloning $REPO_URL"
            clone_repo $REPO_URL $prod_dir
        done
    elif [ "$build_type" = "XCHANGE" ]; then
        for REPO_URL in "${BIOP_XCHANGE_REPOS[@]}"; do
            echo "cloning $REPO_URL"
            clone_repo $REPO_URL $prod_dir
        done
    elif [ "$build_type" = "ADMIN" ]; then
        for REPO_URL in "${BIOP_ADMIN_REPOS[@]}"; do
            echo "cloning $REPO_URL"
            clone_repo $REPO_URL $prod_dir
        done
    fi
}

function build() {
    # build all common
    for MODULE in "$BIOP_REPO_DIRECTORY/common/*"; do
        echo "Folder: $MODULE"
        DIRECTORY_NAME=$(echo "$MODULE" | awk -F/ '{print $(NF)}')
        echo "Directory name: $DIRECTORY_NAME"
        echo "========== Installing: $DIRECTORY_NAME =========="
        build
        deploy
        echo "========== Done =========="
    done

    # build all specific
    for MODULE in "$BIOP_REPO_DIRECTORY/$BUILD_TYPE/*"; do
        echo "Folder: $MODULE"
        DIRECTORY_NAME=$(echo "$MODULE" | awk -F/ '{print $(NF)}')
        echo "Directory name: $DIRECTORY_NAME"
        echo "========== Installing: $DIRECTORY_NAME =========="
        cd $MODULE
        $INSTALL_DIRECTORY/usr/bin/build
        $INSTALL_DIRECTORY/usr/bin/deploy
        echo "========== Done =========="
    done
}

clone_common_libraries
clone_libraries
build