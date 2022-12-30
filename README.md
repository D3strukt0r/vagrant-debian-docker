# Vagrant Box with Debian and Docker preinstalled

A Debian image based on Bento boxes with Docker and other tools preinstalled

## Build

```shell
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

TIP: Convert old JSON formatted configs to HCL2:

```shell
packer hcl2_upgrade <config>.pkr.json
```

Install required plugins:

```shell
packer init .
```

Format template files:

```shell
packer fmt .
```

Validate template files:

```shell
packer validate .
```

Build the box:

```shell
packer build -force debian-docker.pkr.hcl
```

Run the build:

```shell
cd test/
vagrant box add --force debian-docker ../build/package.box
vagrant up
```

## Publish

Create an [access token](https://app.vagrantup.com/settings/security)

```shell
VAGRANT_CLOUD_USER=D3strukt0r
VAGRANT_CLOUD_TOKEN=<my_access_token>
VAGRANT_CLOUD_BOX=debian-docker
VAGRANT_CLOUD_VERSION=0.1.0
VAGRANT_CLOUD_PROVIDER=virtualbox
VAGRANT_CLOUD_FILE=./build/package.box
```

Create a new version

```shell
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/versions" \
  --data "{ \"version\": { \"version\": \"$VAGRANT_CLOUD_VERSION\" } }"
```

Create a new provider

```shell
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/providers" \
  --data "{ \"provider\": { \"name\": \"$VAGRANT_CLOUD_PROVIDER\" } }"
```

Prepare the provider for upload/get an upload URL

```shell
response=$(curl \
    --request GET \
    --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/provider/$VAGRANT_CLOUD_PROVIDER/upload")
```

Extract the upload URL from the response (requires the jq command)

```shell
brew install jq
```

```shell
upload_path=$(echo "$response" | jq --raw-output .upload_path)
```

Perform the upload

```shell
curl --request PUT "${upload_path}" --upload-file "$VAGRANT_CLOUD_FILE"
```

Release the version

```shell
curl \
  --request PUT \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/release"
```
