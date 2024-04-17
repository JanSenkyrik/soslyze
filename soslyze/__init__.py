from soslyze.plugins.discovery import Discovery
from soslyze.plugins.insights import Insights
from soslyze.plugins.os import Rhel8, Rhel7
from soslyze.plugins.package_manager import Dnf, Yum
from soslyze.plugins.rhui import Rhui
from soslyze.plugins.satellite import Satellite
from soslyze.plugins.subscription_manager import SubscriptionManager
from soslyze.utils import Style, package_present, print_warning
import sys
import os
from pathlib import Path
import re


class SoSLyze:
    def __init__(self):
        """
        Initialization of SoSLyze
        """
        if len(sys.argv) > 1:
            if os.path.isdir(sys.argv[1]):
                if os.path.isdir(sys.argv[1] + '/sos_reports'):
                    self.path = sys.argv[1]
                else:
                    print_warning(
                        "This is not a valid sosreport archive. Exiting..")
                    exit()
            else:
                print_warning("Path is not a folder.")
                exit()
        else:
            print_warning("Missing path to extracted sosreport directory.")
            print("Example: ./soslyze.sh /path/to/sosreport")
            exit()

        if len(re.findall('8[.]', Path(
                self.path + '/etc/redhat-release').read_text())) == 1 or \
                len(re.findall('9[.]', Path(
                    self.path + '/etc/redhat-release').read_text())) == 1:
            self.os = Rhel8(self.path)
        elif len(re.findall('6[.]', Path(
                self.path + '/etc/redhat-release').read_text())) == 1 or \
                len(re.findall('7[.]', Path(
                    self.path + '/etc/redhat-release').read_text())) == 1:
            self.os = Rhel7(self.path)

        if package_present(self.path, "dnf"):
            self.package_manager = Dnf(self.path)
        elif package_present(self.path, "yum"):
            self.package_manager = Yum(self.path)
        if package_present(self.path, "subscription-manager"):
            self.subscription_manager = SubscriptionManager(self.path)
        if package_present(self.path, "insights-client"):
            self.insights = Insights(self.path)
        if package_present(self.path, "satellite"):
            self.satellite = Satellite(self.path)
        if os.path.isfile(self.path + "/etc/rhui/rhui-tools.conf"):
            self.rhui = Rhui(self.path)
        if os.path.isdir(self.path + "/sos_commands/discovery"):
            self.discovery = Discovery(self.path)

    def output(self):
        self.os.output()

        if hasattr(self, "subscription_manager"):
            self.subscription_manager.output()

        if hasattr(self, "package_manager"):
            self.package_manager.output()

        if hasattr(self, "insights"):
            self.insights.output()

        if hasattr(self, "satellite"):
            self.satellite.output()

        if hasattr(self, "rhui"):
            self.rhui.output()

        if hasattr(self, "discovery"):
            self.discovery.output()


SoSLyze().output()
