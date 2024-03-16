# K8s-demo-cluster
A simple kubeadm based cluster with 1 control &amp; 2 worker nodes


## Before You Begin
Make sure you have installed all of the following prerequisites on your development machine:
* This setup will work on Ubuntu/Debian based systems, Please replace apt commands with yum if you're trying to run on RHEL based systems.

## Prerequisites
Make sure you have installed all of the following prerequisites on your development machine:
* AWS-CLI - [Download & Install AWS CLI ](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

## Setup
There are several steps you need to follow:
* aws configure
* Create 3 EC2 with respective names k8s-control,k8s-worker1 and k8s-worker2.
* Configure Security groups with TCP all allowed (if you are using cloud sandboxes) or inbound rules to allow SSH (port 22) and Kubernetes communication (ports 6443, 2379-2380, and 10250-10252).
* Clone repo, Run commands mentioned below:-

```bash
$ bash init.sh <-path to pem file for access ec2 via awscli->
```

