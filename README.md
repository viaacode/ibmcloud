# IBM Cloud resources



## terraform

Code describing meemoo's infrastructure in the IBM cloud using the
[Terrafom IBM provider](https://github.com/IBM-Cloud/terraform-provider-ibm).

## openshift

An openshift cluster is running in the IBM cloud. This repository contains 
general openshift resources shared by different applications. These resources are outside of the scope
of the application deployment pipelines.

- *certificate secret for private ingress*

    Non public services are exposed via IBM's default private ingress controller.
    The template is used to create a shared wildcard certificate secret in the default
    namespace that can be used by the the private ingress resources according to
    the example provided.
