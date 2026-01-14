setup:
	brew install ansible ansible-lint prometheus

deploy:
	ansible-playbook site.yml --become-password-file ~/.pwd-file -vv

deploy-homelab:
	ansible-playbook homelab-setup.yml --become-password-file ~/.pwd-file -vv

deploy-homelab-boilerplate:
	ansible-playbook homelab-setup.yml --become-password-file ~/.pwd-file -vv --tags boilerplate

deploy-homelab-zfs:
	ansible-playbook homelab-setup.yml --become-password-file ~/.pwd-file -vv --tags zfs

deploy-homelab-komodo:
	ansible-playbook homelab-setup.yml --become-password-file ~/.pwd-file -vv --tags komodo

run: deploy sync-prom

ssh:
	ssh root@homelab

decrypt:
	ansible-vault decrypt secrets.yml

encrypt:
	ansible-vault encrypt secrets.yml

validate:
	# TODO: fix linting issues for ansible
	#ansible-lint site.yml
	promtool check config prometheus.yml
	promtool check rules prom_rules/files/*.rules.yml

## Sync Prometheus configuration and rules without running full playbook
sync-prom:
	# Sync main Prometheus config
	rsync -avpz prometheus.yml root@homelab:/mnt/tank/prometheus/config/
	# Sync alerting/recording rules
	rsync -avpz --delete prom_rules/files/*.rules.yml root@homelab:/mnt/tank/prometheus/rules/
	# Send reload signal to Prometheus server
	curl -X POST http://homelab:9090/-/reload

# Legacy target name for backward compatibility
sync-rules: sync-prom



.PHONY: decrypt encrypt run validate sync-prom sync-rules deploy deploy-homelab deploy-homelab-boilerplate deploy-homelab-zfs deploy-homelab-komodo ssh setup
