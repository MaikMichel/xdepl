#!/bin/bash

downloadFiles() {
  echo "Downloading ${DOWNLOAD_URL}/${FILE_SQLCL}"
  curl -# --retry 3 -m 60 --create-dirs -o /tmp/${FILE_SQLCL} -L ${DOWNLOAD_URL}/${FILE_SQLCL}
}

# download the all files if FILE_SQLCL is not there
if [ ! -f /tmp/${FILE_SQLCL} ]; then
  downloadFiles
fi

echo "create dir sqlcl_bin"
mkdir /sqlcl_bin

echo "installing sqlcl"
cd /tmp
unzip -q sqlcl*.zip
rm -rf sqlcl*.zip
mv * /sqlcl_bin

