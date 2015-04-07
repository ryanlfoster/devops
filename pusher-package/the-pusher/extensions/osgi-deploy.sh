deployOsgiPackage () {

    server=$1
    felixBase=$2

    log detail "Copying & extracting $currentContextPath bundles to $server:$baseDirectory/$felixBase..."
    ssh $localUser@$server "mkdir -p '$baseDirectory/$felixBase/bundle'"
    scp $workspaceDirectory/webapps/*$currentContextPath*.zip $localUser@$server:$baseDirectory/$felixBase/bundle/
    ssh $localUser@$server "unzip -qo $baseDirectory/$felixBase/bundle/*$currentContextPath*.zip -d $baseDirectory/$felixBase/bundle/"
    ssh $localUser@$server "mv $baseDirectory/$felixBase/bundle/ep-rest-studio*.war $baseDirectory/$felixBase/bundle/ep-rest-studio.jar"
    ssh $localUser@$server "mv $baseDirectory/$felixBase/bundle/ep-rs-system-ready*.jar $baseDirectory/$felixBase/bundle/ep-rs-system-ready.jar"

    log detail "Starting $currentContextPath on $server..."
    ssh $localUser@$server "$baseDirectory/felix-${currentContextPath}/init.sh start"

    return 0
}


deployFelixContainer () {

    context=$1

    containerBase="felix-${felixVersion}"
    containerName="felix-${felixVersion}-${context}"
    containerNameLink="felix-${context}"

    if ssh $localUser@$server "test ! -d '$baseDirectory/$containerNameLink'"; then
        log detail "No $context felix directory found on $server...  deploying default Felix package."
        scp $workspaceDirectory/webapps/$felixPackage $localUser@$server:$baseDirectory
        ssh $localUser@$server "unzip -qo '$baseDirectory/$felixPackage' -d '$baseDirectory' &&
            DATE=\$(date +%D-%H%M%S|sed -e 's/\//-/g') &&
            cp -R '$baseDirectory/$containerBase' \"$baseDirectory/$containerName-\$DATE\" &&
            ln -s \"$baseDirectory/$containerName-\$DATE\" '$baseDirectory/$containerNameLink'"

        # Move JDBC driver jars into felix
        scp $workspaceDirectory/database/jdbc/* $localUser@$server:$baseDirectory/$containerNameLink/
    else
        # Stop Felix if it's running
        log detail "Stopping Felix on $server if running..."
        # We pass in the default PID location so that we know we can test for its existence and not fail
        ssh $localUser@$server "if test -e '$baseDirectory/$containerNameLink/felix.pid' && ps -p \"\$(cat '$baseDirectory/$containerNameLink/felix.pid')\" >/dev/null; then
                FELIX_PID='$baseDirectory/$containerNameLink/felix.pid' $baseDirectory/$containerNameLink/init.sh stop
            fi"

        # TO-DO:
        # Check for number of copies of the felix and delete any over the max
        #oldFelixDeployments=`ssh $localUser@$i "ls $baseDirectory | grep apache-felix | wc -l"`
        #if [[ $oldFelixDeployments -gt $maxOldFelixDeployments ]]; then
        #    ssh $localUser@$i "cd $baseDirectory && ls -t | grep apache-felix | awk 'NR>max' max=$maxOldFelixDeployments | xargs rm -rf"
        #fi

        log detail "Making a copy of the $containerNameLink directory and switching symlink on $server..."
        ssh $localUser@$server "rm -f '$baseDirectory/$containerNameLink' &&
            DATE=\$(date +%D-%H%M%S|sed -e 's/\//-/g') &&
            PREV=\$(ls -t '$baseDirectory' | grep '$containerName-[0-9]\+' | head -n 1) &&
            cp -R \"$baseDirectory/\$PREV\" \"$baseDirectory/$containerName-\$DATE\" &&
            ln -s \"$baseDirectory/$containerName-\$DATE\" '$baseDirectory/$containerNameLink' &&
            rm -f '$baseDirectory/$containerNameLink/bundle/'*"
    fi

    # Do filtering depending on context
    _filterFelix $context

    return 0
}


_filterFelix () {

    context=$1

    ssh $localUser@$server "perl -p -i -e 's|http.port=\d+|http.port=${currentPorts[0]}|g' $baseDirectory/$containerNameLink/conf/config.properties"
    ssh $localUser@$server "perl -p -i -e 's|http.context_path=/[\w\-\_\d]+|http.context_path=/${context}|g' $baseDirectory/$containerNameLink/conf/config.properties"
    ssh $localUser@$server "perl -p -i -e 's|^NAME=FELIX|NAME=${context}|g' '$baseDirectory/$containerNameLink/init.sh'"

    return 0
}
