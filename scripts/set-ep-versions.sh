#! /bin/bash

set -e
readonly PROGNAME=$(basename -- $0)
readonly ARGS="$@"
readonly WORKSPACE=$(pwd)

# Wraps sed to work on Windows because "sed -i" destroys file permissions.  
exec_sed_update() {
	local script=$1
	local inputfile=$2
	local tempfile="${inputfile}.bak"

	sed "${script}" "${inputfile}" > "${tempfile}"
	mv -f "${tempfile}" "${inputfile}"
}

set_ce_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS -f "${ce_directory}"/pom.xml versions:set versions:commit -DnewVersion="${version}"
}

build_ce() {
	mvn $MAVEN_SETTINGS -f "${ce_directory}"/pom.xml clean install -DskipAllTests
}

# Installs the parent poms which maven would otherwise complain about not having
maven_dependency_trick() {
	mvn $MAVEN_SETTINGS -f "${ce_directory}"/pom.xml clean install -N
	mvn $MAVEN_SETTINGS -f "${extensions_dir}"/pom.xml clean install -N
}

search_and_replace_dce_version() {
	local version=$1
	local fileToModify=$2

	exec_sed_update "s,\(<dce.version>\).*\(</dce.version>\),\1${version}\2,g" "${fileToModify}"
}

set_extensions_dependencies() {
	local version=$1

	mvn $MAVEN_SETTINGS -f "${extensions_dir}"/osgi-wrappers/com.elasticpath.cmclient.testlibs/pom.xml versions:set versions:commit -DnewVersion="${version}"
	mvn $MAVEN_SETTINGS -f "${extensions_dir}"/osgi-wrappers/com.elasticpath.cmclient.libs/pom.xml versions:set versions:commit -DnewVersion="${version}"

	# We have confidence we will not have overlapping versions here because the only other versions in the Extensions/pom.xml are
	# the project version which will be 1.0-SNAPSHOT for the foreseeable future and modelVersion in the project tag
	# All other version tags are filled in by variables
	mvn $MAVEN_SETTINGS -f "${extensions_dir}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion=${version} -Dartifacts=com.elasticpath:parent

	exec_sed_update "s,\(<platform.version>\).*\(</platform.version>\),\1${version}\2,g" "${extensions_dir}"/pom.xml

	if [ -d "${extensions_dir}"/cortex ]; then
		search_and_replace_dce_version "${version}" "${extensions_dir}"/cortex/*-commerce-engine-wrapper/pom.xml
		search_and_replace_dce_version "${version}" "${extensions_dir}"/cortex/*-cortex-webapp/pom.xml
	fi
	
}

build_extensions() {
	mvn $MAVEN_SETTINGS -f "${extensions_dir}"/pom.xml clean install
}

set_extensions_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${extensions_dir}"/pom.xml

	exec_sed_update "\#<parent>#,\#</parent># s|<version>\(.*\)</version>|<version>${version}</version>|" "${extensions_dir}"/tutorials/pom.xml

	if [ -d "${extensions_dir}"/cortex ]; then
		mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${extensions_dir}"/cortex/pom.xml
		mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${extensions_dir}"/cortex/*-commerce-engine-wrapper/pom.xml 
		mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${extensions_dir}"/cortex/*-cortex-webapp/pom.xml

		exec_sed_update "s,\(<ep-commerce-engine-wrapper-version>\).*\(</ep-commerce-engine-wrapper-version>\),\1${version}\2,g" "${extensions_dir}"/cortex/*-cortex-webapp/pom.xml
	fi
}

set_devops_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${devops_directory}"/pom.xml	
	
	mvn $MAVEN_SETTINGS -f "${devops_directory}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion=${version} -Dartifacts=ext-commerce-engine-parent
}

set_cmc_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS -f "${cmc_directory}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion="${version}" -Dartifacts=com.elasticpath:ep-core,com.elasticpath:ep-base,com.elasticpath:ep-cache,com.elasticpath:ep-persistence-api,com.elasticpath:ep-persistence-openjpa,com.elasticpath:ep-settings,com.elasticpath:ep-search,com.elasticpath:ep-querylanguage,com.elasticpath.osgi.wrappers:com.elasticpath.cmclient.libs,com.elasticpath.osgi.wrappers:com.elasticpath.cmclient.testlibs

	mvn $MAVEN_SETTINGS -f "${cmc_directory}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion="${version}" -DincludeSubmodules=true

	mvn $MAVEN_SETTINGS -f "${cmc_directory}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion="${version}" -Dartifacts=com.elasticpath:parent

	local osgi_version=$(echo "${version}" | sed "s,\(.*\)-SNAPSHOT,\1\.qualifier,")
	# Again, we have confidence this sed will only replace the version numbers we specify because we are including application/id in the search which is unique in this file
	exec_sed_update "s,\(application=\"com.elasticpath.cmclient.core.application\" version=\"\)[^\"]*\(.*\),\1${osgi_version}\2,g" "${cmc_directory}"/product/commercemanager.product
	exec_sed_update "s,\(id=\"com.elasticpath.cmclient.platform.feature\" version=\"\)[^\"]*\(.*\),\1${osgi_version}\2,g" "${cmc_directory}"/product/commercemanager.product
}

build_cmc() {
	mvn $MAVEN_SETTINGS -f "${cmc_directory}"/pom.xml clean package
}

# The reason we are creating the script this way is so that we have a way to simply use a single "settings.xml" file for all projects when we get to that point. Ideally, we should also be supplying all these projects in the same zip or side by side; the script accommodates that.
usage() {
	cat << EOF

	Usage: ./${PROGNAME} [-h] [-b] [-s <settings-file-location>] <ce_version> <extensions_version> <commerce-engine-directory> <extensions-directory> <commerce-manager-client-directory> <devops-directory>

	Sets the project versions and dependencies in Commerce Engine, Extensions, Commerce Manager Client, and DevOps.

	Options:
		-h, --help
			Displays this help page
		-b, --build
			Builds the projects upon completing the version setting. By building the projects after setting their versions, you verify the new version builds correctly.
		-s, --maven-settings <settings-file-location>
			Use a Maven settings.xml file that is not your default from your .m2 directory.

	Examples:

		$ ./${PROGNAME} 612.0.0-SNAPSHOT 0-SNAPSHOT commerce-engine extensions cmclient devops
			This will be the most common usage (relative paths and your settings file in your .m2 directory).

		$ ./${PROGNAME} -s extensions/maven/settings.xml 612.0.0-SNAPSHOT 0-SNAPSHOT commerce-engine extensions cmclient devops
			This approach lets you use a different settings.xml than the default maven settings specified in your .m2 directory.

		$ ./${PROGNAME} -s /home/ep-user/code/extensions/maven/ep-settings.xml 612.0.0-SNAPSHOT 0-SNAPSHOT /home/ep-user/code/commerce-engine /home/ep-user/code/extensions /home/ep-user/code/cmclient /home/ep-user/code/devops
			Both the settings.xml file and the project directories can be specified with absolute paths.
			This is the syntax you would use for a Linux user.

		$ ./${PROGNAME} -s c:/Users/ep-user/code/extensions/maven/ep-settings.xml 612.0.0-SNAPSHOT 0-SNAPSHOT c:/Users/ep-user/code/commerce-engine c:/Users/ep-user/code/extensions c:/Users/ep-user/code/cmclient c:/Users/ep-user/code/devops
			This is the syntax you would use for a Windows user when using absolute paths.
			You can mix and match absolute paths and relative paths if that's what you're into.

		$ ./${PROGNAME} -b 612.0.0-SNAPSHOT 0-SNAPSHOT commerce-engine extensions cmclient devops
			Specifying the -b option will build the projects after setting their versions to confirm the version set doesn't break the projects.
EOF

	exit 1
}

main() {
	# This magic number is derived from the 6 mandatory operands: ce_version, extensions_version, commerce_engine, extensions, commerce_manager_client, devops
	if [[ $# -ne 6 ]]; then
		usage
	fi

	local ce_version=$1
	local extensions_version=$2
	local ce_directory=$3
	local extensions_dir=$4
	local cmc_directory=$5
	local devops_directory=$6

	maven_dependency_trick
	set_ce_versions "${ce_version}"

	set_extensions_versions "${extensions_version}"
	set_extensions_dependencies "${ce_version}"

	set_cmc_versions "${ce_version}"

	set_devops_versions "${extensions_version}"
	
	if [[ $BUILD_FLAG == true ]]; then
		build_ce "${settings_file}"

		build_extensions "${settings_file}"

		build_cmc "${settings_file}"
	fi
}

cmdline() {
	for arg
	do
		local delim=""
		case "$arg" in
			#translate --gnu-long-options to -g (short options)
			--build)          args="${args}-b ";;
			--help)           args="${args}-h ";;
			--maven-settings) args="${args}-s ";;
			*) [[ "${arg:0:1}" == "-" ]] || delim="\""
				args="${args}${delim}${arg}${delim} ";;
		esac
	done

	#Reset the positional parameters to the short options
	eval set -- $args

	local MAVEN_SETTINGS=""
	local BUILD_FLAG=false

	while getopts "be:hs:" OPTION
	do
		case $OPTION in
			b)
				BUILD_FLAG=true
				;;
			h)
				usage
				;;
			s)
				MAVEN_SETTINGS="-s $OPTARG"
				;;
		esac
	done

	# shifts all options parsed previously by getopts to get operands not parsed by getopts
	local i=1
	while [[ $# -gt 0 && $i -lt $OPTIND ]]; do
		let i=$i+1
		shift
	done

	main $@
}
cmdline $ARGS
