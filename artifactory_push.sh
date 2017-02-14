#!/bin/bash
#
# Pushes .rpm and .deb artifacts to Artifactory
#
# Requires the following external env vars
#   ARTIFACTORY_USER - user name for Artifactory login
#   ARTIFACTORY_PASSWORD - password for the Artifactory user
#
# TODO should observe the respective Debian / RPM artifact name conventions
#    deb   <foo>_<VersionNumber>-<DebianRevisionNumber>_<DebianArchitecture>.deb
#    rpm   name-version-release.architecture.rpm
#

# -------------
# Configuration
# -------------

# Base URL to your Artifactory
ARTIFACTORY_BASE="https://artifactory.viasat.com/artifactory"

# URL element for an Artifactory repo set up as a Debian apt repo
ARTIFACTORY_DEB_REPO="databus-deb"

# URL element for an Artifactory repo set up as an RPM yum repo
ARTIFACTORY_RPM_REPO="databus-rpm"

# Command on your build host that produces a SHA1 hash
#   best general choice is "openssl sha1"; alternative "sha1sum"
SHA1CMD="openssl sha1"

PKG=grafana

# -----------------
# End Configuration
# -----------------

[[ -z $ARTIFACTORY_PASSWORD ]] && echo "ARTIFACTORY_PASSWORD not set" && exit 1
[[ -z $ARTIFACTORY_USERNAME ]] && echo "ARTIFACTORY_USERNAME not set" && exit 1

# function to count words in a string
howmany() ( set -f; set -- $1; echo $# )

# we don't use an os or arch element in the path, grafana is always going to be amd64
DEB_REPO=$ARTIFACTORY_BASE/databus-deb/$PKG
RPM_REPO=$ARTIFACTORY_BASE/databus-rpm/$PKG

# make sure we don't have multiple artifact versions in the dist directory
DEB_ARTIFACT_PATH="$(ls dist/*.deb)"
RPM_ARTIFACT_PATH="$(ls dist/*.rpm)"
NDEB=$(howmany "$DEB_ARTIFACT_PATH")
NRPM=$(howmany "$RPM_ARTIFACT_PATH")
if [[ $NDEB != 1 ]]; then
	echo "expected exactly one Debian artifact! (found $NDEB)"
	exit 1
fi
if [[ $NRPM != 1 ]]; then
	echo "expected exactly one RPM artifact! (found $NRPM)"
	exit 1
fi

DEB_ARTIFACT_NAME="$(basename ${DEB_ARTIFACT_PATH})"
RPM_ARTIFACT_NAME="$(basename ${RPM_ARTIFACT_PATH})"

DEB_ARTIFACT_URL=$DEB_REPO/$DEB_ARTIFACT_NAME
RPM_ARTIFACT_URL=$RPM_REPO/$RPM_ARTIFACT_NAME

DEB_SHA1="$(${SHA1CMD} ${DEB_ARTIFACT_PATH} | cut -d' ' -f2)"
RPM_SHA1="$(${SHA1CMD} ${RPM_ARTIFACT_PATH} | cut -d' ' -f2)"

echo "DEB_ARTIFACT_URL = $DEB_ARTIFACT_URL"
echo "DEB_SHA1 = $DEB_SHA1"
echo "RPM_ARTIFACT_URL = $RPM_ARTIFACT_URL"
echo "RPM_SHA1 = $RPM_SHA1"

curl -k -u $ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -X PUT \
    -H "X-Checksum-Sha1:${DEB_SHA1}" \
	--write-out "\n HTTP code %{http_code}\nUploaded bytes %{size_upload}\n" \
    -T $DEB_ARTIFACT_PATH \
    ${DEB_ARTIFACT_URL}

curl -k -u $ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -X PUT \
	-H "X-Checksum-Sha1:${RPM_SHA1}" \
	--write-out "\n HTTP code %{http_code}\nUploaded bytes %{size_upload}\n" \
	-T $RPM_ARTIFACT_PATH \
	${RPM_ARTIFACT_URL}
