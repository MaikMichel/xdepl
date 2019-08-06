#!/bin/bash

echo Your container args are: "$@"

export DEPOT_PATH="/u01/apps/${PROJECT}/depot"
export INSTANCE_PATH="/u01/apps/${PROJECT}/instances/${STAGE}"

# aliases
source /.ashrc

case ${STAGE,,} in
  "dev")
    PATCH_SOURCE_PATH=$DEPOT_PATH/develop
    ;;
  "tst")
    PATCH_SOURCE_PATH=$DEPOT_PATH/test
    ;;
  "acc")
    PATCH_SOURCE_PATH=$DEPOT_PATH/acceptance
    ;;
  "prd")
    PATCH_SOURCE_PATH=$DEPOT_PATH/master
    ;;
  *)
    echo "Targetstage $STAGE unknown"
    exit 1
    ;;
esac

# Validating parameters
if [[ "$1" =~ ^(init|patch|base|backup|imp_app_sql|imp_app_dmp|nginx|sql|bash)$ ]]; then
  echo "$1 - recognized command"
else
  echo "Please call script with following command"
  echo "  1 - [init | patch | base | backup | imp_app_sql | nginx | sql | bash]"
  echo "  2 - options"
  echo ""
  echo "Example: patch 1.0.1"
  echo ""
  exit
fi

command=$1
options=${@:2}

update_git(){

  if [ -z ${GIT_USER+x} ]; then
    DEPOT_URL=https://${GIT_URL_DEPOT}
    INSTANCE_URL=https://${GIT_URL_INSTANCE}
  else
    DEPOT_URL=https://${GIT_USER}:${GIT_PASS}@${GIT_URL_DEPOT}
    INSTANCE_URL=https://${GIT_USER}:${GIT_PASS}@${GIT_URL_INSTANCE}
  fi

  echo "PROJECT:       ${PROJECT}"
  echo "STAGE:         ${STAGE}"
  echo "DEPOT_PATH:    ${DEPOT_PATH}"
  echo "INSTANCE_PATH: ${INSTANCE_PATH}"
  echo "DEPOT_URL:     ${DEPOT_URL}"
  echo "INSTANCE_URL:  ${INSTANCE_URL}"
  echo
  echo

  # check if GIT-Path exists
  # clone or pull
  if [ ! -d ${DEPOT_PATH} ]
  then
    mkdir -p ${DEPOT_PATH}
    echo "cloning DEPOT"
    rm -rf ${DEPOT_PATH}
    git clone ${DEPOT_URL} ${DEPOT_PATH}
  else
    cd ${DEPOT_PATH}
    git pull
  fi

  if [ ! -d ${INSTANCE_PATH} ]
  then
    mkdir -p ${INSTANCE_PATH}
    echo "cloning INSTANCE"
    rm -rf ${INSTANCE_PATH}
    git clone ${INSTANCE_URL} ${INSTANCE_PATH}
  else
    cd ${INSTANCE_PATH}
    git pull
  fi

  export INSTANCE_PATH
  export DEPOT_PATH
}

extract_patchfile()
{
  local mode=$1
  local version=$2

  local patch_source_file=${PATCH_SOURCE_PATH}/${mode}_${version}.tar.gz
  local patch_target_file=${INSTANCE_PATH}/${mode}_${version}.tar.gz

  # check if patch exists
  if [ -e $patch_source_file ]
  then
    echo "$patch_source_file exists"

    # copy patch to _installed
    mv -f $patch_source_file $INSTANCE_PATH
  else
    echo "$patch_source_file does not exist"
    if [ -e $patch_target_file ]
    then
      echo "$patch_target_file allready copied"
    else
      echo "$patch_target_file not found, nothing to install"
      exit 1
    fi
  fi

  # extract file
  echo "extracting file $patch_target_file"
  tar -zxf $patch_target_file -C ${INSTANCE_PATH}
}


apply() {
  local mode=$1
  local version=$2

  update_git

  extract_patchfile $mode $version

  # call apply
  cd ${INSTANCE_PATH}

  chmod +x ./apply.sh
  echo "Now calling ./apply.sh $mode $version notar"
  ./apply.sh $mode $version
}

base(){
  local mode=init
  local version=$1

  update_git

  extract_patchfile $mode $version

  cd ${INSTANCE_PATH}/db/_sys

  chmod +x ./install.sh
  echo "Now calling ./install.sh"
  ./install.sh

  writenginx
}

imp_app_sql(){
  local backup_file="/u01/apps/${PROJECT}/last_backup.sql"
  if [ -e ${backup_file} ]; then
	  echo "Installing Backup from "
    exit | sql ${DB_APP_USER}/${DB_APP_PWD}@${DB_TNS} @/u01/apps/${PROJECT}/last_backup.sql
  else
    echo "Backup ${backup_file} not found"
    exit 1
  fi
}

imp_app_dmp(){
  local backup_file=$1
	echo "Installing Backup ${backup_file}"

	# Import of your schema has to be done by yourself
	# this file is copied to db container /tmp
	# during schema install DATAPUMP_DIR is created
	# and will point to /tmp

	# import backup-file
  sql ${DB_APP_USER}/${DB_APP_PWD}@${DB_TNS} <<!
	set serveroutput on
  prompt Restoring backup ...
  exec tayra_backup.restore_backup('${backup_file}');
  exit
!
}




writenginx() {
	echo "writing nginx configuration --- start"

	TARGET_FILE=/etc/nginx/vhost.d/${APP_SERVER}

	echo "  writing $TARGET_FILE"

	echo "location = / {" > "$TARGET_FILE"
	echo "  rewrite ^ /ords/f?p=${APP_NUM};" >> "$TARGET_FILE"
	echo "}" >> "$TARGET_FILE"
  echo "gzip on;" >> "$TARGET_FILE"


	TARGET_FILE=/etc/nginx/vhost.d/${APP_SERVER}_location
	echo "  writing $TARGET_FILE"
	echo "proxy_set_header Origin \"\";" > "$TARGET_FILE"

	echo "writing nginx configuration --- end"
}

############################################################################################

case $1 in
  init)
    apply $1 $2
    ;;
  patch)
    apply $1 $2
    ;;
  base)
    base $2
    ;;
  nginx)
    writenginx
    ;;
  imp_app_sql)
    imp_app_sql
    ;;
  imp_app_dmp)
    imp_app_dmp $2
    ;;
  *)
    $1 $options
    ;;
esac