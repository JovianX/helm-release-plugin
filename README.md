# Helm3 Plugin `helm-release`
[![GitHub license](https://img.shields.io/github/license/JovianX/helm-release-plugin)](https://github.com/JovianX/helm-release-plugin)
![GitHub contributors](https://img.shields.io/github/contributors/JovianX/helm-release-plugin)
[![GitHub stars](https://img.shields.io/github/stars/JovianX/helm-release-plugin)](https://github.com/JovianX/helm-release-plugin/stargazers) Please star ⭐ the repo if you find it useful.

`helm-release` is a Helm 3 plugin that allows running operatins on Helm releases (deployed Helm charts).


Features:

 * Pull (re-create) Helm charts from a deployed helm release.
 * Update values of a deployed release (without the chart package or path).


## Getting started
### Installation
To install the plugin:
```shell
$ helm plugin install  https://github.com/JovianX/helm-release-plugin
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
release	0.3.0  	Update values of a releases, pull charts from releases
...
```


### Usage
```
$ helm release
usage: helm release [ pull ]
Available Commands:
    pull   Pulls (re-create) a Helm chart from a deployed Helm release

$ helm release pull
usage: helm release pull <RELEASE NAME> [-d | --destination <TARGET CHART DIRECTORY>] [-o | --output [yaml | json | text]]

Example:
$ helm --namespace nginx release pull nginx --destination /home/me/helm-charts 
Chart saved to nginx-ingress-0.13.2

$ ls /home/me/helm-charts/nginx-ingress-0.13.2/
Chart.yaml  crds  README.md  templates  values-icp.yaml  values-nsm.yaml  values-plus.yaml  values.yaml

```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Contributors
<a href = "https://github.com/JovianX/helm-release-plugin/graphs/contributors">
  <img src = "https://contrib.rocks/image?repo=JovianX/helm-release-plugin"/>
</a>

## License
This Project is licensed under the Apache 2.0 license agreement, see [LICENSE](https://github.com/JovianX/helm-release-plugin/blob/main/LICENSE) file for complete license agreement.
