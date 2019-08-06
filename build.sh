#!/bin/bash


# All Params are required
usage() {
	echo
  echo
  echo -e "${RED}Please call script by using params...!${NC}"
  echo -e
	echo -e "    $0 download_url sqlcl_zip image_name"
  echo -e "------------------------------------------------------------------"
  echo -e
  echo -e "  ${YELLOW}download_url${NC}     - url from where to download sqlcl"
  echo -e "  ${YELLOW}file_sqlcl${NC}        - name of the zip-file, containing sqlcl"
  echo -e "  ${YELLOW}image_name${NC}       - give your image a meaningful name"
  echo -e
  echo -e "------------------------------------------------------------------"
}

# Reset
NC="\033[0m"       # Text Reset

# Regular Colors
BLACK="\033[0;30m"        # Black
RED="\033[0;31m"          # Red
GREEN="\033[0;32m"        # Green
BGREEN="\033[1;32m"        # Green
YELLOW="\033[0;33m"       # Yellow
BLUE="\033[0;34m"         # Blue
PURPLE="\033[0;35m"       # Purple
CYAN="\033[0;36m"         # Cyan
WHITE="\033[0;37m"        # White
BYELLOW="\033[1;33m"       # Yellow

echo_red(){
    echo -e "${RED}${1}${NC}"
}

echo -e "${BGREEN}XDEPL - APEX Deployment Container${NC}"
echo -e "${GREEN}---------------------------------${NC}"

DOWNLOAD_URL=${1}
FILE_SQLCL=${2}
IMAGE_NAME=${3}



echo "DOWNLOAD_URL=${DOWNLOAD_URL}"
echo "FILE_SQLCL=${FILE_SQLCL}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo
###################################################################################################

if [ $# -lt 3 ]; then
  usage
  exit 1
fi

###################################################################################################

# remove old image if exists
if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
  echo "nothing to remove"
else
  docker rmi -f ${IMAGE_NAME}
fi

# if sqlcl is reachable we will use that
# otherwise we will move anything inside _binaries into build-content
if curl --output /dev/null --silent --head --fail "${DOWNLOAD_URL}/${FILE_SQLCL}"; then
  echo -e "${GREEN}${DOWNLOAD_URL}/${FILE_SQLCL} exists${NC}"
  mv _binaries/* _binaries_tmp 2>/dev/null
  mv _binaries_tmp/note.md _binaries 2>/dev/null
else
  echo -e "${RED}${DOWNLOAD_URL}/${FILE_SQLCL} does not exist${NC}"
  mv _binaries_tmp/* _binaries 2>/dev/null
  mv _binaries/note_tmp.md _binaries_tmp 2>/dev/null
fi
  
docker build -t ${IMAGE_NAME} \
  --build-arg DOWNLOAD_URL=${DOWNLOAD_URL} \
  --build-arg FILE_SQLCL=${FILE_SQLCL} \
.

