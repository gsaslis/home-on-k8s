KCONF=KUBECONFIG=~/.kube/raspi
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=`curl -w '%{url_effective}' -I -L -s -S $(GITHUB_URL)/latest -o /dev/null | sed -e 's|.*/||'`

dashboard-install:
	echo $(VERSION_KUBE_DASHBOARD)
	$(KCONF) kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/$(VERSION_KUBE_DASHBOARD)/aio/deploy/recommended.yaml

dashboard-user:
	$(KCONF) kubectl create -f dashboard/

dashboard: dashboard-install dashboard-user

mosquitto-prep:
  kubectl create namespace mosquitto

mosquitto:
  kubectl apply --filename=mosquitto/ --namespace mosquitto

nextcloud:
  kubectl create namespace nextcloud || true
  kubectl apply --filename=nextcloud/postgres/ --namespace nextcloud
  kubectl apply --filename=nextcloud/secret.yaml --namespace nextcloud
  helm install nextcloud nextcloud/nextcloud \
    --namespace nextcloud \
    --values nextcloud/nextcloud.values.yml

nfs-install:
	$(KCONF) kubectl apply -f nfs-subdir/

pihole:
  helm install pihole mojo2600/pihole \
    --namespace pihole \
    --values pi-hole/pihole.values.yml
