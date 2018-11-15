
include_recipe "lsf::default"
#lsf10.1_linux2.6-glibc2.3-x86_64.tar.Z	lsfsce10.2.0.6-x86_64.tar.gz
#lsf10.1_lsfinstall_linux_x86_64.tar.Z
tar_dir = node['lsf']['tar_dir']
lsf_top = node['lsf']['lsf_top']
lsf_version = node['lsf']['version']
lsf_kernel = node['lsf']['kernel']
lsf_arch = node['lsf']['arch']
clustername = node['lsf']['clustername']

lsf_product = "lsf#{lsf_version}_#{lsf_kernel}-#{lsf_arch}"
lsf_install = "lsf#{lsf_version}_lsfinstall_linux_#{lsf_arch}"

jetpack_download "#{lsf_install}.tar.Z" do
    project "lsf"
    dest tar_dir
    not_if { ::File.exist?("#{tar_dir}/#{lsf_install}.tar.Z") }
end

jetpack_download "#{lsf_product}.tar.Z" do
    project "lsf"
    dest tar_dir
    not_if { ::File.exist?("#{tar_dir}/#{lsf_product}.tar.Z") }
end

execute "untar_installers" do 
    command "gunzip #{lsf_install}.tar.Z && tar -xf #{lsf_install}.tar"
    cwd tar_dir
    not_if { ::File.exist?("#{tar_dir}/lsf#{lsf_version}_lsfinstall/lsfinstall") }
end

template "#{tar_dir}/lsf#{lsf_version}_lsfinstall/lsf.install.config" do
    source 'conf/install.config.erb'
    variables lazy {{
      :master_list => node[:lsf][:master_list].nil? ? node[:hostname] : node[:lsf][:master_list]
    }}
end

execute "run_lsfinstall" do
    command "./lsfinstall -f lsf.install.config"
    cwd "#{tar_dir}/lsf#{lsf_version}_lsfinstall"
    creates "#{lsf_top}/conf/profile.lsf"
    not_if { ::File.exist?("#{lsf_top}/#{lsf_version}/#{lsf_kernel}-#{lsf_arch}/lsf_release")}
    not_if { ::Dir.exist?("#{lsf_top}/#{lsf_version}")}
end

directory node['lsf']['local_etc']

link "#{lsf_top}/conf/lsf.conf" do
  to "#{node['lsf']['local_etc']}/lsf.conf"
end

link "#{lsf_top}/conf/lsf.cluster.#{clustername}" do
  to "#{node['lsf']['local_etc']}/lsf.cluster.#{clustername}"
end

link "#{lsf_top}/conf/lsbatch/#{clustername}/configdir/lsb.hosts" do
  to "#{node['lsf']['local_etc']}/lsb.hosts"
end