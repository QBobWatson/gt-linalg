# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "build_env"
  config.vm.box_check_update = false
  config.vm.hostname = "gt-linalg"
  config.vm.synced_folder "../", "/base"
  config.vm.network "forwarded_port", guest: 80, host: 8081

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 4
  end
end


# Contents of build_env.box:
#
# * debian packages
#   python-minimal
#   python3-minimal
#   python-pip
#   python3-pip
#   python-poppler
#   fontforge
#   python-fontforge
#   libcairo2-dev
#   texlive-full
#   xsltproc
#   libxml2-utils
#   coffeescript
#   apache2
#   inkscape (patched)

# * python2
#   pdfrw
#   pycairo (need 1.15.3)

# * python3
#   cssutils
#   lxml
#   bs4
#   mako
#   pyyaml

# * node_modules
#   see package.json

