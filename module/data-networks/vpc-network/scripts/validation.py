import sys
import json
from ipaddress import ip_network
from functools import reduce

ALLOWED_MIN_CIDR_RANGE = '192.168.0.0/18'
ALLOWED_MAX_CIDR_RANGE = '192.168.254.255/32'
ALLOWED_CONTINENT_REGION = {
    "EU": ["europe-west2", "europe-west1"],
    "ASIA": ["asia-east2", "asia-southeast1"],
    "US": ["us-east4", "us-central1"]
}


def get_all_cidr_ranges(subnets, secondary_ranges):
    """
    return all cidr ranges from subnets and secondary_ranges
    :param subnets: List
    :param secondary_ranges: dict
    """
    flat_secondary_ranges = reduce(lambda x, value: x + value,
                                   secondary_ranges.values(),
                                   [])

    return reduce(lambda x, y: x + [y['subnet_ip']],
                  subnets,
                  []) \
           + reduce(lambda x, y: x + [y['ip_cidr_range']],
                    flat_secondary_ranges,
                    [])


def is_subnets_length_greater_than_zero(subnets):
    return len(subnets) > 0


def is_cidr_within_allowed_ranges(cidr, shared_vpc_host):
    if shared_vpc_host:
        return True
    else:
        return ip_network(unicode(ALLOWED_MIN_CIDR_RANGE)) \
               <= ip_network(unicode(cidr)) \
               < ip_network(unicode(ALLOWED_MAX_CIDR_RANGE))


def is_network_continent_allowed(network_continent):
    return network_continent in ALLOWED_CONTINENT_REGION.keys()


def is_subnet_region_allowed(network_continent, subnet_region):
    return subnet_region in ALLOWED_CONTINENT_REGION[network_continent]


if __name__ == '__main__':
    TF_MODULE_PARAMS = json.load(sys.stdin)

    validation_result = {
        "validation": "OK"
    }

    network_continent = json.loads(TF_MODULE_PARAMS["network_continent"])
    subnets = json.loads(TF_MODULE_PARAMS["subnets"])
    secondary_ranges = json.loads(TF_MODULE_PARAMS["secondary_ranges"])
    shared_vpc_host = json.loads(TF_MODULE_PARAMS["shared_vpc_host"])

    # with open('network_continent.tfdebug.txt', 'w') as outfile:
    #     json.dump(network_continent, outfile)
    # with open('subnets.tfdebug.txt', 'w') as outfile:
    #     json.dump(subnets, outfile)
    # with open('secondary_ranges.tfdebug.txt', 'w') as outfile:
    #     json.dump(secondary_ranges, outfile)
    # with open('shared_vpc_host.tfdebug.txt', 'w') as outfile:
    #     json.dump(shared_vpc_host, outfile)

    if not is_subnets_length_greater_than_zero(subnets):
        raise ValueError('Must provide at least one subnet')

    if not is_network_continent_allowed(network_continent):
        raise ValueError('network continent {} must be within allowed list {}'
                         .format(network_continent,
                                 ALLOWED_CONTINENT_REGION.keys()))

    for subnet in subnets:
        if not is_subnet_region_allowed(network_continent,
                                        subnet['subnet_region']):
            raise ValueError('subnet region {} must be within allowed list {}'
                             .format(subnet['subnet_region'],
                                     ALLOWED_CONTINENT_REGION[network_continent]))

    all_cidr_ranges = get_all_cidr_ranges(subnets, secondary_ranges)
    for cidr in all_cidr_ranges:
        if not is_cidr_within_allowed_ranges(cidr, shared_vpc_host):
            raise ValueError('CIDR {} is not within allowed devops ranges, '
                             'lowest allowed range: {}, '
                             'highest allowed range: {}'
                             .format(cidr,
                                     ALLOWED_MIN_CIDR_RANGE,
                                     ALLOWED_MAX_CIDR_RANGE))

    # if all validations pass, output a json string back to terraform
    print(json.dumps(validation_result))
