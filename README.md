# Helm3 Plugin `helm-release`
`helm-release` is a Helm 3 plugin that allows running operatins on Helm releases (deployment instances of Helm charts). 

`helm-release` plugin allows:

 * Pull (re-create) Helm charts from a deployed helm release.
 * Update values of deployed releases, without spesificing the Helm chart.

## Getting started
### Installation
To install the plugin:
```shell
$ helm plugin install  https://github.com/JovianX/helm-release-plugin
```
Update to latest:
```shell
$ helm plugin update release
```
Verify it's been installed:
```shell
$ helm plugin list
```

>
>
> Dependencies: `helm-release` plugin depends on:  
>>      jq - a lightweight and flexible command-line JSON processor.   
>>             Install: https://stedolan.github.io/jq/download/  
> 
>>      yq - a lightweight and portable command-line YAML processor.   
>>            Install: https://github.com/mikefarah/yq/#install
>

### Usage
```
$ helm release
usage: ./release.sh [ pull ]
Available Commands:
    pull   Pulls (re-create) a Helm chart from a deployed Helm release

$ helm release pull 
usage: helm release pull <RELEASE NAME>

Example:
$ helm --namespace nginx release pull nginx

```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
This Project is licensed under the Apache 2.0 license agreement, see [LICENSE](https://github.com/JovianX/helm-release-plugin/blob/main/LICENSE) file for complete license agreement.