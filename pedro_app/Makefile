run:
	ansible-playbook site.yml --become-password-file ~/.pwd-file

decrypt:
	ansible-vault decrypt secrets.yml

encrypt:
	ansible-vault encrypt secrets.yml

.PHONY: decrypt encrypt run
