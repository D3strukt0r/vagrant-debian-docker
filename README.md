# Vagrant Box with Debian and Docker preinstalled

A Debian image based on Bento boxes with Docker and other tools preinstalled

## Getting Started

### Prerequisites

* [Vagrant](https://developer.hashicorp.com/vagrant/docs/installation) - To run images

#### Quick Guide on macOS

```shell
brew install vagrant
```

### Usage

Inside your `Vagrantfile` simply use our image as base image:

```vagrantfile
Vagrant.configure('2') do |config|
  config.vm.box = 'd3strukt0r/debian-docker'
end
```

For a complete example that we also use for testing, check out [test/Vagrantfile](test/Vagrantfile)

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
