# First, we need to update our package list
execute 'apt-get-update' do
  command 'apt-get -y update'
end

# Install few packages
package 'telnet'
package 'htop'

directory "/data"

# Setup filesystems
node['filesystems'].each do |fs|
  filesystem "#{fs.name}" do
    fstype "#{fs.type}"
    device "#{fs.device}"
    mount "#{fs.mount}"
    action [:create,:enable,:mount]
  end
end
