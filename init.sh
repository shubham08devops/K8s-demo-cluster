#!/bin/bash
chmod 400 ~/Downloads/k8s-demo-cluster.pem

INSTANCE_NAMES="k8s-control","k8s-worker1","k8s-worker2"
instance_private_ip_k8s_control=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-control"  --output text --query "Reservations[*].Instances[*].PrivateIpAddress");

instance_public_ip_k8s_control=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-control"  --output text --query "Reservations[*].Instances[*].PublicIpAddress");

instance_private_ip_k8s_worker1=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-worker1"  --output text --query "Reservations[*].Instances[*].PrivateIpAddress");

instance_private_ip_k8s_worker2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-worker2"  --output text --query "Reservations[*].Instances[*].PrivateIpAddress");

IFS=","
for instance_name in $INSTANCE_NAMES; do
	instance_public_ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values="$instance_name""  --output text --query "Reservations[*].Instances[*].PublicIpAddress");
          echo "Deploying to $instance_name...";
          ssh -oStrictHostKeyChecking=no -i ~/Downloads/k8s-demo-cluster.pem ubuntu@"$instance_public_ip" 'bash -s' < prepare.sh $instance_name $instance_private_ip_k8s_control $instance_private_ip_k8s_worker1 $instance_private_ip_k8s_worker2
          if [ $instance_name == "k8s-control" ]
          then
                ssh -oStrictHostKeyChecking=no -i ~/Downloads/k8s-demo-cluster.pem ubuntu@"$instance_public_ip" '''# On the control plane node only, initialize the cluster and set up kubectl access:
                sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.26.0
                mkdir -p $HOME/.kube
                sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
                sudo chown $(id -u):$(id -g) $HOME/.kube/config
                kubectl get nodes
                kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
                sleep 30
		curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
		echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helmstable-debian.list
		sudo apt update
		sudo apt install -y helm
		helm version
		##metrics API
		kubectl apply -f https://raw.githubusercontent.com/ACloudGuru-Resources/content-cka-resources/master/metrics-server-components.yaml
                '''
          else
                token=$(ssh -oStrictHostKeyChecking=no -i ~/Downloads/k8s-demo-cluster.pem ubuntu@"$instance_public_ip_k8s_control" "kubeadm token create --print-join-command")
                ssh -oStrictHostKeyChecking=no -i ~/Downloads/k8s-demo-cluster.pem ubuntu@"$instance_public_ip" "sudo "$token""
          fi
          done
