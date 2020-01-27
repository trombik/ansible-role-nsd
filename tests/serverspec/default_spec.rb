require "spec_helper"
require "serverspec"

package = "nsd"
service = "nsd"
config_dir = "/etc/nsd"
config_mode = 640
user = "nsd"
group = "nsd"
default_user = "root"
default_group = "wheel"
ports = [53]
extra_groups = %w[bin]
extra_packages = []
db_dir = ""

case os[:family]
when "openbsd"
  user = "_nsd"
  group = "_nsd"
  config_dir = "/var/nsd/etc"
  package = nil
  db_dir = "/var/nsd/db"
when "freebsd"
  config_dir = "/usr/local/etc/nsd"
  db_dir = "/var/db/nsd"
when "ubuntu"
  db_dir = "/var/lib/nsd"
  default_group = "root"
  extra_packages = %w[dnsutils]
when "redhat"
  db_dir = "/var/lib/nsd"
  default_group = "root"
  extra_packages = %w[bind-utils]
end

config = "#{config_dir}/nsd.conf"
zones = %w[trombik.org.zone]

unless package.nil?
  describe package(package) do
    it { should be_installed }
  end
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe user(user) do
  it { should exist }
  it { should belong_to_group group }
  extra_groups.each do |g|
    it { should belong_to_group g }
  end
end

describe file(config_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into os[:family] == "openbsd" ? group : default_group }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode config_mode }
  it { should be_owned_by default_user }
  it { should be_grouped_into group }
  its(:content) { should match(/Managed by ansible/) }
end

describe file(db_dir) do
  mode = case os[:family]
         when "openbsd"
           775
         when "redhat"
           750
         else
           755
         end
  it { should exist }
  it { should be_directory }
  it { should be_owned_by os[:family] == "openbsd" ? default_user : user }
  it { should be_grouped_into group }
  it { should be_mode mode }
end

zones.each do |z|
  describe file("#{config_dir}/#{z}") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
    its(:content) { should match(/Managed by ansible/) }
  end
end

case os[:family]
when "openbsd"
  describe file("/etc/rc.conf.local") do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
  end
when "redhat"
  describe file("/etc/sysconfig/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end
when "ubuntu"
  describe file("/etc/default/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end

  describe service("systemd-resolved") do
    it { should_not be_running }
  end
when "freebsd"
  describe file("/etc/rc.conf.d") do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
  end

  describe file("/etc/rc.conf.d/#{service}") do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command("host -t axfr trombik.org 127.0.0.1") do
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: \d+/) }
  its(:stdout) { should match(/trombik\.org\.\s+86400\s+IN\s+SOA\s+a\.ns\.trombik.org\.\s+hostmaster\.trombik\.org\.\s+2013020201\s+10800\s+3600\s+604800\s+3600/) }

  its(:exit_status) { should eq 0 }
end
