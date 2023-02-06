# Developer Guide for working on this repository

## Getting Started

### Prerequisites

* [Packer](https://developer.hashicorp.com/packer/downloads) - To build images
* [Vagrant](https://developer.hashicorp.com/vagrant/docs/installation) - To run images
* [Act](https://github.com/nektos/act) - For testing GitHub actions locally
* [jq](https://stedolan.github.io/jq/) - For parsing JSON

#### Quick Guide on macOS

```shell
brew tap hashicorp/tap
brew install hashicorp/tap/packer vagrant act jq gnu-getopt
```

#### Configure environment

Optionally update submodules with

```shell
git submodule update --remote --merge
```

### Build

Note: Within the `./src/` folder

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

### Test

Note: Within the `./test/` folder

```shell
vagrant box add --force debian-docker-local ../build/package.box
vagrant up
vagrant ssh
```

Inside the VM

```shell

```

### Test CI

Following will simulate pushing to the branch

Note: At the project root `./`

#### Test regular push (Tags: latest, sha-3909bd48)

```shell
act --secret-file ./test/workflows/.secrets.dist
```

#### Test manual dispatch (Tags: latest)

```shell
act workflow_dispatch --secret-file ./test/workflows/.secrets.dist
```

#### Test tag push (Tags: latest, 1.2.3, 1.2, 1)

```shell
act -e ./test/workflows/event-tag.json --secret-file ./test/workflows/.secrets.dist
```

#### Test pull request (Tags: merge)

```shell
act pull_request -e ./test/workflows/event-pr.json --secret-file ./test/workflows/.secrets.dist
```

### Publish

Note: Within the `./` folder

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

## Contributing

Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details on our code of conduct, and [CONTRIBUTING.md](CONTRIBUTING.md) for the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository][gh-tags].

## Authors

All the authors can be seen in the [AUTHORS.md](AUTHORS.md) file.

Contributors can be seen in the [CONTRIBUTORS.md](CONTRIBUTORS.md) file.

See also the full list of [contributors][gh-contributors] who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

A list of used libraries and code with their licenses can be seen in the [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) file.

[gh-tags]: https://github.com/D3strukt0r/vagrant-debian-docker/tags
[gh-contributors]: https://github.com/D3strukt0r/vagrant-debian-docker/contributors
