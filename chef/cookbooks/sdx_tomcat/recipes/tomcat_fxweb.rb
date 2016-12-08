include_recipe 'java'

user 'application'

group 'application' do
  members 'application'
  action :create
end

tomcat_install 'fxweb' do
  tarball_uri 'http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz'
  tomcat_user 'application'
  tomcat_group 'application'
end

cookbook_file '/opt/tomcat_fxweb/conf/server.xml' do
  source 'fxweb_tomcat_server.xml'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'tomcat_service[fxweb]'
end

remote_file '/opt/tomcat_fxweb/webapps/sample.war' do
  owner 'application'
  mode '0644'
  source 'https://tomcat.apache.org/tomcat-6.0-doc/appdev/sample/sample.war'
  checksum '89b33caa5bf4cfd235f060c396cb1a5acb2734a1366db325676f48c5f5ed92e5'
end

tomcat_service 'fxweb' do
  action [:start, :enable]
  env_vars [{ 'CATALINA_PID' => '/opt/tomcat_fxweb/bin/tomcat.pid' }]
  sensitive true
  tomcat_user 'application'
  tomcat_group 'application'
end
