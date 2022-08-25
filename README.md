
![Panda](/panda.jpg)

# Helm3 Plugin `helm-release`
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/helm-release)](https://artifacthub.io/packages/helm-plugin/helm-release/release)
[![GitHub license](https://img.shields.io/github/license/JovianX/helm-release-plugin)](https://github.com/JovianX/helm-release-plugin)
![GitHub contributors](https://img.shields.io/github/contributors/JovianX/helm-release-plugin)
[![GitHub stars](https://img.shields.io/github/stars/JovianX/helm-release-plugin)](https://github.com/JovianX/helm-release-plugin/stargazers)  **Please star ⭐ the repo if you find it useful.**


`helm-release` is a Helm 3 plugin that allows running operatins on Helm releases (deployed Helm charts).

Features:

 * Pull (re-create) Helm charts from a deployed helm release.
 * Update values of a deployed release (without the chart package or path).

Common use-Cases:
 * Redeploy a release on another cluster or namespace with the exact same helm chart. 
 * Update values of a release without the original helm chart, when you are not sure what exact version was used, or you have no access to the original helm chart (helm upgrade command requires the chart `helm upgrade [RELEASE] [CHART] [flags]`).

## Getting started
### Installation
To install the plugin:
```shell
helm plugin install https://github.com/JovianX/helm-release-plugin
```

>
> Dependencies: `helm-release` plugin depends on:
>>      jq - a lightweight and flexible command-line JSON processor.
>>             Install: https://stedolan.github.io/jq/download/
>

Update to latest:
```shell
$ helm plugin update release
```
Verify it's been installed:
```shell
$ helm plugin list
NAME   	VERSION	DESCRIPTION
...
release	0.3.2  	Update values of a releases, pull charts from releases
...
```


### Usage

```
$ helm release
usage: helm release [ pull upgrade ]
```
Available Commands:
* __pull__ - Pulls (re-create) a Helm chart from a deployed Helm release
* __upgrade__ - Behaves same as `helm upgrade`, but doesn't require providing of helm chart. Chart pulled by `helm release pull`.


#### helm release pull

```
$ helm release pull
usage: helm release pull <RELEASE NAME> [-d | --destination <TARGET CHART DIRECTORY>] [-o | --output [yaml | json | text]]
```

Example:
```
$ helm --namespace nginx release pull nginx --destination /home/me/helm-charts
Chart saved to nginx-ingress-0.13.2

$ ls /home/me/helm-charts/nginx-ingress-0.13.2/
Chart.yaml  crds  README.md  templates  values-icp.yaml  values-nsm.yaml  values-plus.yaml  values.yaml
```

#### helm release upgrade

This command accepts same parameters as `helm upgrade` except no need to provide chart. As optional parameter you can pass `--destination` directory where chart will be dumped, by default chart dumped to `/tmp`. After release update chart will be deleted.
```
$ helm release upgrade
Helper for helm upgrade, that doesn't require to provide original helm chart. Usage: helm release upgrade [RELEASE NAME] [-d | --destination <TARGET CHART DIRECTORY>] [helm upgrade arguments]
```

Example:
```
helm release upgrade rabbitmq --namespace=rabbitmq --set=key1=value1 --reuse-values
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading common from repo https://charts.bitnami.com/bitnami
Deleting outdated charts
Release "rabbitmq" has been upgraded. Happy Helming!
... standard helm upgrade output ...
```

## Contributing
We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:
- Reporting a bug
- Submitting a fix
- Proposing new features
- All pull requests are welcome.

Please see the [CONTRIBUTING](CONTRIBUTING.md) guide.


## Contributors
<a href = "https://github.com/JovianX/helm-release-plugin/graphs/contributors">
  <img src = "https://contrib.rocks/image?repo=JovianX/helm-release-plugin"/>
</a>

## License
 Copyright 2022 JovianX Ltd.

 Licensed under the Apache License, Version 2.0 (the "[LICENSE](https://github.com/JovianX/helm-release-plugin/blob/main/LICENSE)")
 
<a href="https://jovianx.com">
    <img src=https://jovianx.com/wp-content/uploads/2021/05/Logo2-2.png  height="50">
</a>

