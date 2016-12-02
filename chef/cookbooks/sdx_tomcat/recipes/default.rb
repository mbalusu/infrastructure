include_recipe 'java'

user 'application'

group 'application' do
  members 'application'
  action :create
end

tomcat_install 'fxoffice' do
  tarball_uri 'http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz'
  tomcat_user 'application'
  tomcat_group 'application'
  exclude_examples false
  exclude_docs false
end

tomcat_service 'fxoffice' do
  action [:start, :enable]
  env_vars [{ 'CATALINA_PID' => '/opt/tomcat_fxoffice/bin/non_standard_location.pid' }, { 'SOMETHING' => 'some_value' }]
  sensitive true
  tomcat_user 'application'
  tomcat_group 'application'
end
