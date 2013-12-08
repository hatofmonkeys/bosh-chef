# BOSH-Chef

This is a [BOSH](https://github.com/cloudfoundry/bosh) release of [Chef](http://www.opscode.com/chef/) to enable easy creation of client-server Chef clusters of arbitrary sizes on arbitrary infrastructures.

## Walkthrough

### 1. Set up BOSH

Target your BOSH server - ideally your BOSH-Lite server. Follow the README for [bosh-lite](https://github.com/cloudfoundry/bosh-lite) to set this up, and [upload the warden stemcell](https://github.com/cloudfoundry/bosh-lite#upload-warden-stemcell). There is no need to deploy Cloud Foundry, we're using BOSH to deploy Chef.

```
$ bosh status
Config
             /home/hato/.bosh_config

Director
  Name       Bosh Lite Director
...
```


### 2. Tailor the sample manifest to your BOSH director

Copy the manifest (manifests/chef-manifest.yml) to your own deployments directory, and customise to your BOSH environment. For example:-
```
~/bosh-chef $ cp manifests/chef-manifest.yml ~
$ sed -i "s/d235f4e9-fc81-4924-b331-3712f16611ec/`bosh status | grep UUID | awk '{print $2}'`/g" ~/chef-manifest.yml
```
Ensure you have connectivity to the assigned networks.
```
~/bosh-lite $ scripts/add-route
```
The routing table can get flushed when starting/stopping virtual machines with some virtualisation technologies so check your routing table if you lose connectivity; you may need to re-run this script.

### 3. Deploy

Upload a version of the release
```
bosh-chef $ bosh upload release releases/chef-1.yml
```
Deploy the cluster
```
$ bosh deployment ~/chef-manifest.yml
$ bosh deploy

```

### 4. Log in and create an admin user

- Log in to your new Chef server; for the BOSH-Lite manifest default this will be on [https://10.244.0.30.xip.io/](https://10.244.0.30.xip.io/).
- Accept the SSL error if one appears once you've understood it
- Use the default password
- Set a new password and generate a new private key; save this admin key for later use
- Browse to the [nodes page](https://10.244.0.30.xip.io/nodes) to view your lovely Chef clients

### 5. Configure client and upload cookbook

- Install the [Chef Client](http://www.opscode.com/chef/install/) on your machine.
- Write the admin key you saved earlier to ~/admin.pem
- Write the validation key from the manifest's properties section to ~/validator.pem . You may need to remove the leading whitespace from the key.
- Configure your client - the output will differ by username

```
~ $ knife configure -i
WARNING: No knife configuration file found
Where should I put the config file? [/home/vagrant/.chef/knife.rb]
Please enter the chef server URL: [https://precise64:443] https://10.244.0.30.xip.io/
Please enter a name for the new user: [vagrant]
Please enter the existing admin name: [admin]
Please enter the location of the existing admin's private key: [/etc/chef-server/admin.pem] ./admin.pem
Please enter the validation clientname: [chef-validator]
Please enter the location of the validation key: [/etc/chef-server/chef-validator.pem] ./validator.pem
Please enter the path to a chef repository (or leave blank): ./chef-repo
Creating initial API user...
Please enter a password for the new user:
Created user[vagrant]
Configuration file written to /home/vagrant/.chef/knife.rb
```
- Create and upload a cookbook

```
$ mkdir ~/chef-repo

$ knife cookbook create apache

$ cat <<EOF >~/chef-repo/cookbooks/apache/recipes/default.rb
package "apache2"
EOF

$ knife cookbook upload apache -V
```

### 6. Apply cookbook to node(s)

- Log back in to the [nodes page](https://10.244.0.30.xip.io/nodes)
- Select the first node - usually [node 0](https://10.244.0.30.xip.io/nodes/0.chef-client.chef1.chef-warden.bosh).
- Edit the node and add the apache recipe from the cookbook you uploaded to the run list. Save the node.

### 7. Wait for convergence and bask in the glow of your own brilliance

If you've used BOSH-Lite and have the routes in place you should be able to [view a default apache page on the node you edited](http://10.244.0.50/) once the node has converged (up to three minutes). Doing something useful with the cluster is left as an exercise for the reader.

### 8. Scale the cluster up

- Edit the manifest to increase the instances of the chef_client job.
- Redeploy
```
$ bosh deploy
```

# DO NOT USE THIS IN PRODUCTION OR TO STORE ANY DATA!