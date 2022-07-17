KCONF=KUBECONFIG=~/.kube/raspi
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=`curl -w '%{url_effective}' -I -L -s -S $(GITHUB_URL)/latest -o /dev/null | sed -e 's|.*/||'`

.PHONY: k3s-install
k3s-install:
	ansible-playbook --inventory k3s/ansible/inventory.yaml k3s/ansible/ha_cluster.yaml

.PHONY: cert-manager
cert-manager:
	helm install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
	    --version v1.8.2 \
		--create-namespace \
		--values cert-manager/helm/cert-manager.values.yaml
	$(KCONF) kubectl apply --filename=cert-manager/ --namespace cert-manager

.PHONY: dashboard-install
dashboard-install:
	echo $(VERSION_KUBE_DASHBOARD)
	$(KCONF) kubectl create --filename=https://raw.githubusercontent.com/kubernetes/dashboard/$(VERSION_KUBE_DASHBOARD)/aio/deploy/recommended.yaml

.PHONY: dashboard-user
dashboard-user:
	$(KCONF) kubectl apply --filename=dashboard/ --namespace kubernetes-dashboard

.PHONY: dashboard
dashboard: dashboard-install dashboard-user

.PHONY: home-assistant
home-assistant:
	helm install homeassistant k8s-at-home/home-assistant \
		--namespace homeassistant \
		--create-namespace \
		--values home-assistant/hass.values.yaml

.PHONY: mosquitto
mosquitto:
	$(KCONF) kubectl create namespace mosquitto || true
	$(KCONF) kubectl apply --filename=mosquitto/ --namespace mosquitto

.PHONY: mariadb
mariadb:
	$(KCONF) kubectl create namespace databases || true
	$(KCONF) kubectl apply --filename=photoprism/mariadb/storage/ --namespace databases
	$(KCONF) kubectl apply --filename=photoprism/mariadb/ --namespace databases

.PHONY: nextcloud
nextcloud:
	$(KCONF) kubectl create namespace nextcloud || true
	$(KCONF) kubectl apply --filename=nextcloud/postgres/ --namespace nextcloud
	$(KCONF) kubectl apply --filename=nextcloud/secret.yaml --namespace nextcloud
	helm install nextcloud nextcloud/nextcloud \
   		--namespace nextcloud \
    	--values nextcloud/nextcloud.values.yml

nextcloud-clean:
	helm uninstall nextcloud --namespace nextcloud

.PHONY: nfs-install
nfs-install:
	$(KCONF) kubectl apply --filename=nfs-subdir/rbac.yaml
	$(KCONF) kubectl apply --filename=nfs-subdir/standard/
	$(KCONF) kubectl apply --filename=nfs-subdir/fast/


.PHONY: photoprism
photoprism:
	$(KCONF) kubectl create namespace photoprism || true
	$(KCONF) kubectl apply --filename=photoprism/storage/ --namespace photoprism
	$(KCONF) kubectl apply --filename=photoprism/ --namespace photoprism

.PHONY: pihole
pihole:
	helm install pihole mojo2600/pihole \
    	--namespace pihole \
    	--create-namespace \
    	--values pi-hole/pihole.values.yml


.PHONY: shairport-sync
shairport-sync:
	$(KCONF) kubectl create namespace shairport-sync || true
	$(KCONF) kubectl apply --filename=shairport-sync/ --namespace shairport-sync

.PHONY: traefik
traefik:
	$(KCONF) kubectl apply --filename=traefik/ --namespace kube-system

.PHONY: unifi-controller
unifi-controller:
	$(KCONF) kubectl create namespace unifi || true
	$(KCONF) kubectl apply --filename=unifi-controller/ --namespace unifi
