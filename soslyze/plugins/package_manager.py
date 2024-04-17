import re
import os
from pathlib import Path

from soslyze.utils import print_value, parse_text


class Rpm:
    def __init__(self, path):
        lines = ['{:75s}| {:30s}| {:50s}'
                 .format('Name', 'Vendor', 'Build Host'), '-' * 159]
        for line in Path(
                path + '/sos_commands/rpm/package-data')\
                .read_text().splitlines():
            if re.search(r"^(?!.*Red Hat.*).*", line):
                split = line.split('\t')
                lines.append('{:75s}| {:30s}| {:50s}'
                             .format(split[0], split[3], split[4]))
        self.rpms = '\n'.join(sorted(lines))
        lines.clear()
        tmp = Path(path + '/etc/yum.repos.d/redhat.repo')\
            .read_text().splitlines()
        for i in range(len(tmp)):
            if re.search(r".*enabled *= *1.*", tmp[i]):
                lines.append(tmp[i-3])
                lines.append(tmp[i-1])
                lines.append(tmp[i])
        self.urls = '\n'.join(lines)
        lines.clear()

    def output(self):
        print_value("Packages from 3rd party repositories:", self.rpms)
        print_value("Repo URLs:", self.urls)


class Dnf(Rpm):
    def __init__(self, path):
        super().__init__(path)
        if os.path.isfile(path + '/sos_commands/dnf/dnf_-C_repolist'):
            self.enabled = Path(
                path + '/sos_commands/dnf/dnf_-C_repolist').read_text()
        if os.path.isfile(path + '/sos_commands/dnf/dnf_history'):
            self.history = '\n'.join(Path(
                path + '/sos_commands/dnf/dnf_history').read_text()
                                     .splitlines()[0:15])
        if os.path.isfile(path + "/etc/dnf/dnf.conf"):
            self.exclude = parse_text(
                path + "/etc/dnf/dnf.conf", r'.*exclude.*',
                options=re.IGNORECASE)
        if os.path.isdir(path + '/etc/dnf/vars/'):
            self.vars = '\n'.join(os.listdir(path + '/etc/dnf/vars/'))

    def output(self):
        super().output()
        if hasattr(self, "enabled"):
            print_value("Enabled repositories:", self.enabled)
        if hasattr(self, "history"):
            print_value("Yum/dnf history:", self.history)
        if hasattr(self, "exclude"):
            print_value("Excluded packages by yum/dnf:", self.exclude)
        if hasattr(self, "vars"):
            print_value("Yum/dnf variables:", self.vars)


class Yum(Rpm):
    def __init__(self, path):
        super().__init__(path)
        self.enabled = Path(
            path + '/sos_commands/yum/yum_-C_repolist').read_text()
        self.history = '\n'.join(Path(
            path + '/sos_commands/yum/yum_history').read_text()
                                 .splitlines()[0:15])
        self.exclude = parse_text(path + "/etc/yum.conf", r'.*exclude.*',
                                  options=re.IGNORECASE)
        self.vars = '\n'.join(os.listdir(path + '/etc/yum/vars/'))

    def output(self):
        super().output()
        print_value("Enabled repositories:", self.enabled)
        print_value("Yum/dnf history:", self.history)
        print_value("Excluded packages by yum/dnf:", self.exclude)
        print_value("Yum/dnf variables:", self.vars)
