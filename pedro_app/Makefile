deps:
	brew install ansible ansible-lint prometheus

deploy:
	ansible-playbook site.yml --become-password-file ~/.pwd-file -v

run: deploy sync-rules

ssh:
	ssh pedro@mediasrv

decrypt:
	ansible-vault decrypt secrets.yml

encrypt:
	ansible-vault encrypt secrets.yml

validate:
	# TODO: fix linting issues for ansible
	#ansible-lint site.yml
	promtool check rules prom_rules/files/*.rules.yml

## Avoid running the whole playbook, just sync the rules
sync-rules:
	rsync -avpz --delete prom_rules/files/*.rules.yml root@mediasrv:/home/observability/prometheus/config/rules/
	# send a reload signal to the prometheus server
	curl -X POST http://mediasrv:9090/-/reload



.PHONY: decrypt encrypt run validate sync-rules deploy ssh
