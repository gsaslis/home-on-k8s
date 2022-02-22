KCONF=KUBECONFIG=~/.kube/raspi
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=`curl -w '%{url_effective}' -I -L -s -S $(GITHUB_URL)/latest -o /dev/null | sed -e 's|.*/||'`

.PHONY: dashboard-install
dashboard-install:
	echo $(VERSION_KUBE_DASHBOARD)
	$(KCONF) kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/$(VERSION_KUBE_DASHBOARD)/aio/deploy/recommended.yaml

.PHONY: dashboard-user
dashboard-user:
	$(KCONF) kubectl create -f dashboard/

.PHONY: dashboard
dashboard: dashboard-install dashboard-user

.PHONY: home-assistant
home-assistant:
	helm install homeassistant k8s-at-home/home-assistant --namespace homeassistant --values home-assistant/hass.values.yaml --create-namespace

.PHONY: mosquitto
mosquitto:
	kubectl create namespace mosquitto || true
	kubectl apply --filename=mosquitto/ --namespace mosquitto

.PHONY: nextcloud
nextcloud:
	kubectl create namespace nextcloud || true
	kubectl apply --filename=nextcloud/postgres/ --namespace nextcloud
	kubectl apply --filename=nextcloud/secret.yaml --namespace nextcloud
	helm install nextcloud nextcloud/nextcloud \
   		--namespace nextcloud \
    	--values nextcloud/nextcloud.values.yml

.PHONY: nfs-install
nfs-install:
	$(KCONF) kubectl apply --filename=nfs-subdir/ --recursive=false

.PHONY: pihole
pihole:
	helm install pihole mojo2600/pihole \
    	--namespace pihole \
    	--values pi-hole/pihole.values.yml
