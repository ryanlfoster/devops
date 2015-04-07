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

build_ep_for_aem() {
	mvn $MAVEN_SETTINGS -f "${ep_for_aem_dir}"/pom.xml clean install
}

build_geometrixx_demo() {
	mvn $MAVEN_SETTINGS -f "${geometrixx_demo_dir}"/pom.xml clean install
}

# Installs the parent poms which maven would otherwise complain about not having
maven_dependency_trick() {
	mvn $MAVEN_SETTINGS -f "${ep_for_aem_dir}"/pom.xml clean install -N
}

set_ep_for_aem_parent_versions() {
	local version=$1
	
	exec_sed_update "s,\(<com.elasticpath.commerce-engine.version>\).*\(</com.elasticpath.commerce-engine.version>\),\1${version}\2,g" "${ep_for_aem_dir}"/pom.xml
}

set_ep_for_aem_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${ep_for_aem_dir}"/pom.xml
	
	exec_sed_update "s,\(<com.elasticpath.aem.commerce.version>\).*\(</com.elasticpath.aem.commerce.version>\),\1${version}\2,g" "${ep_for_aem_dir}"/pom.xml
}

set_geometrixx_demo_parent_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS -f "${geometrixx_demo_dir}"/pom.xml -Dtycho.mode=maven org.eclipse.tycho:ep-tycho-versions-plugin:set-version -DnewVersion=${version} -Dartifacts=com.elasticpath.aem.commerce:aem-commerce-parent
}

set_geometrixx_demo_versions() {
	local version=$1

	mvn $MAVEN_SETTINGS versions:set versions:commit -DnewVersion="${version}" -f "${geometrixx_demo_dir}"/pom.xml
}

# The reason we are creating the script this way is so that we have a way to simply use a single "settings.xml" file for all projects when we get to that point. Ideally, we should also be supplying all these projects in the same zip or side by side; the script accommodates that.
usage() {
	cat << EOF

	Usage: ./${PROGNAME} [-h] [-b] [-s <settings-file-location>] <ce_version> <ep_for_aem_version> <ep-for-aem-directory> <geometrixx-demo-directory>

	Sets the project versions and dependencies in EP for AEM Commerce.

	Options:
		-h, --help
			Displays this help page
		-b, --build
			Builds the projects upon completing the version setting. By building the projects after setting their versions, you verify the new version builds correctly.
		-s, --maven-settings <settings-file-location>
			Use a Maven settings.xml file that is not your default from your .m2 directory.

	Examples:

		$ ./${PROGNAME} 613.0.0-SNAPSHOT 1.1.0-SNAPSHOT ep-aem-commerce geometrixx-demo
			This will be the most common usage (relative paths, default settings.xml from your .m2 directory).

		$ ./${PROGNAME} -s extensions/maven/settings.xml 613.0.0-SNAPSHOT 1.1.0-SNAPSHOT ep-aem-commerce geometrixx-demo
			This approach lets you use a different settings.xml than the default maven settings specified in your .m2 directory.

		$ ./${PROGNAME} -s /home/ep-user/code/extensions/maven/ep-settings.xml 613.0.0-SNAPSHOT 1.1.0-SNAPSHOT /home/ep-user/code/ep-aem-commerce /home/ep-user/code/geometrixx-demo
			Both the settings.xml file and the project directories can be specified with absolute paths.
			This is the syntax you would use for a Linux user.

		$ ./${PROGNAME} -s c:/Users/ep-user/code/extensions/maven/ep-settings.xml 613.0.0-SNAPSHOT 1.1.0-SNAPSHOT c:/Users/ep-user/code/ep-aem-commerce c:/Users/ep-user/code/geometrixx-demo
			This is the syntax you would use for a Windows user when using absolute paths.
			You can mix and match absolute paths and relative paths if that's what you're into.

		$ ./${PROGNAME} -b 613.0.0-SNAPSHOT 1.1.0-SNAPSHOT ep-aem-commerce geometrixx-demo
			Specifying the -b option will build the projects after setting their versions to confirm the version set doesn't break the projects.
EOF

	exit 1
}

main() {
	# This magic number is derived from the 3 mandatory operands: ce_version, ep_aem_version, ep_for_aem, geometrixx_demo
	if [[ $# -ne 4 ]]; then
		usage
	fi

	local ce_version=$1
	local ep_aem_version=$2
	local ep_for_aem_dir=$3
	local geometrixx_demo_dir=$4
	
	maven_dependency_trick
	
	set_ep_for_aem_parent_versions "${ce_version}"
	set_ep_for_aem_versions "${ep_aem_version}"

	maven_dependency_trick

	set_geometrixx_demo_parent_versions "${ep_aem_version}"
	set_geometrixx_demo_versions "${ep_aem_version}"
	
	if [[ $BUILD_FLAG == true ]]; then
		build_ep_for_aem "${settings_file}"
		build_geometrix_demo "${settings_file}"
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
