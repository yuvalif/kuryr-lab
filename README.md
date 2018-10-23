# Devstack Installation
The following process was tested on CentOS7.5.
> To create a CentOS7.5 machine you can use ```./create-centos-vm.sh``` script.

First step is to install ```git```: 
```
yum update -y && yum install -y git
```

> Bedore the devstack installation start, update ```/etc/hosts/``` and make sure that the host name and IP are set there.

Follow the [devstack instructions](https://docs.openstack.org/kuryr-kubernetes/latest/installation/devstack/basic.html) for installing kuryr-kubernetes (with some minor corrections):
```
git clone https://git.openstack.org/openstack-dev/devstack
./devstack/tools/create-stack-user.sh
sudo su - stack
git clone https://git.openstack.org/openstack-dev/devstack
git clone https://git.openstack.org/openstack/kuryr-kubernetes
cp kuryr-kubernetes/devstack/local.conf.sample devstack/local.conf
```
Now edit the local.conf file: ```vi devstack/local.conf```, and uncomment: ```KURYR_MULTI_VIF_DRIVER=npwg_multiple_interfaces```.
And run:
```
devstack/stack.sh
```
> If needed to workaround the issue of: ```Command "python setup.py egg_info" failed with error code 1``` on the: ```pycparser``` package
> Do the following downgrade:
> ```
> sudo pip install setuptools==33.1.1
> ```

Fetch this repo: ```git clone https://github.com/yuvalif/kuryr-lab.git```

# Test Pods
## Default Network
First run: 
```
source ./devstack/openrc admin admin
``` 
And then: 
```
openstack network list
```
And: 
```
openstack subnet list
```
To see what is the subnet given for the k8s network (```k8s-pod-net``` and ```k8s-pod-subnet```).
Run:
```
kubectl create -f kuryr-lab/cirros-pod.yaml
```
And then:
```
kubectl get pods -o wide
```
To verify that the pod is running and received an IP address in the correct range.
## Multi Network
First, create the networks in openstack (assuming the range 10.10.0.0/24 is not taken by the other networks):
```
openstack network create net-a
openstack subnet create subnet-a --network net-a --subnet-range 10.10.0.0/24
```
Look at the subnet ID from the above output, and replace the IDs in ```net-a-conf.yaml``` and ```net-b-conf.yaml```, then create the ```NetworkAttachmentDefinition``` CRD:
```
kubectl create -f kuryr-lab/net-a-conf.yaml
kubectl create -f kuryr-lab/net-b-conf.yaml
```
Now, the pod could be created:
```
kubectl create -f kuryr-lab/cirros-pod-multinet.yaml
```
Three interfaces should exist on the pod, the default one as well as one for net-a and one for net-b. The default one is shown by calling:
```
kubectl get pods -o wide
```
In order to see the other interfaces, use:
```
kubectl exec cirros-multinet ip a
```
> In case the above is failing due to some issue, use docker directly:
> ```
> CONTAINER_ID=`docker ps | grep cirros-multinet | grep sleep  | awk '{print $1}' | tail -n 1`
> docker exec $CONTAINER_ID= ip a
> ```

# Test [Kubevirt](https://kubevirt.io/)
## Background
The initial purpose of the kuryr-kubernetes is to allow both pods (managed by kubernetes/openshift) and virtual machines (managed by openstack) to share the same networking infrastructure. 

In case of Kubevirt, however, the purpose is to connect virtual machine managed by kubernetes/openshift) to share the same networking infrastructure with pods and virtual machines managed by openstack.

Note that kubernetes is not running inside a virtual machine, instead, it is installed directly on the same host running openstack. For Kubevirt, this is an advantage, as one level of virtualization is spared.
## Default Network

## Multi Network

# Debugging
kuryr-kubernetes logs are here:
```
sudo journalctl -u devstack@kuryr-kubernetes | less
```
And:
```
sudo journalctl -u devstack@kuryr-daemon | less
```
Kubernetes services are not running as pods (as done in a regular kubernetes deployment), instead they are running as services (executed directly by docker). Which means that running ```kubectl get pods -n kube-system``` will not show them.
E.g.:
```
systemctl status devstack@kubernetes-api.service    
● devstack@kubernetes-api.service - Devstack devstack@kubernetes-api.service
   Loaded: loaded (/etc/systemd/system/devstack@kubernetes-api.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2018-10-23 10:09:12 EDT; 4s ago
 Main PID: 13617 (docker)
   CGroup: /system.slice/system-devstack.slice/devstack@kubernetes-api.service
           └─13617 /bin/docker start --attach kubernetes-api
```
