# Home Assistant Ops 


## Upgrade to new version

   1. Settings -> System -> Backups -> Create Backup 
   2. **Wait** a few minutes
   3. Download backup
1. Check that a new image version is available by lscr.io/linuxserver/homeassistant (e.g. in https://quay.io/repository/linuxserver.io/homeassistant?tab=tags )
1. Update version in helm chart
1. Use helm to upgrade:
```bash
helm upgrade homeassistant k8s-at-home/home-assistant \
		--namespace homeassistant \
		--values home-assistant/hass.values.yaml
```