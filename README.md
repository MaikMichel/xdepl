# xdepl - APEX Deployment Container

-----------------------------------

> Main purpose of this image is a special deployment concerning Oracle APEX Applications

-----------------------------------

APEX deployment container will be installed with SQLcl onboard. Anything aside is just bash.

## build image

You only need to call build.sh with the following parameters:

```./build.sh download_url file_sqlcl image_name```

or build the image by yourself

```bash
docker build -t ${IMAGE_NAME} \
  --build-arg DOWNLOAD_URL=${DOWNLOAD_URL} \
  --build-arg FILE_SQLCL=${FILE_SQLCL} \
.
```

> If download-url is not reachable sqlcl-zip is expected inside _binaries_tmp directory
