# First, we need to update our package list
execute 'apt-get-update' do
  command 'apt-get -y update'
end

# Install the latest rabbitmq server version
package 'rabbitmq-server'

bash 'setup_autocluster' do
  cwd "/tmp"
  code <<-EOH
    wget https://github.com/aweber/rabbitmq-autocluster/releases/download/#{node['autocluster']['version']}/autocluster-#{node['autocluster']['version']}.tgz
    tar -zxf autocluster-#{node['autocluster']['version']}.tgz
    cp -r plugins /usr/lib/rabbitmq/lib/rabbitmq_server-*/
  EOH
  not_if 'grep autocluster /etc/rabbitmq/enabled_plugins'
end

execute 'enable_rabbitmq_plugins' do
  command 'rabbitmq-plugins enable autocluster'
  not_if 'grep autocluster /etc/rabbitmq/enabled_plugins'
end

bash 'create_user' do
  code <<-EOH
    rabbitmqctl change_password guest #{node['rabbitmq']['user']['password']}
    rabbitmqctl add_user #{node['rabbitmq']['user']['name']} #{node['rabbitmq']['user']['password']}
    rabbitmqctl set_user_tags #{node['rabbitmq']['user']['name']} administrator
    rabbitmqctl set_permissions -p / #{node['rabbitmq']['user']['name']} ".*" ".*" ".*"
    touch /etc/rabbitmq/userisupdated
  EOH
  creates "/etc/rabbitmq/userisupdated"
end

cookbook_file '/var/lib/rabbitmq/.erlang.cookie' do
  source 'erlang.cookie'
  owner 'rabbitmq'
  group 'rabbitmq'
  mode '0400'
end

template '/etc/rabbitmq/rabbitmq.config' do
  source 'rabbitmq.config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/rabbitmq/rabbitmq-env.conf' do
  source 'rabbitmq-env.conf'
  owner 'root'
  group 'root'
  mode '0644'
end

service 'rabbitmq-server' do
  action [:enable, :restart]
end
