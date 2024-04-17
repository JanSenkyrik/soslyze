from io import StringIO
from pathlib import Path
from contextlib import redirect_stdout
from rct.cli import CatCertCommand
import re
import os

from soslyze.utils import print_headline, print_value, parse_text


class SubscriptionManager:
    def __init__(self, path):
        lines = []
        if os.path.isfile(path + '/etc/rhsm/rhsm.conf'):
            self.platform = parse_text(path + '/etc/rhsm/rhsm.conf',
                                       r"^(hostname|baseurl|port|repo_ca_cert|ca_cert_dir).*")
            self.proxy = parse_text(path + '/etc/rhsm/rhsm.conf', r"^proxy.*")
        if os.path.isfile(path + "/environment"):
            self.env_proxy = parse_text(path + "/environment", r".*proxy.*")
        self.content_access = False

        if os.path.isdir(path + '/etc/pki/entitlement/'):
            for cert in os.listdir(path + '/etc/pki/entitlement/'):
                catcher = StringIO()
                with redirect_stdout(catcher):
                    exec('CatCertCommand().main(args=["' + path +
                         '/etc/pki/entitlement/' + cert + '", "--no-products", "--no-content"])')
                for line in catcher.getvalue().splitlines():
                    if re.search(r'.*SKU:.*', line):
                        self.content_access = True
                        break
        if os.path.isfile(path + '/sos_commands/subscription_manager/subscription-manager_list_--consumed'):
            self.consumed = parse_text(path + '/sos_commands/subscription_manager/subscription-manager_list_--consumed',
                                       r"^(Subscription Name|Subskriptionsname|Nom de l'abonnement|" +
                                       "SKU|Start|Ends|Pool ID|Status Details).*")
        if os.path.isdir(path + '/etc/rhsm/facts/'):
            for fact in os.listdir(path + '/etc/rhsm/facts/'):
                lines.append(Path(path + '/etc/rhsm/facts/' + fact).read_text())
            self.facts = '\n'.join(lines)
            lines.clear()
        if os.path.isfile(path + '/sos_commands/subscription_manager/subscription-manager_identity'):
            self.lfce = Path(path + '/sos_commands/subscription_manager/subscription-manager_identity').read_text()
        if os.path.isfile(path + '/dmidecode'):
            parse_text(path + '/dmidecode', r".*uuid.*", options=re.IGNORECASE)

    def output(self):
        print_headline("### SUBSCRIPTIONS & REPOSITORIES ###")
        if hasattr(self, "platform"):
            print_value("How is the system registered:", self.platform)
        if hasattr(self, "proxy"):
            print_value("Proxy information (rhsm.conf):", self.proxy)
        if hasattr(self, "env_proxy"):
            print_value("Proxy information (environment):", self.env_proxy)
        if hasattr(self, "content_access"):
            print_value("SCA:", str(self.content_access))
        if hasattr(self, "consumed"):
            print_value("Subscriptions attached:", self.consumed)
        if hasattr(self, "lfce"):
            print_value("CV, LFCE and organization:", self.lfce)
        if hasattr(self, "facts"):
            print_value("Custom RHSM facts:", self.facts)
        if hasattr(self, "uuid"):
            print_value("RHSM/DMI UUID:", self.uuid)
