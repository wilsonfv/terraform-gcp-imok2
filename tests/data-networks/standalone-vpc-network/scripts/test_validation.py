import unittest
import os
import json
from subprocess import Popen, PIPE


VALIDATION_PYFILE_PATH = \
    os.path.dirname(__file__) \
    + '/../../../../data-networks/standalone-vpc-network/scripts/'


def generate_tf_params(network_continent, subnets, secondary_ranges):
    tf_parameter = {
        "network_continent": json.dumps(network_continent),
        "subnets": json.dumps(subnets),
        "secondary_ranges": json.dumps(secondary_ranges)
    }
    return tf_parameter


class ValidationTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.proc = None

    def setUp(self):
        self.proc = Popen(['python',
                           VALIDATION_PYFILE_PATH + 'validation.py'],
                          stdin=PIPE,
                          stdout=PIPE,
                          stderr=PIPE)

    def test_validation_ok(self):
        network_continent = "EU"
        subnets = [
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west2",
                "subnet_region": "europe-west2",
                "subnet_ip": "192.168.192.0/23",
                "subnet_private_access": "true"
            },
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west1",
                "subnet_region": "europe-west1",
                "subnet_ip": "192.168.194.0/23",
                "subnet_private_access": "true"
            }]
        secondary_ranges = {
            "gke-poc-269206-standalone-vpc-subnet-gke-europe-west2": [
                {
                    "range_name": "pods",
                    "ip_cidr_range": "192.168.128.0/19"
                },
                {
                    "range_name": "services",
                    "ip_cidr_range": "192.168.208.0/21"
                }],
            "gke-poc-269206-standalone-vpc-subnet-gke-europe-west1": [
                {
                    "range_name": "pods",
                    "ip_cidr_range": "192.168.160.0/19"
                },
                {
                    "range_name": "services",
                    "ip_cidr_range": "192.168.216.0/21"
                }]}

        stdout_result, stderr_result = \
            self.proc.communicate(
                json.dumps(generate_tf_params(network_continent,
                                              subnets,
                                              secondary_ranges)))

        # print('return code: ', self.proc.returncode)
        # print('stdout: ', stdout_result)
        # print('stderr: ', stderr_result)

        self.assertEqual(self.proc.returncode, 0)
        self.assertRegexpMatches(stdout_result, 'validation.*OK')
        self.assertEqual(stderr_result, '')

    def test_should_fail_if_subnet_length_is_empty(self):
        network_continent = ""
        subnets = []
        secondary_ranges = {}

        stdout_result, stderr_result = \
            self.proc.communicate(
                json.dumps(generate_tf_params(network_continent,
                                              subnets,
                                              secondary_ranges)))

        self.assertEqual(1, self.proc.returncode)
        self.assertEqual('', stdout_result)
        self.assertRegexpMatches(stderr_result,
                                 '.*Must provide at least one subnet.*')

    def test_should_fail_if_network_continent_is_invalid(self):
        network_continent = "Europe"
        subnets = [
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west2",
                "subnet_region": "europe-west2",
                "subnet_ip": "192.168.192.0/23",
                "subnet_private_access": "true"
            }]
        secondary_ranges = {}

        stdout_result, stderr_result = \
            self.proc.communicate(
                json.dumps(generate_tf_params(network_continent,
                                              subnets,
                                              secondary_ranges)))

        self.assertEqual(1, self.proc.returncode)
        self.assertEqual('', stdout_result)
        self.assertRegexpMatches(stderr_result,
                                 '.*network continent.*must be within allowed list')

    def test_should_fail_if_subnet_region_is_invalid(self):
        network_continent = "EU"
        subnets = [
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west2",
                "subnet_region": "europe-west2",
                "subnet_ip": "192.168.192.0/23",
                "subnet_private_access": "true"
            },
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west1",
                "subnet_region": "europe-west4",
                "subnet_ip": "192.168.194.0/23",
                "subnet_private_access": "true"
            }]
        secondary_ranges = {}

        stdout_result, stderr_result = \
            self.proc.communicate(
                json.dumps(generate_tf_params(network_continent,
                                              subnets,
                                              secondary_ranges)))

        self.assertEqual(1, self.proc.returncode)
        self.assertEqual('', stdout_result)
        self.assertRegexpMatches(stderr_result,
                                 '.*subnet region.*must be within allowed list')

    def test_should_fail_if_cidr_is_invalid(self):
        network_continent = "EU"
        subnets = [
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west2",
                "subnet_region": "europe-west2",
                "subnet_ip": "192.168.192.0/23",
                "subnet_private_access": "true"
            },
            {
                "subnet_name": "gke-poc-269206-standalone-vpc-subnet-gke-europe-west1",
                "subnet_region": "europe-west1",
                "subnet_ip": "192.168.255.0/24",
                "subnet_private_access": "true"
            }]
        secondary_ranges = {}

        stdout_result, stderr_result = \
            self.proc.communicate(
                json.dumps(generate_tf_params(network_continent,
                                              subnets,
                                              secondary_ranges)))

        self.assertEqual(1, self.proc.returncode)
        self.assertEqual('', stdout_result)
        self.assertRegexpMatches(stderr_result,
                                 '.*CIDR.*is not within allowed devops ranges.*')


if __name__ == '__main__':
    unittest.main()
