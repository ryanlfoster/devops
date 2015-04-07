deployAemToAppServer () {
    local server="$1"
    local port="$2"
    local user="$3"
    local folderPath="$4"
    local processes="$5"
    local context="$6"

    log detail "AEM Commerce: Deploying to $server:$port/$context ..."
    _deployAemCommerce "$server" "$port" "$context"

    _waitForAem "$server" "$port" "$context"
    _restartAem "$server" "$port" "$user" "$folderPath" "$processes"
}

_deployAemCommerce () {
    local aemServer="$1"
    local aemPort="$2"
    local aemContext="$3"

    if [ "$aemContext" != "" ]
    then
	    aemContext=${aemContext}/
    fi

    # Prerequisites:
    # - EP for AEM bundles are included in deployment package
    # - EP has been deployed with AEM data and cortex is running
    # - jcrConnectorSettings.config is in place

    # Then EP packages
    _refreshAemPackage "$aemServer" "$aemPort" "$aemContext" "$installPackages"
    _waitForAem "$aemServer" "$aemPort" "$aemContext"
    _updateAemCortexPort "$aemServer" "$aemPort" "$aemContext"

    # The clean up AEM
    log detail "Running Data Store Garbage Collection on AEM..."
    _dataStoreGarbageCollection "$aemServer" "$aemPort" "$aemContext"
}

_refreshAemPackage() {
    local aemServer="$1"
    local aemPort="$2"
    local aemContext="$3"
    shift 3
    local aemPackages="$@"

    for aemPackage in `_reverse_array ${aemPackages[@]}`; do
        _waitForAem "$aemServer" "$aemPort" "$aemContext"
        _removeExistingAemPackage "$aemServer" "$aemPort" "$aemContext" "$aemPackage"
    done
    for aemPackage in $aemPackages; do
        _waitForAem "$aemServer" "$aemPort" "$aemContext"
        _uploadAemPackage "$aemServer" "$aemPort" "$aemContext" "$aemPackage"
    done
}

_waitForAem () {
    local server="$1"
    local port="$2"
    local context="$3"
    local rc="404"
    local MAX_ATTEMPTS=80
    local attempts=0
    local success=0
    local url="http://${server}:${port}/${context}libs/granite/core/content/login.html"
    
    log detail "Waiting for AEM to respond ."

    sleep 10

    while [ "$success" -lt "3" ]; do
        attempts=$[attempts + 1]
        if [ "$attempts" -gt "$MAX_ATTEMPTS" ]; then
            log detail "ERROR: AEM would not respond after $MAX_ATTEMPTS attempts."
            exit 1
        fi
        rc=`wget --timeout=2 --server-response --max-redirect=0 --output-document=/dev/null "${url}" 2>&1 | awk '/^  HTTP/{print \$2}'`
        if [[ "$rc" != "404" && "$rc" != "503" && "$rc" != "" ]]; then
            success=$[success + 1]
            echo -n "OK(${rc})"
        fi
        echo -n .
        sleep 5 
    done

    log detail "AEM responded OK."

    sleep 5
}

_reverse_array() {
    printf "%s\n" "$@" | tac
}

_uploadAemPackage() {
    local aemServer="$1"
    local aemPort="$2"
    local aemContext="$3"
    local aemPackage="$4"

    local latestPkgFull=$(_getLatestPackageName "$aemPackage")
    local latestBase=$(_getBaseName "$latestPkgFull")

    log detail "Uploading AEM Package '$latestPkgFull' to server: $aemServer:$aemPort/$aemContext"
    curl -vf -u "${aem_admin_user}:${aem_admin_pass}" -F file=@"${latestPkgFull}" -F install=true "http://${aemServer}:${aemPort}/${aemContext}crx/packmgr/service.jsp?name=${latestBase}"
}

_removeExistingAemPackage() {
    local aemServer="$1"
    local aemPort="$2"
    local aemContext="$3"
    local aemPackage="$4"

    local latestPkgFull=$(_getLatestPackageName "$aemPackage")
    local latestBase=$(_getBaseName "$latestPkgFull")

    log detail "Uninstalling AEM Package '$aemPackage' from server: $aemServer:$aemPort/$aemContext"
    curl -vf -u "${aem_admin_user}:${aem_admin_pass}" -X POST "http://${aemServer}:${aemPort}/${aemContext}crx/packmgr/service/.json/etc/packages/com/${latestBase}.zip?cmd=uninstall"

    log detail "Deleting AEM Package '$aemPackage' from server: $aemServer:$aemPort"
    curl -vf -u "${aem_admin_user}:${aem_admin_pass}" -X POST "http://${aemServer}:${aemPort}/${aemContext}crx/packmgr/service/.json/etc/packages/com/${latestBase}.zip?cmd=delete"
}

_getLatestPackageName() {
    local aemPackage="$1"
    local subDirectory="${2:-aemcomponents}"

    local pathToMatch="$workspaceDirectory/$subDirectory/$aemPackage"

    log debug "Getting latest file matching: $pathToMatch"
    local latestPkgFull=$(ls -tr $pathToMatch | tail -1)
    log debug "Matched file: $latestPkgFull"

    echo "$latestPkgFull"
}

_getBaseName() {
    # Get everything after the last slash
    local latestPkg="${1##*/}"
    local suffix="${2:-.zip}"

    # Strip off the suffix
    echo "${latestPkg%$suffix}"
}

_updateAemCortexPort () {
    local aemServer="$1"
    local port="$2"
    local context="$3"
    local cortexUrl=""

    # Defaults to the first cortex server and port if the load balancer is not supplied.
    if [ "$cortexLoadBalancer" != "" ]; then
        cortexUrl=$cortexLoadBalancer
    else
        local cortexPorts=(${cortexPorts})
        local cortexPort=${cortexPorts[0]}
        local cortexServers=(${cortexServers})
        local cortexServer=${cortexServers[0]}

        cortexUrl="http://${cortexServer}:${cortexPort}"
    fi

    log detail "Configuring Cortex Ports on AEM Server: $cortexUrl"

    curl -vf -u "${aem_admin_user}:${aem_admin_pass}" -X POST -d "cortex.url=${cortexUrl}/${cortexContextPath}/&propertylist=cortex.url&apply=true" "http://${aemServer}:${port}/${context}system/console/configMgr/com.elasticpath.rest.client.impl.CortexClientFactoryImpl" --header "Content-Type:application/x-www-form-urlencoded"
}

_restartAem () {
    local server=$1
    local port=$2
    local user=$3
    local folderPath=$4
    local pids=$5

    #This is a hack to restart aem
    log detail "Restarting AEM server $server via SSH call"

    log detail "Stopping AEM processes: $pids"
    ssh $user@$server "
for pid in $pids
do
    kill \$pid
done
"
    #wait for aemprocesses to die
    ssh $user@$server "
for pid in $pids
do
    while kill -s 0 \$pid 2>/dev/null; do
        sleep 1
    done
    echo \$pid killed
done
"
    log detail "Starting AEM on port: ${port}"
    ssh $user@$server "cd $folderPath; \
if [ -f "*-author-p${port}.jar" ]; \
then \
nohup java -Xmx1536m -XX:MaxPermSize=256m -jar *-author-p${port}.jar -nofork -pt CHILD -quickstart.server.port ${port} > aemRestart.log & \
fi"

    ssh $user@$server "cd $folderPath; \
if [ -f "*-publish-p${port}.jar" ]; \
then \
nohup java -Xmx1536m -XX:MaxPermSize=256m -jar *-publish-p${port}.jar -nofork -pt CHILD -quickstart.server.port ${port} > aemRestart.log & \
fi"

}

_dataStoreGarbageCollection() {
    local aemServer="$1"
    local port="$2"
    local context="$3"
    # changes cortex ports from one string to an array of strings
    curl -vf -u "${aem_admin_user}:${aem_admin_pass}" -X POST -d "action=start" "http://${aemServer}:${port}/${context}mnt/overlay/granite/operations/config/maintenance/_granite_weekly/_granite_MongoDataStoreGarbageCollectionTask"
}
