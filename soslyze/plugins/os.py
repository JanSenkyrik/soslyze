import os
from pathlib import Path
from soslyze.utils import parse_text, print_headline, print_value
import re


class Rhel:
    def __init__(self, path):
        lines = []
        if os.path.isfile(path + '/date'):
            self.date = Path(path + '/date').read_text()
        if os.path.isfile(path + '/ip_addr'):
            for line in Path(path + '/ip_addr').read_text().splitlines():
                if re.search(r".*inet .*", line):
                    lines.append(re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}", line).group())
            self.ip = '\n'.join(lines)
            lines.clear()
        if os.path.isfile(path + '/etc/redhat-release'):
            self.release = Path(path + '/etc/redhat-release').read_text()
        if os.path.isfile(path + '/hostname'):
            self.hostname = Path(path + '/hostname').read_text()
        if os.path.isfile(path + '/free'):
            self.ram = Path(path + '/free').read_text()
        if os.path.isfile(path + '/sos_commands/processor/lscpu'):
            self.cpu = ""
            tmp = Path(path + '/sos_commands/processor/lscpu').read_text()
            self.cpu = self.cpu + str(re.search(r"CPU\(s\).*", tmp).group() + "\n")
            self.cpu = self.cpu + str(re.search(r"Core\(s\) per socket.*", tmp).group() + "\n")
            self.cpu = self.cpu + str(re.search(r"Socket\(s\).*", tmp).group())
        if os.path.isfile(path + '/df'):
            for line in Path(path + '/df').read_text().splitlines():
                if re.search(r".*9[0-9]%.*|.*100%.*", line) is not None:
                    lines.append(line)
            self.full_fs = '\n'.join(lines)
            lines.clear()
        if os.path.isfile(path + '/sos_commands/selinux/sestatus'):
            self.selinux = parse_text(path + '/sos_commands/selinux/sestatus',
                                      r"SELinux status.*|Current mode.*")
        if os.path.isfile(path + '/dmidecode'):
            self.virt_what = Path(path + '/dmidecode').read_text().splitlines()[0-3]
        if os.path.isfile(path + '/proc/sys/crypto/fips_enabled'):
            self.fips = Path(path + '/proc/sys/crypto/fips_enabled').read_text()

    def output(self):
        print_headline("### GENERAL INFORMATION ###")
        if hasattr(self, 'hostname'):
            print_value("Hostname:", self.hostname)
        if hasattr(self, 'ip'):
            print_value("NICs:", self.ip)
        if hasattr(self, 'full_fs'):
            print_value("Filesystems over 90% usage:", self.full_fs)
        if hasattr(self, 'selinux'):
            print_value("SELinux:", self.selinux)
        if hasattr(self, 'virt_what'):
            print_value("VM or physical:", self.virt_what)
        if hasattr(self, 'fips'):
            print_value("FIPS mode (0=disabled, 1=enabled):", self.fips)


class Rhel8(Rhel):
    def __init__(self, path):
        super().__init__(path)
        if os.path.isfile(path + '/sos_commands/crypto/update-crypto-policies_--show'):
            self.crypto = Path(path + '/sos_commands/crypto/update-crypto-policies_--show').read_text()

    def output(self):
        super().output()
        if hasattr(self, 'crypto'):
            print_value("Crypto policy:", self.crypto)


class Rhel7(Rhel):
    def __init__(self, path):
        super().__init__(path)

    def output(self):
        super().output()


