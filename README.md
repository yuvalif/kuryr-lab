# Devstack Installation
The following process was tested on CentOS7.5, to create a CentOS7.5 machine you can use ```./create-centos-vm.sh``` script.
Install ```git```: 
```
yum update -y && yum install -y git
```
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

# Test Default Network
First run: 
```
source ./devstack/openrc admin admin
``` 
and then: 
```
openstack network list
```
and: 

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


# Test Multi Network
First, create the networks in openstack (assuming the range 10.10.0.0/24 is not taken by the other networks):
```
openstack network create net-a
openstack subnet create subnet-a --network net-a --subnet-range 10.10.0.0/24
```
Then create the ```NetworkAttachmentDefinition``` CRD:
```
kubectl create -f kuryr-lab/net-a-conf.yaml
```
Now, the pod could be created:
```
kubectl create -f kuryr-lab/cirros-pod-multinet.yaml
```

