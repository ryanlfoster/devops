deployUI () {

    uiServer=$1

    # Variable configuration: Assume Cortex only deploy (hawaiian)
    uiPort=${uiServerPorts}
    uiScope=${cortexScope}
    cortexPath=${cortexContextPath}
    cortexPort=`echo "$cortexPorts" | cut -d' ' -f1`

    # Check if full integrator deploy and adjust accordingly
    if [ "$integratorServers" != "" ]; then
        cortexPath=${integratorContextPath}
        cortexPort=`echo "$integratorPorts" | cut -d' ' -f1`
        uiScope=${integratorScope}
    fi

    # Determine host URL for Apache. Try specific one, fall back on CE SF
    if [ "$uiHostUrl" != "" ]; then
        uiHostName=${uiHostUrl}
    else
        uiHostName=`echo ${sfDnsSnapitupus} | awk -F. '{ $1=""; print $0 }' | tr ' ' '.' | cut -b 2-`
    fi
    
    # Do it - start the deploy
    log detail "Deploying HTML5 Storefront on $uiServer ..."
    scp -q $workspaceDirectory/webapps/ui-storefront-*.zip $localUser@$uiServer:/ep/ui-storefront.zip
    ssh $localUser@$uiServer "unzip -qo /ep/ui-storefront.zip -d /ep/ui-storefront"

    log detail "Filtering HTML5 Storefront configuration file with path = $cortexPath and scope = $uiScope "
    _filterUiConfig

    log detail "Configuring Apache proxy for HTML5 SF (running on $uiHostName port $uiPort)"
    # Have to do this in two steps as sudo redirect doesn't play nice
    cat "$templatesDirectory/httpd-ui-storefront.conf" | env_filter | ssh $localUser@$uiServer "cat > '/tmp/ui-storefront.conf'"
    ssh $localUser@$uiServer -t -t "sudo mv /tmp/ui-storefront.conf /etc/httpd/conf.d/"
    log detail "Restarting Apache on $uiServer ..."
    ssh $localUser@$uiServer -t -t "sudo /etc/init.d/httpd restart"

    return 0
}

_filterUiConfig () {

    # We don't do this with a template because we cannot own this file

    ssh $localUser@$uiServer "perl -p -i -e 's|\"path\"\:\"\w+\"|\"path\":\"${cortexPath}\"|g' /ep/ui-storefront/public/ep.config.json"
    ssh $localUser@$uiServer "perl -p -i -e 's|\"scope\"\:\"\w+\"|\"scope\":\"${uiScope}\"|g' /ep/ui-storefront/public/ep.config.json"

    return 0
}
