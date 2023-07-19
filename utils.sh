check_if_directory_is_not_empty() {
    local directory=$1
    echo "checking if $directory exists and is empty..."
    if [[ -d "$directory" && -n "$(ls -A "$directory")" ]]; then
        echo "The $directory exists and is not empty."
        return 0
    else
        echo "The $directory either does not exist or is empty."
        return 1
    fi
}

get_directory_name_from_absoulte_path() {
    return $(echo "$MODULE" | awk -F/ '{print $(NF)}')
}

clone_repo() {
    REPO_URL="$1"
    REPO_DIR="$2"
    REPO_CLONE_DIRECTORY=$REPO_DIR"/"$(echo "$REPO_URL" | awk -F/ '{print $(NF)}' | sed 's/\.git$//')
    echo "cloning into $REPO_CLONE_DIRECTORY"
    if check_if_directory_is_not_empty "$REPO_CLONE_DIRECTORY" ; then
        echo "$REPO_CLONE_DIRECTORY already exists, checking for update if any..."
        cd $REPO_CLONE_DIRECTORY
        git pull
    else
        mkdir -p $REPO_CLONE_DIRECTORY
        git clone $REPO_URL $REPO_CLONE_DIRECTORY
    fi
}

configure_and_make() {
    local use_python=$1
    local type=$2
    echo "use python: $use_python and type: $type"
    # Run the autoreconf -i command and capture the output
    autoreconf -i
    if [ use_python == true ]; then
        echo "configuring $type with python"
        ./configure --prefix=$INSTALL_DIRECTORY/usr --exec-prefix=$INSTALL_DIRECTORY/usr
    else
        echo "configuring $type without python"
        ./configure --without-python --prefix=$INSTALL_DIRECTORY/usr --exec-prefix=$INSTALL_DIRECTORY/usr
    fi
    make
    make install
}

check_if_installed() {
    $1 --version >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

platform_name() {
    PLATFORM_TYPE=$(uname -m)
    echo "$PLATFORM_TYPE"
}