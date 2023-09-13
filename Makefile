KCONF=KUBECONFIG=~/.kube/k8spi
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=`curl -w '%{url_effective}' -I -L -s -S $(GITHUB_URL)/latest -o /dev/null | sed -e 's|.*/||'`
ENVIRONMENT=yorgos

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
	$(KCONF) kubectl apply --kustomize=cert-manager/overlays/$(ENVIRONMENT) --namespace cert-manager

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

.PHONY: mimic3
mimic3:
	$(KCONF) kubectl create namespace mycroft || true
	$(KCONF) kubectl apply --filename=mimic3-tts/pvc/ --namespace mycroft
	$(KCONF) kubectl apply --filename=mimic3-tts/ --namespace mycroft

nas-shutdown:
	$(KCONF) kubectl scale --replicas=0 --timeout=1m statefulset/unifi-controller --namespace unifi
	$(KCONF) kubectl scale --replicas=0 --timeout=1m statefulset/photoprism --namespace photoprism
	$(KCONF) kubectl scale --replicas=0 --timeout=1m deployment/photoprism-mariadb --namespace databases
	$(KCONF) kubectl scale --replicas=0 --timeout=1m deployment/nextcloud --namespace nextcloud
	$(KCONF) kubectl scale --replicas=0 --timeout=1m deployment/nextcloud-postgres --namespace nextcloud
	$(KCONF) kubectl scale --replicas=0 --timeout=1m deployment/mimic3-tts --namespace mycroft

nas-restart:
	$(KCONF) kubectl scale --replicas=1 --timeout=5m statefulset/unifi-controller --namespace unifi
	$(KCONF) kubectl scale --replicas=1 --timeout=5m statefulset/photoprism --namespace photoprism
	$(KCONF) kubectl scale --replicas=1 --timeout=5m deployment/photoprism-mariadb --namespace databases
	$(KCONF) kubectl scale --replicas=1 --timeout=5m deployment/nextcloud --namespace nextcloud
	$(KCONF) kubectl scale --replicas=1 --timeout=5m deployment/nextcloud-postgres --namespace nextcloud
	$(KCONF) kubectl scale --replicas=1 --timeout=5m deployment/mimic3-tts --namespace mycroft

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
  # enable if you have 2 types of SSD on your Network-Attached Storage (NAS) and you want to have
  # 2 storage classes: one for SSD, one for HDD.
	#$(KCONF) kubectl apply --filename=nfs-subdir/fast/


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

.PHONY: piper-tts
piper-tts:
	$(KCONF) kubectl create namespace piper-tts || true
	$(KCONF) kubectl apply --filename=piper-tts/pvc/ --namespace piper-tts
	$(KCONF) kubectl apply --filename=piper-tts/ --namespace piper-tts


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

.PHONY: whisper-stt
whisper-stt:
	$(KCONF) kubectl create namespace whisper-stt || true
	$(KCONF) kubectl apply --filename=whisper-stt/pvc/ --namespace whisper-stt
	$(KCONF) kubectl apply --filename=whisper-stt/ --namespace whisper-stt
