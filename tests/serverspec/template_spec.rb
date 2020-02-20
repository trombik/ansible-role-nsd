require "spec_helper"
require "serverspec"
require "default_spec"

domain_dir = case os[:family]
             when "freebsd"
               "/usr/local/etc/nsd"
             when "openbsd"
               "/var/nsd/etc"
             else
               "/etc/nsd"
             end
# trombik.org.  IN SOA a.ns.trombik.org. hostmaster.trombik.org. 2013020201 10800 3600 604800 3600

domains = [
  {
    name: "trombik.org",
    default_ttl: 86_400,
    soa: {
      ttl: 864_000,

      # required
      mname: "a.ns.trombik.org",

      # required
      rname: "hostmaster.trombik.org",

      # required
      serial: 2_013_020_201,
      refresh: 10_800,
      retry: 3600,
      expire: 604_800,
      negative_cache_ttl: 3600
    },
    ns: [
      { name: "a.ns", address: "192.168.1.1", ttl: 864_000 },
      { name: "b.ns", address: "192.168.1.2", ttl: 864_000 }
    ],
    a: [
      { name: "www", addresses: %w[192.168.1.3 192.168.1.4] },
      { name: "mail", addresses: %w[192.168.1.5] }
    ],
    mx: [
      { host: "mail.trombik.org.", prio: 50 },
      { host: "external.example.org.", prio: 200 }
    ],
    cname: [
      { host: "alias", addresses: %w[canonical] }
    ],
    txt: [
      { name: "@", addresses: %w[foo bar] },
      { name: "txt", addresses: %w[buz] }
    ],
    post_config: [
      ";; post_config",
      "foobarbuz IN A 192.168.255.255"
    ]
  }
]

describe "domain" do
  domains.each do |domain|
    describe file "#{domain_dir}/#{domain[:name]}.zone" do
      it { should be_file }
      its(:content) { should match(/^\$TTL\s+#{domain[:default_ttl]}$/) }
      its(:content) { should match(/^#{domain[:name]}\.\s+86400\s+IN\s+SOA\s+#{domain[:soa][:mname]}\.\s+#{domain[:soa][:rname]}.\s+#{domain[:soa][:serial]}\s+#{domain[:soa][:refresh]}\s+#{domain[:soa][:retry]}\s+#{domain[:soa][:expire]}\s+#{domain[:soa][:negative_cache_ttl]}$/) }
      domain[:ns].each do |ns|
        its(:content) { should match(/^#{domain[:name]}\.\s+#{ns[:ttl]}\s+IN\s+NS\s+#{ns[:name]}$/) }
        its(:content) { should match(/^#{ns[:name]}\s+#{ns[:ttl]}\s+IN\s+A\s+#{ns[:address]}$/) }
        # a.ns 864000 IN A 192.168.1.1
      end
      domain[:mx].each do |mx|
        # trombik.org.  IN MX 50 mx.trombik.org.
        its(:content) { should match(/^#{domain[:name]}\.\s+IN\s+MX\s+#{mx[:prio]}\s+#{mx[:host]}$/) }
      end
      domain[:a].each do |a|
        a[:addresses].each do |addr|
          its(:content) { should match(/^#{a[:name]}\s+IN\s+A\s+#{addr}$/) }
        end
      end
      domain[:txt].each do |t|
        t[:addresses].each do |addr|
          its(:content) { should match(/^#{t[:name]}\s+IN\s+TXT\s+"#{addr}"$/) }
        end
      end
      domain[:post_config].each do |line|
        its(:content) { should match(/^#{line}$/) }
      end
    end
  end
end
