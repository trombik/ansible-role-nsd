# `trombik.nsd`

[![Build Status](https://travis-ci.com/trombik/ansible-role-nsd.svg?branch=master)](https://travis-ci.com/trombik/ansible-role-nsd)

`ansible` role for `nsd`.

# Requirements

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `nsd_package` | Package name of `nsd` | `{{ __nsd_package }}` |
| `nsd_service` | Service name of `nsd` | `{{ __nsd_service }}` |
| `nsd_extra_packages` | A list of extra packages to install | `[]` |
| `nsd_user` | User name of `nsd` | `{{ __nsd_user }}` |
| `nsd_group` | Group name of `nsd` | `{{ __nsd_group }}` |
| `nsd_extra_groups` | A list of extra groups for `nsd` user | `[]` |
| `nsd_config_dir` | Path to the configuration directory | `{{ __nsd_config_dir }}` |
| `nsd_config_file` | Path to `nsd.conf` | `{{ nsd_config_dir }}/nsd.conf` |
| `nsd_config` | The content of `nsd.conf` | `""` |
| `nsd_flags` | See below | `""` |
| `nsd_zones` | See below | `[]` |
| `nsd_zonesdir` | | `{{ __nsd_zonesdir }}` |
| `nsd_pid_dir` | Path to PID directory | `{{ __nsd_pid_dir }}` |
| `nsd_pid_file` | Path to PID file | `{{ nsd_pid_dir }}/nsd.pid` |
| `nsd_include_x509_certificate` | See below | `false` |

## `nsd_flags`

This variable is used for overriding defaults for startup scripts. In Debian
variants, the value is the content of `/etc/default/nsd`. In RedHat
variants, it is the content of `/etc/sysconfig/nsd`. In FreeBSD, it
is the content of `/etc/rc.conf.d/nsd`. In OpenBSD, the value is
passed to `rcctl set nsd`.

Note that the file is not always be used. Some distributions ignore the file.

## `nsd_include_x509_certificate`

When true, include
[`trombik.x509_certificate`](https://github.com/trombik/ansible-role-x509_certificate)
during the play, which can be used to install X509 certificates.

## `nsd_zones`

| Key | Description | Mandatory? |
|-----|-------------|------------|
| `name` | File name of the zone file (file name only) | yes |
| `config` | Content of the zone file | no |
| `state` | Either `present` or `absent` | no |
| `yaml` | Use `templates/config_yaml.j2` as template (experimental) | no |

## Debian

| Variable | Default |
|----------|---------|
| `__nsd_service` | `nsd` |
| `__nsd_package` | `nsd` |
| `__nsd_config_dir` | `/etc/nsd` |
| `__nsd_user` | `nsd` |
| `__nsd_group` | `nsd` |
| `__nsd_pid_dir` | `/run/nsd` |
| `__nsd_zonesdir` | `/var/lib/nsd` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__nsd_service` | `nsd` |
| `__nsd_package` | `dns/nsd` |
| `__nsd_config_dir` | `/usr/local/etc/nsd` |
| `__nsd_user` | `nsd` |
| `__nsd_group` | `nsd` |
| `__nsd_pid_dir` | `/var/run/nsd` |
| `__nsd_zonesdir` | `/var/db/nsd` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__nsd_service` | `nsd` |
| `__nsd_package` | `false` |
| `__nsd_config_dir` | `/var/nsd/etc` |
| `__nsd_user` | `_nsd` |
| `__nsd_group` | `_nsd` |
| `__nsd_pid_dir` | `/var/nsd/run` |
| `__nsd_zonesdir` | `/var/nsd/zones` |

## RedHat

| Variable | Default |
|----------|---------|
| `__nsd_service` | `nsd` |
| `__nsd_package` | `nsd` |
| `__nsd_config_dir` | `/etc/nsd` |
| `__nsd_user` | `nsd` |
| `__nsd_group` | `nsd` |
| `__nsd_pid_dir` | `/run/nsd` |
| `__nsd_zonesdir` | `/var/lib/nsd` |

# Dependencies

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - role: trombik.redhat_repo
      when: ansible_os_family == 'RedHat'
    - role: ansible-role-nsd
  pre_tasks:
    - name: Dump all hostvars
      debug:
        var: hostvars[inventory_hostname]
  post_tasks:
    - name: List all services (systemd)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; systemctl list-units --type service"
      changed_when: false
      when:
        - ansible_os_family == 'RedHat' or ansible_os_family == 'Debian'
    - name: list all services (FreeBSD service)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; service -l"
      changed_when: false
      when:
        - ansible_os_family == 'FreeBSD'
  vars:
    os_nsd_flags:
      OpenBSD: ""
      FreeBSD: ""
      Debian: ""
      RedHat: ""
    nsd_flags: "{{ os_nsd_flags[ansible_os_family] }}"


    nsd_zones:
      - name: trombik.org.zone
        config: |
          $TTL 86400
          trombik.org. IN SOA a.ns.trombik.org. hostmaster.trombik.org. 2013020201 10800 3600 604800 3600
          trombik.org. IN NS a.ns
          trombik.org. IN NS b.ns
          ;;
          a.ns  IN A 192.168.1.1
          b.ns  IN A 192.168.1.2
          www   IN A 192.168.1.3
          mail  IN A 192.168.1.5
    os_nsd_extra_packages:
      FreeBSD: []
      Debian: ["dnsutils"]
      OpenBSD: []
      RedHat: ["bind-utils"]
    nsd_extra_packages: "{{ os_nsd_extra_packages[ansible_os_family] }}"
    nsd_extra_groups: []
    nsd_config: |
      server:
        server-count: 1
        do-ip4: yes
        do-ip6: no
        verbosity: 1
        username: "{{ nsd_user }}"
        zonesdir: "{{ nsd_zonesdir }}"
        database: ""
        hide-version: no
        pidfile: "{{ nsd_pid_file }}"

      remote-control:
        {% if ansible_os_family == 'OpenBSD' %}
        control-enable: yes
        {% else %}
        control-enable: no
        {% endif %}
        control-interface: 127.0.0.1
        control-port: 8952

      zone:
        name: "trombik.org"
        zonefile: "{{ nsd_config_dir }}/trombik.org.zone"
        provide-xfr: 127.0.0.1 NOKEY
        provide-xfr: 192.168.1.1 NOKEY

    redhat_repo_extra_packages:
      - epel-release
    redhat_repo:
      epel:
        mirrorlist: "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-{{ ansible_distribution_major_version }}&arch={{ ansible_architecture }}"
        gpgcheck: yes
        enabled: yes

    # XXX OpenBSD's rc.subr controls nsd by nsd-control
    os_nsd_include_x509_certificate:
      OpenBSD: yes
      FreeBSD: no
      Debian: no
      RedHat: no
    nsd_include_x509_certificate: "{{ os_nsd_include_x509_certificate[ansible_os_family] }}"
    x509_certificate_debug_log: yes
    x509_certificate:
      - name: nsd_server
        state: present
        secret:
          path: "{{ nsd_config_dir }}/nsd_server.key"
          owner: "{{ nsd_user }}"
          group: "{{ nsd_group }}"
          mode: "0640"
          key: |
            -----BEGIN RSA PRIVATE KEY-----
            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
            -----END RSA PRIVATE KEY-----
        public:
          path: "{{ nsd_config_dir }}/nsd_server.pem"
          key: |
            -----BEGIN CERTIFICATE-----
            MIIDmDCCAgACCQCPl2UlWTXJCzANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANu
            c2QwHhcNMjAwMTI2MTE0MzM0WhcNMzAwMTIzMTE0MzM0WjAOMQwwCgYDVQQDDANu
            c2QwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDBZ75jsshnNwg+/J2f
            a1SfA9ivfIhzr6d+L0J6iagXgrYdFMDcHjWSfRyftnxHLW9iZC6o9wRU5ij6lcnp
            ggZKMpimIVkjyG+IbVVzAYBNdwMfW2bX5yprgCieS9vjh1ZFF90oGLFG1+AhOEW2
            u/ocwwK3kVArojCeLqfJJ3ASwEe9x/b7GxfZddrKdirNaq2ziPUXND0Wcm3xBhCu
            3tzOgt7Cmlh4hzlAdUcJHkcR41sNW63jx3t1EeiXOgvNR0NWdWTLn10aARvFgVyi
            KhqdGGa6ZLgkcI+SfxNhzaHCkbcXgfECY/oY43WLVB+IAbYgCruqnSwSzZiVUdvd
            BcK1XMnqjtEJXpCOYjGnJ20KxLJ6Oz8NRd/HXY5W+QxuJsOFBQ5N0mLhDC7GbP4K
            v7Grz0uh85mfapdG798ubcd2yZoqp9+YbyPryuID/BfcOM7mb/kHljAEgB3gvL2i
            hnDQcdt7xga0LIeHyBnoc6ChDjJSJ9aIPov9ayPXZkxCLasCAwEAATANBgkqhkiG
            9w0BAQsFAAOCAYEAgfzUIOz0PEMURIGrltL7ctKP42E7GysZA12xxId2alwwIfaa
            d3/KdOQkqDoME7LhrIFGfH0OFtN9gK7MoM/m94QTHptrIR12TcO2YXXHmg2rJeKz
            Rx6CqOGKdi7LMQ4l2GbKuaZ62JkTwhLKiWigzYMPSuFlKiYfmzBxO51eXK0c/BW4
            zMyql2SYcbj0b29t1nrMCbIQ2f3qpTBr0AuVa801TAoPYm0xdjJ8li5zUmbNzKtK
            RA0TCm997P0IDmi2KAyKMi9031SG6PZhydweN9JvEuC13fvpAxBpEN4EQfoYtHoB
            J+fOkyEjhu9DibdY9VK2+96/dLupYBtQUf30zETUvpwaH5qxtmGJNgkTtxAK54dX
            M2JmTtmZP2msZSfH8WOGL/w6MfIlhNKQAc/umnZ6MjAHTzx/xVhtofbIvpwmIR0X
            kxvGrQaoXdt5VsOlieqK3Xm4ZMWANLTrNZb+bYbdpuwDFfdbBrRY1SeRzuDkNov/
            pkbsds6pWtX9s/QA
            -----END CERTIFICATE-----
      - name: nsd_control
        state: present
        secret:
          path: "{{ nsd_config_dir }}/nsd_control.key"
          owner: "{{ nsd_user }}"
          group: "{{ nsd_group }}"
          mode: "0640"
          key: |
            -----BEGIN RSA PRIVATE KEY-----
            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
            -----END RSA PRIVATE KEY-----
        public:
          path: "{{ nsd_config_dir }}/nsd_control.pem"
          key: |
            -----BEGIN CERTIFICATE-----
            MIIDoDCCAggCCQD1GtHU1uV8sTANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANu
            c2QwHhcNMjAwMTI2MTE0MzM0WhcNMzAwMTIzMTE0MzM0WjAWMRQwEgYDVQQDDAtu
            c2QtY29udHJvbDCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAKmuIR3u
            zA1lFdKfbm21gOBoL7j4n+OLbACAZVLsfVFT1fVvgSSkRgDdb6QxXKFRc+gImhLo
            qnnmQOCSrfIJ6OUIbwmcxIxPNWPWUPDSWXsLkxeh9H5UEnGeG+0TBfXIvqYd/gwW
            Nx3SnKVqT+ZqwTZIqGDNE3do08GWpan0K+V3TQ6F0GMepHDnX/htauJu7L8SnlK2
            MxZr4+ae11r2IXLbGFCi9rSaUDtrVj8QmiaCetbcC805b7tHCh4ivql6IvIa3um3
            3XUK7apc35gKxkxyR0c9LiKKmz+QNZANLRUn8cszelAWoj3KnZznKnMpj/MPcBTM
            sfVRgqHGveVHDakC21PFCoA3UwUCQAscenCqdI1XLfuF1G0lNt1nLGA0oFluzLL2
            MpVKRcVWBsT5cYqbsZ7tnKhDX1RwUzdV/K42WL0pesTcqJ2sAcpdSmfknEo5O62+
            vilEghlHwuAtc0zmJqIg/4Sf1GM4bhtBJ5kQsA/eFAqQHl/E8bIISPyfbwIDAQAB
            MA0GCSqGSIb3DQEBCwUAA4IBgQB3EyRMABxd3QCIe/KBDR5ISmy5tCDsySk6Iopm
            NPNPsoPdh+BGFnFrWv0vGIaXUqTX8e4rKfB+Ihe6ZML2NY7aFHvx9te9gIF+JheP
            s5AWWeVtB6mypWMk6hQPTu/DZbdp6zAz2LmTQafd7tTrl/b4+hztGtF3NRFyG1N7
            6FvFSdPZYg9Q3fQUTGM1t+yXGPLLpFzbAsEqvHDyN+v/VlROJGNBbZHcY18W3QbZ
            tS8+nol+syWmrMkOKX/K4aC8ENN03mStj41wCKb1sap7Nh0/Hr9S180YJnjp8Vzx
            3d6Fcc5IRhngpyx6Xj/HNTBJ7X0kcVE5CFha0pzjhgJyPnlklxd+ZFAAsIyZ2KD+
            qg68RpQ46Qa8V/HjURKCITNbc8XkmxxSxV2Vq4/NFXo6Z1HicrofUMKpKT8FoBFn
            uKo5LvWdgHgmn/r/SrFomUgg1eNliTyNF/5wvBRxPSTcrDXhfmFLwKOrW404wIG0
            LVeiZ2BZ9wcrvkS1s2/uSWM1u5Y=
            -----END CERTIFICATE-----
```

# License

```
Copyright (c) 2020 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>
