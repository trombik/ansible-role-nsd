import os

import testinfra
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def get_service_name(host):
    if host.system_info.distribution == 'freebsd':
        return 'nsd'
    elif host.system_info.distribution == 'openbsd':
        return 'nsd'
    elif host.system_info.distribution == 'ubuntu':
        return 'nsd'
    elif host.system_info.distribution == 'centos':
        return 'nsd'
    raise NameError('Unknown distribution')


def get_ansible_vars(host):
    return host.ansible.get_variables()


def get_ansible_facts(host):
    return host.ansible('setup')['ansible_facts']


def get_ping_target(host):
    ansible_vars = get_ansible_vars(host)
    if ansible_vars['inventory_hostname'] == 'master1':
        return 'slave1' if is_docker(host) else '192.168.21.201'
    elif ansible_vars['inventory_hostname'] == 'slave1':
        return 'master1' if is_docker(host) else '192.168.21.200'
    else:
        raise NameError(
                "Unknown host `%s`" % ansible_vars['inventory_hostname']
              )


def read_remote_file(host, filename):
    f = host.file(filename)
    assert f.exists
    assert f.content is not None
    return f.content.decode('utf-8')


def is_docker(host):
    ansible_facts = get_ansible_facts(host)
    if 'ansible_virtualization_type' in ansible_facts:
        if ansible_facts['ansible_virtualization_type'] == 'docker':
            return True
    return False


def read_digest(host, filename):
    uri = "ansible://client1?ansible_inventory=%s" \
            % os.environ['MOLECULE_INVENTORY_FILE']
    client1 = host.get_host(uri)
    return read_remote_file(client1, filename)


def get_listen_ports(host):
    return [53]


def get_ipv4_address(host):
    address = None
    ansible_facts = get_ansible_facts(host)
    if host.system_info.distribution == "freebsd":
        address = ansible_facts['ansible_em1']['ipv4'][0]['address']
    elif host.system_info.distribution == "openbsd":
        address = ansible_facts['ansible_em1']['ipv4'][0]['address']
    elif host.system_info.distribution == "ubuntu":
        address = ansible_facts['ansible_eth1']['ipv4']['address']
    elif host.system_info.distribution == "centos":
        address = ansible_facts['ansible_eth1']['ipv4']['address']
    else:
        raise NameError('Unknown distribution')
    return address


def test_hosts_file(host):
    f = host.file('/etc/hosts')

    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root' or f.group == 'wheel'


def test_icmp_from_slave(host):
    ansible_vars = get_ansible_vars(host)
    if ansible_vars['inventory_hostname'] == 'slave1':
        target = get_ping_target(host)
        cmd = host.run("ping -c 1 -q %s" % target)

        assert cmd.succeeded


def test_icmp_from_master(host):
    ansible_vars = get_ansible_vars(host)
    if ansible_vars['inventory_hostname'] == 'master1':
        target = get_ping_target(host)
        cmd = host.run("ping -c 1 -q %s" % target)

        assert cmd.succeeded


def test_port(host):
    address = get_ipv4_address(host)
    ports = get_listen_ports(host)

    for p in ports:
        assert host.socket("udp://%s:%d" % (address, p)).is_listening


def test_axfr_on_slave(host):
    ansible_vars = get_ansible_vars(host)
    if ansible_vars['inventory_hostname'] == 'slave1':
        cmd = host.run("dig axfr trombik.org @192.168.21.200")

        assert cmd.succeeded
