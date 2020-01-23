# Scale up target

```
export KUBEVIRT_PROVIDER=ocp-4.3
export KUBECONFIG=$(./cluster-up/kubeconfig.sh)
export CUSTOM_IMAGE=worker.img 
export REPO_FILE=<FILL_HERE> # .repo file needed in order to install openshift packages
export BASE_URL=<FILL_HERE> # URL where CUSTOM_IMAGE can be found

make scale-up
```

# Scale up provisioning
Since make scale-up needs OCP base images, and those are getting deleted from CI,
we need to pre-provision the qcow image every time a new ocp provider is created.

The cluster-up should be created with a pull secret (might need to include registry.svc.ci.openshift.org as well)
```
export INSTALLER_PULL_SECRET=$(realpath pull-secret)
export KUBEVIRT_PROVIDER=ocp-4.3
make cluster-up
```

Run scale-up with provision_mode
(ocp repo file should have the needed repos required by the script and the ansible playbook scaleup.yml)
```
export KUBECONFIG=$(./cluster-up/kubeconfig.sh)
export REPO_FILE=<FILL_HERE>
export PROVISION_MODE=1
make scale-up
```
When done copy /tmp/custom.img from the container and upload it to your selected server (\$BASE_URL/$CUSTOM_IMAGE)

# Troubleshooting

## Ansible fails loading yaml
Error: `ModuleNotFoundError: No module named 'yaml'`

Install pyyaml, and make sure ansible will look on its location with the following export.
```
export PYTHONPATH=/usr/local/lib64/python3.7/site-packages:$PYTHONPATH
pip3 install pyyaml
```
