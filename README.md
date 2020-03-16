# terraform gcp module
Terraform module to provision google cloud resource. <br/>
This is based on [terraform-google-module](https://registry.terraform.io/modules/terraform-google-modules) 
with a custom validation implementation to validate terraform input variables. <br/>

## Table of contents
[Terraform official validation functionality VS Custom valiation implementation](#terraform-official-validation-functionality-vs-custom-valiation-implementation)<br>
[Custom validation implementation Details](#custom-validation-implementation-details)<br>
[Development](#development)<br>

## Terraform official validation functionality VS Custom valiation implementation

#### [Terraform validate command](https://www.terraform.io/docs/commands/validate.html)
CLI validate only validates static config but it does not validate input variables. 

#### [Terraform input variables custom validation rules](https://www.terraform.io/docs/configuration/variables.html#custom-validation-rules) 
This feature is currently experimental and not suitable for production. It only supports simple validation.

#### [Terraform with Sentinel](https://www.terraform.io/docs/cloud/sentinel/index.html)
Sentinel can define [policies](https://www.terraform.io/docs/cloud/sentinel/import/index.html) 
which is integrated with terraform state to do comprehensive validation and enforcement 
however Sentinel requires [license](https://www.hashicorp.com/products/terraform/pricing/). 

#### [Forseti Terraform Validator](https://github.com/GoogleCloudPlatform/terraform-validator)
Haven't tried a thorough test on Forseti terraform validator but roughly look, 
it does not [support](https://github.com/GoogleCloudPlatform/terraform-validator#resources) google compute network resource.

#### Custom validation implementation
This custom validation implementation make uses of terraform [External Data Source](https://www.terraform.io/docs/providers/external/data_source.html) plugin to call external python program in which we implement comprehensive validation logic on terraform input variables.  

## Custom validation implementation Details
### How is custom validation python being triggered
Each terraform module main.tf will contain an external data block 
in which it will use system path python interpreter to execute a python script. 
In the [query](https://www.terraform.io/docs/providers/external/data_source.html#argument-reference) block, 
you can define parameters you wanna pass into the python script via stdin. 
The parameters values come from terraform input variables. 
```
data "external" "validation" {
  program = ["python", "${path.module}/scripts/validation.py"]

  query = {
    network_continent = jsonencode(var.network_continent)
    subnets           = jsonencode(var.subnets)
    secondary_ranges  = jsonencode(var.secondary_ranges)
  }
}
```

<br/>Inside the python script, you can receive the parameters from stdin as a json string 
and formalize them properly then you can claim back each terraform input variable correspondingly 
in the form of standard python data type, such list, dict etc.  

```
TF_MODULE_PARAMS = json.load(sys.stdin)

network_continent = json.loads(TF_MODULE_PARAMS["network_continent"])
subnets = json.loads(TF_MODULE_PARAMS["subnets"])
secondary_ranges = json.loads(TF_MODULE_PARAMS["secondary_ranges"])
```

### Comparison between terraform variable data type and python data type
in terraform, variable _network_continent_ is defined as string
```
variable "network_continent" {
  type = string
  description = "the continent in which standalone vpc network will be created, it must be one of these values (EU, ASIA, US)"
}
```
in terraform, variable _network_continent_ value will look like
```
network_continent = "EU"
```
in python, variable _network_continent_ is a primitive str data type, its value will look like
```
network_continent
Out[23]: 'EU'
```

<br/>in terraform, variable _subnets_ is defined as 
```
variable "subnets" {
  type        = list(map(string))
  description = "The list of subnets being created"
}
```
in terraform, variable _subnets_ value will looke like
```
  subnets = [
    {
      subnet_name           = local.subnet1_gke_name
      subnet_ip             = "192.168.192.0/23"
      subnet_region         = local.subnet1_region
      subnet_private_access = true
    },
    {
      subnet_name           = local.subnet2_gke_name
      subnet_ip             = "192.168.194.0/23"
      subnet_region         = local.subnet2_region
      subnet_private_access = true
    }
  ]
```
in python, variable _subnets_ is a list of dict, its value will looke like
```
subnets
Out[24]: 
[{'subnet_ip': '192.168.192.0/23',
  'subnet_name': 'gke-poc-269206-standalone-vpc-subnet-gke-europe-west2',
  'subnet_private_access': 'true',
  'subnet_region': 'europe-west2'},
 {'subnet_ip': '192.168.194.0/23',
  'subnet_name': 'gke-poc-269206-standalone-vpc-subnet-gke-europe-west1',
  'subnet_private_access': 'true',
  'subnet_region': 'europe-west1'}]
```

<br/>in terraform, variable _secondary_ranges_ is defined as 
```
variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default     = {}
}
```
in terraform, variable _secondary_ranges_ value will look like
```
  secondary_ranges = {
    "${local.subnet1_gke_name}" = [
      {
        range_name    = "pods"
        ip_cidr_range = "192.168.128.0/19"
      },
      {
        range_name    = "services"
        ip_cidr_range = "192.168.208.0/21"
      },
    ]
    "${local.subnet2_gke_name}" = [
      {
        range_name    = "pods"
        ip_cidr_range = "192.168.160.0/19"
      },
      {
        range_name    = "services"
        ip_cidr_range = "192.168.216.0/21"
      },
    ]
  }
```
in python, variable _secondary_ranges_ is a dict, its value will look like
```
secondary_ranges
Out[25]: 
{'gke-poc-269206-standalone-vpc-subnet-gke-europe-west1': [{'ip_cidr_range': '192.168.160.0/19',
   'range_name': 'pods'},
  {'ip_cidr_range': '192.168.216.0/21', 'range_name': 'services'}],
 'gke-poc-269206-standalone-vpc-subnet-gke-europe-west2': [{'ip_cidr_range': '192.168.128.0/19',
   'range_name': 'pods'},
  {'ip_cidr_range': '192.168.208.0/21', 'range_name': 'services'}]}
```
### How to enforce validation in python script and report error back to terraform
As it explains in terraform [External Program Protocol](https://www.terraform.io/docs/providers/external/data_source.html#external-program-protocol), 
if one of validations fails in python script, we explicitly raise an error, the python error will cause the python script to exit with non-zero exit code. 
The python script non-zero exit code will cause the terraform external data block to fail immediately regardless of other resources' states in main.tf. 
This "fail then exit" behavior will happen to both "terraform plan" and "terraform apply" which is the exact mechanism we need so as to implement validation enforcement.
<br/><br/>For example,  here is a terraform log if validation fails when running "terraform plan", 
the error message from python script will be printed by terraform as well.
```
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.create_service_project_standalone_vpc_network.data.external.validation: Refreshing state...

Error: failed to execute "python": Traceback (most recent call last):
  File "../../../data-networks/standalone-vpc-network/scripts/validation.py", line 82, in <module>
    ALLOWED_CONTINENT_REGION[network_continent]))
ValueError: subnet region europe-west4 must be within allowed list ['europe-west2', 'europe-west1']


  on ../../../data-networks/standalone-vpc-network/main.tf line 4, in data "external" "validation":
   4: data "external" "validation" {
```

<br/>If all validations are passed in python script, the script will exit normally with zero exit code and terraform will continue to the rest of resources in main.tf.
The python script will output a simple message to terraform to indicate the validations are all passed. This is implemented via terraform output variable.
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

validation_result = {
  "validation" = "OK"
}
```
### Benefit of custom validation implementation
Terraform official functionality is limited, Terraform with Sentinel thus seems to be the best solution however it requires license. 
The above implementation gives us a simple and customized way to implement comprehensive validation enforcement. 
The validation script is per module, it can be developed and tested separately.

## Development

### Prerequisite
In order to do development on this repo, you will require

#### [Terraform](https://www.terraform.io/downloads.html)
This repo has been developed and tested based on terraform v0.12.13.

#### [Google Cloud Project](https://console.cloud.google.com/)
A valid gcp project

#### [Google Cloud Service Account](https://cloud.google.com/iam/docs/service-accounts)
The gcp service account run by terraform will require following [gcp iam roles](https://cloud.google.com/iam/docs/understanding-roles) 
```
Compute Instance Admin (v1)
Compute Network Admin
Compute Security Admin
Kubernetes Engine Admin
DNS Administrator
Service Account User
Viewer
```

#### Python Environment
You will need to setup a proper python environment to run the python validation script.
You can use [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-python.html#managing-python) to install a python environment. 
The current version of repo is developed and tested on python 2.7.
```
conda create --name py2 python=2.7
``` 

### Coding
We try to reuse [terraform-google-module](https://registry.terraform.io/modules/terraform-google-modules) as much as possible 
as you can see for the module in this repo, it will [source](https://www.terraform.io/docs/modules/sources.html) from terraform-google-module 
```
module "standalone-vpc-network" {
  source = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/vpc?ref=master"
  ...
  ...
}
```

### Testing

#### Testing for terraform module
The tests folder contains directories for each module, in which it has a main.tf to provision the gcp resources using the module we develop.
The main.tf will be called by the terraform command in the test bash script.

#### Testing for python validation script
We use standard python library [unittest](https://docs.python.org/2/library/unittest.html) framework to write testcases for the python validation script. 
The testcases for validation script is more like an integration test rather than actual unit test on each method in the validation script.
We use python [subprocess](https://docs.python.org/2/library/subprocess.html) to simulate how terraform calls the validation script by passing parameters to stdin and capturing stdout and stderr from the validation script.