deployEpConfigAndProperties () {

    configPath=$baseDirectory

    # We could likely remove the existence check - we would just always deploy
    # And the dir might be a variable instead of hardcoded
    # Don't check for existence, just deploy them.
    log detail "Deploying EP properties and config files to $configPath ..."
    scp -qr $pusherConfigDirectory/files/* $localUser@$server:$configPath/

    filterConfigFiles $configPath

    return 0
}

filterConfigFiles () {

    configPath=$1
    mercuryPort=$(echo "$mercuryPorts" | cut -d' ' -f1)
    #${mercuryContextPath}

    log detail "Filtering config files for $appServer ..."

    # Assume port is 8080 (typical for most app containers) unless weblogic
    cePort="8080"
    if [ "$appServer" == "weblogic" ]; then
        cePort="7001"
        ssh $localUser@$server "perl -p -i -e 's|8080|$cePort|g' $1/cortex/system/config/authClientHost.cfg"
    fi

    return 0
}

