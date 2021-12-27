This is an ansible task that uses the rpi_stuff as a collection to really install

All roles are disabled by default. Go to file `vars.yml` and enable the roles you're interested in.

There needs to be a series of steps to enable
1. Update the file `vars.yml` to enable the roles you want. All roles are disabled by default

1. Update the file `secrets.yml` with the values you want, like NordVPN credentials and telegram token

1. Add the RaspberryPi IP in the file `hosts.`

1. Install the stable version of the collection
``` bash
ansible-galaxy install -r requirements.yml
```

1. Run the ansible playbook replacing its ssh username and password
```bash
# Replace with your own username and password
ansible-playbook --extra-vars='ansible_user=pi' --extra-vars='ansible_ssh_pass=raspberry' site.yml
```

1. (Optional) If you wanna encrypt the contents of secrets.yml to upload to a GitHub repo
``` bash
# Replace "password" with a strong password
echo "password" > ~/.ansible-vault.txt
# To encrypt the file
ansible-vault encrypt secrets.yml

# To update or add a new value
ansible-vault decrypt secrets.yml
```
