![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Using the Deployment Operator with an inline configuration

* [Introduction](#introduction)
* [Using the inline configuration method](#using-the-inline-configuration-method)
  * [Create the working folder](#create-the-working-folder)
  * [Step 1 - Create the order secrets](#step-1-create-the-order-secrets)
  * [Step 2. Create the Custom Resource file](#step-2-create-the-custom-resource-file)
  * [Step 3. Deploy SAS Viya using the operator](#step-3-deploy-sas-viya-using-the-operator)
* [Navigation](#navigation)
* [Navigation](#navigation-1)

## Introduction

To recap... in the previous lab exercises you have deployed the operator in its own namespace, running with cluster-wide mode.

In the last lab, see [here](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md), you used the operator with a Git repository, to deploy a Viya environment and then upgrade it.

Now you will examine using the operator with an inline configuration.

In the real world we would still recommend placing the configuration files under version control, but we won't be using your GitLab instance for this exercise.

***This exercise assumes that you have completed the initial setup steps, see [here](/06_Deployment_Steps/06_091_Deployment_Operator_setup.md)***.

## Using the inline configuration method

In this exercise you will deploy a new SAS Viya environment into the 'lab' namespace. For this you will create the secrets for the license, entitlement certificates and the CA certificate, rather than referencing the files in a Git project.

Then the Viya configuration will be provided inline in the Custom Resource yaml.

### Create the working folder

1. Issue the following command to create the working folder for the inline exercises.

    ```bash
    mkdir -p ~/project/operator-driven/inline-projects/lab
    ```

### Step 1 - Create the order secrets

The first step is to create the secrets for the order, this includes the license and certificates. To save you from spending hours editing yaml files we will take a couple of short-cuts. :-)

Using this approach has the advantage that it keeps the secrets out of the Custom Resource yaml file, separate from the SAS Viya configuration.

1. Issue the following command to create the `order-secrets.yaml` file. Make sure you copy the block of text in its entirety, preserving the indentation.

   ```bash
   cd ~/project/operator-driven/inline-projects/lab
   tee ~/project/operator-driven/inline-projects/lab/order-secrets.yaml > /dev/null << "EOF"
   apiVersion: v1
   kind: Secret
   metadata:
     name: order-secrets
   type: Opaque
   stringData:
     license: eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlDVFRDQ0FkU2dBd0lCQWdJTUcxK0ZkejR5dTNoS2lEcWpNQW9HQ0NxR1NNNDlCQU1DTUc0eEN6QUpCZ05WQkFZVEFsVlRNUmN3RlFZRFZRUUlFdzVPYjNKMGFDQkRZWEp2YkdsdVlURU5NQXNHQTFVRUJ4TUVRMkZ5ZVRFYk1Ca0dBMVVFQ2hNU1UwRlRJRWx1YzNScGRIVjBaU0JKYm1NdU1Sb3dHQVlEVlFRREV4Rk1hV05sYm5ObElGSnZiM1FnTWpBeE9EQWVGdzB4T0RBek1qWXhOelExTWpsYUZ3MHlPREF6TWpZeE56UTFNamxhTUhZeEN6QUpCZ05WQkFZVEFsVlRNUmN3RlFZRFZRUUlFdzVPYjNKMGFDQkRZWEp2YkdsdVlURU5NQXNHQTFVRUJ4TUVRMkZ5ZVRFYk1Ca0dBMVVFQ2hNU1UwRlRJRWx1YzNScGRIVjBaU0JKYm1NdU1TSXdJQVlEVlFRREV4bE1hV05sYm5ObElFbHVkR1Z5YldWa2FXRjBaU0F5TURFNE1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRTMrM29QV25UVFBoODM2TzBnMXNkWm94RldTQS9XVzN2R3BCQ205MlRPUXF1N3llaUNWMDBtR2U2QnlMa1JuYys1c0hBc2NKa2ZQc1NCb0Z3ZGQySllhTlFNRTR3REFZRFZSMFRBUUgvQkFJd0FEQWRCZ05WSFE0RUZnUVVaUGtCVkRrVWlZSVdMY0c5ci9ZN1dlbkZmYmd3SHdZRFZSMGpCQmd3Rm9BVWg2b3dOQ25yU1BXQzFrTnhxZHhZNllYNkVhVXdDZ1lJS29aSXpqMEVBd0lEWndBd1pBSXdKNWZKdXp1Z0VLL0pZV01wVjVGVGVyY1pYaUFNVGJFZHR0Sk1tVzlaTGdrM3h1L1NwNld6OE9sWS80UmJ3MUhMQWpCM3l4TUQ2R2JlaDU0TW5VWmZYU1ZMWHI5Zyt2NXdPUlRsNEIxV1hVRGszYmhVV1IvZWRoZkdBaVZLYTlGNk5MOD0iXX0.eyJsaWNlbnNlX3BheWxvYWQiOnsidmVyc2lvbiI6MSwic2V0aW5pdCI6IiBQUk9DIFNFVElOSVQgUkVMRUFTRT0nVjA0JzsgIFNJVEVJTkZPIE5BTUU9J1ZJWUEgNCBFWFRFUk5BTCBPUkRFUiBUTyBJTExVU1RSQVRFIEdFTCBFTkFCTEVNRU5UJyAgU0lURT03MDE5ODQyMSBPU05BTUU9J0xJTiBYNjQnIFJFQ1JFQVRFIFdBUk49NTEgR1JBQ0U9NDUgIEJJUlRIREFZPScxMUZFQjIwMjEnRCAgRVhQSVJFPSczMFNFUDIwMjEnRCBQQVNTV09SRD03MzQ1MjkzMTM7ICBDUFUgTU9ERUw9JyAnIE1PRE5VTT0nICcgU0VSSUFMPScgJyBOQU1FPUNQVTAwMDsgIENQVSBNT0RFTD0nICcgTU9ETlVNPScgJyBTRVJJQUw9JyAnIE5BTUU9Q1BVMDAxOyAgQ1BVIE1PREVMPScgJyBNT0ROVU09JyAnIFNFUklBTD0nICcgTkFNRT1DUFUwMDI7ICBFWFBJUkUgJ1BST0ROVU0wMDAnICczMFNFUDIwMjEnRCAvIENQVT1DUFUwMDAgQ1BVMDAxICAgICAgICAgQ1BVMDAyOyAgRVhQSVJFICdQUk9ETlVNMDAxJyAnUFJPRE5VTTAwMicgJ1BST0ROVU0wNTAnICdQUk9ETlVNMDk0JyAgICAgICAgICdQUk9ETlVNMTk0JyAnUFJPRE5VTTU2MScgJ1BST0ROVU01NjQnICdQUk9ETlVNNjc3JyAgICAgICAgICdQUk9ETlVNNjg2JyAnUFJPRE5VTTgyNicgJ1BST0ROVU04MjcnICdQUk9ETlVNOTIxJyAgICAgICAgICdQUk9ETlVNOTUyJyAnUFJPRE5VTTk4NScgJ1BST0ROVU0xMDAwJyAnUFJPRE5VTTEwMDgnICAgICAgICAgJ1BST0ROVU0xMDA5JyAnUFJPRE5VTTEwMTAnICdQUk9ETlVNMTAxMScgJ1BST0ROVU0xMDE0JyAgICAgICAgICdQUk9ETlVNMTAzOCcgJ1BST0ROVU0xMDU1JyAnUFJPRE5VTTEyMDAnICdQUk9ETlVNMTIwNicgICAgICAgICAnUFJPRE5VTTEyMDknICdQUk9ETlVNMTIxMScgJ1BST0ROVU0xMjEyJyAnUFJPRE5VTTEyMTMnICAgICAgICAgJ1BST0ROVU0xMjE5JyAnUFJPRE5VTTEyMjEnICdQUk9ETlVNMTIyOCcgJ1BST0ROVU0xMjMxJyAgICAgICAgICdQUk9ETlVNMTIzOCcgJ1BST0ROVU0xMzA4JyAnUFJPRE5VTTEzMDknICdQUk9ETlVNMTMxMCcgICAgICAgICAnMzBTRVAyMDIxJ0QgLyBDUFU9Q1BVMDAwOyAgRVhQSVJFICdQUk9ETlVNMTE0MScgJzMwU0VQMjAyMSdEIC8gQ1BVPUNQVTAwMTsgIEVYUElSRSAnUFJPRE5VTTExMDAnICdQUk9ETlVNMTEwMScgJ1BST0ROVU0xMTAzJyAnUFJPRE5VTTExMDQnICAgICAgICAgJ1BST0ROVU0xMTA2JyAnUFJPRE5VTTExMDcnICdQUk9ETlVNMTEwOCcgJ1BST0ROVU0xMTA5JyAgICAgICAgICdQUk9ETlVNMTExMCcgJ1BST0ROVU0xMTExJyAnUFJPRE5VTTExMTInICdQUk9ETlVNMTExMycgICAgICAgICAnUFJPRE5VTTExMTUnICdQUk9ETlVNMTExNicgJ1BST0ROVU0xMTE3JyAnUFJPRE5VTTExMTknICAgICAgICAgJ1BST0ROVU0xMTIwJyAnUFJPRE5VTTExMjMnICdQUk9ETlVNMTEyNScgJ1BST0ROVU0xMTI3JyAgICAgICAgICdQUk9ETlVNMTEyOCcgJ1BST0ROVU0xMTI5JyAnUFJPRE5VTTExMzEnICdQUk9ETlVNMTEzMycgICAgICAgICAnUFJPRE5VTTExMzUnICdQUk9ETlVNMTEzNicgJ1BST0ROVU0xMTM4JyAnUFJPRE5VTTExNDAnICAgICAgICAgJ1BST0ROVU0xMTQyJyAnUFJPRE5VTTExNDMnICdQUk9ETlVNMTE0NScgJ1BST0ROVU0xMTQ2JyAgICAgICAgICdQUk9ETlVNMTE0OCcgJ1BST0ROVU0xMTU1JyAnUFJPRE5VTTExNTYnICdQUk9ETlVNMTE1OCcgICAgICAgICAnUFJPRE5VTTExNTknICdQUk9ETlVNMTE2MScgJ1BST0ROVU0xMTYyJyAnUFJPRE5VTTExNjMnICAgICAgICAgJ1BST0ROVU0xMTY1JyAnUFJPRE5VTTExNjYnICdQUk9ETlVNMTE2NycgJ1BST0ROVU0xMTY4JyAgICAgICAgICdQUk9ETlVNMTE4MScgJ1BST0ROVU0xMTgyJyAnUFJPRE5VTTExODMnICdQUk9ETlVNMTE4NCcgICAgICAgICAnUFJPRE5VTTExODYnICdQUk9ETlVNMTE4NycgJ1BST0ROVU0xMTkyJyAnUFJPRE5VTTExOTQnICAgICAgICAgJ1BST0ROVU0xMTk1JyAnUFJPRE5VTTExOTYnICdQUk9ETlVNMTE5NycgJ1BST0ROVU0xMTk4JyAgICAgICAgICdQUk9ETlVNMTE5OScgJ1BST0ROVU0xNTAwJyAnUFJPRE5VTTE1MTgnICdQUk9ETlVNMTUxOScgICAgICAgICAnUFJPRE5VTTE1MjAnICdQUk9ETlVNMTUyMScgJ1BST0ROVU0xNTIyJyAnUFJPRE5VTTE1MjUnICAgICAgICAgJ1BST0ROVU0xNTI2JyAnUFJPRE5VTTE1MjcnICdQUk9ETlVNMTUyOCcgJ1BST0ROVU0xNTI5JyAgICAgICAgICdQUk9ETlVNMTUzNycgJ1BST0ROVU0xNTM4JyAnUFJPRE5VTTE1MzknICdQUk9ETlVNMTU0MCcgICAgICAgICAnUFJPRE5VTTE1NDEnICdQUk9ETlVNMTU0MicgJ1BST0ROVU0xNTQzJyAnUFJPRE5VTTE1NDQnICAgICAgICAgJ1BST0ROVU0xNTQ1JyAnUFJPRE5VTTE1NDcnICdQUk9ETlVNMTU1MCcgJ1BST0ROVU0xNTU1JyAgICAgICAgICczMFNFUDIwMjEnRCAvIENQVT1DUFUwMDI7ICBTQVZFOyBSVU47ICAqUFJPRE5VTTAwMCA9IEJBU0UgQmFzZSBTQVM7ICAqUFJPRE5VTTAwMSA9IFNUQVQgU0FTL1NUQVQ7ICAqUFJPRE5VTTAwMiA9IEdSQVBIIFNBUy9HUkFQSDsgICpQUk9ETlVNMDUwID0gRE1JTkVTT0wgRW50ZXJwcmlzZSBNaW5lciBTZXJ2ZXI7ICAqUFJPRE5VTTA5NCA9IFNFQ1VSRUJOREwgU0FTL1NlY3VyZTsgICpQUk9ETlVNMTAwMCA9IENBUyBDbG91ZCBBbmFseXRpYyBTZXJ2aWNlcyBTQVMgQ2xpZW50OyAgKlBST0ROVU0xMDA4ID0gTUxFQVJOSU5HIE1hY2hpbmUgTGVhcm5pbmcgUHJvY2VkdXJlczsgICpQUk9ETlVNMTAwOSA9IEFOQUxZVElDQ01OIENvbW1vbiBBbmFseXRpY3MgUHJvY2VkdXJlczsgICpQUk9ETlVNMTAxMCA9IEFBU1RBVElTVElDUyBTQVMgQWR2YW5jZWQgQW5hbHl0aWNzIFN0YXRpc3RpY3M7ICAqUFJPRE5VTTEwMTEgPSBURVhUTUlORSBUZXh0IE1pbmluZyBQcm9jZXNzOyAgKlBST0ROVU0xMDE0ID0gRE1NTFZJU1NFVCBTQVMgRGF0YSBNaW5pbmcgYW5kIE1hY2hpbmUgTGVhcm5pbmc7ICAqUFJPRE5VTTEwMzggPSBPUFRJTUlaQVRJT04gU0FTIE9wdGltaXphdGlvbiBQcm9jZWR1cmVzOyAgKlBST0ROVU0xMDU1ID0gRk9SRUNBU1QgRm9yZWNhc3RpbmcgUHJvY2VkdXJlczsgICpQUk9ETlVNMTEwMCA9IENSU0FHR1JFR0FURSBBY3Rpb24gU2V0IGZvciBBZ2dyZWdhdGlvbjsgICpQUk9ETlVNMTEwMSA9IENSU0JBWUVTSUFOIEFjdGlvbiBTZXQgZm9yIEJheWVzaWFuIE5ldHdvcmsgQ2xhc3NpZmllcjsgICpQUk9ETlVNMTEwMyA9IENSU0JPT0xSVUxFIEFjdGlvbiBTZXQgQm9vbGVhbiBSdWxlIEV4dHJhY3Rpb247ICAqUFJPRE5VTTExMDQgPSBDUlNDQVJESU5BTCBBY3Rpb24gU2V0IGZvciBDYXJkaW5hbGl0eTsgICpQUk9ETlVNMTEwNiA9IENSU0RFRVBORVVSTCBBY3Rpb24gU2V0IERlZXAgTmV1cmFsIE5ldHdvcmtzOyAgKlBST0ROVU0xMTA3ID0gQ1JTRFMyIEFjdGlvbiBTZXQgZm9yIERTMjsgICpQUk9ETlVNMTEwOCA9IENSU0RUUkVFIEFjdGlvbiBTZXQgZm9yIERlY2lzaW9uIFRyZWU7ICAqUFJPRE5VTTExMDkgPSBDUlNGRURTUUwgQWN0aW9uIFNldCBmb3IgRkVEU1FMOyAgKlBST0ROVU0xMTEwID0gQ1JTRk9SRUNBU1QgQWN0aW9uIFNldCBmb3IgU2ltcGxlIEZvcmVjYXN0czsgICpQUk9ETlVNMTExMSA9IENSU0tNRUFOUyBBY3Rpb24gU2V0IGZvciBLTWVhbnMgQ2x1c3RlciBBbmFseXRpY3M7ICAqUFJPRE5VTTExMTIgPSBDUlNMT0FEU1RSTVMgQWN0aW9uIFNldCBmb3IgU3RyZWFtaW5nIERhdGE7ICAqUFJPRE5VTTExMTMgPSBDUlNNTFJOSU5HIEFjdGlvbiBTZXQgZm9yIEh5cGVyZ3JvdXBzIGFuZCBHcmFwaCBsYXlvdXQ7ICAqUFJPRE5VTTExMTUgPSBDUlNORVVSQUxORVQgQWN0aW9uIFNldCBmb3IgTmV1cmFsIE5ldHdvcmsgQW5hbHl0aWNzOyAgKlBST0ROVU0xMTE2ID0gQ1JTTkxNIEFjdGlvbiBTZXQgZm9yIE5vbmxpbmVhciBNb2RlbHM7ICAqUFJPRE5VTTExMTcgPSBDUlNPUFRNSU5FUiBBY3Rpb24gU2V0IGZvciBPUFRNSU5FUjsgICpQUk9ETlVNMTExOSA9IENSU1BBUlNFIEFjdGlvbiBTZXQgZm9yIFBhcnNpbmcgYW5kIENhdGVnb3JpemF0aW9uOyAgKlBST0ROVU0xMTIwID0gQ1JTUENBIEFjdGlvbiBTZXQgZm9yIFByaW5jaXBhbCBDb21wb25lbnQgQW5hbHlzaXM7ICAqUFJPRE5VTTExMjMgPSBDUlNSRUdSRVNTTiBBY3Rpb24gU2V0IGZvciBSZWdyZXNzaW9uIE1vZGVsaW5nOyAgKlBST0ROVU0xMTI1ID0gQ1JTU0FNUExJTkcgQWN0aW9uIFNldCBmb3IgU2FtcGxpbmc7ICAqUFJPRE5VTTExMjcgPSBDUlNTRUFSQ0ggQWN0aW9uIFNldCBmb3IgU2VhcmNoOyAgKlBST0ROVU0xMTI4ID0gQ1JTU0VOVElNRU5UIEFjdGlvbiBTZXQgZm9yIFNlbnRpbWVudCBBbmFseXNpczsgICpQUk9ETlVNMTEyOSA9IENSU1NFUVVFTkNFIEFjdGlvbiBTZXQgZm9yIFNlcXVlbmNlOyAgKlBST0ROVU0xMTMxID0gQ1JTU1RBVCBBY3Rpb24gU2V0IGZvciBDb21tb24gQ29kZTsgICpQUk9ETlVNMTEzMyA9IENSU1NWTSBBY3Rpb24gU2V0IGZvciBTdXBwb3J0IFZlY3RvciBNYWNoaW5lOyAgKlBST0ROVU0xMTM1ID0gQ1JTVEtGQUNUTUFDIEFjdGlvbiBTZXQgdG8gaW1wbGVtZW50IEZhY3Rvcml6YXRpb247ICAqUFJPRE5VTTExMzYgPSBDUlNUUkFOU1BPU0UgQWN0aW9uIFNldCBmb3IgVHJhbnNwb3NlOyAgKlBST0ROVU0xMTM4ID0gQ1JTVFhUTUlOSU5HIEFjdGlvbiBTZXQgZm9yIFRleHQgTWluaW5nOyAgKlBST0ROVU0xMTQwID0gQ1JTVkFSUkVEVUNFIEFjdGlvbiBTZXQgZm9yIFZhcmlhYmxlIFJlZHVjZTsgICpQUk9ETlVNMTE0MSA9IFRLQ0FTIFNBUyBDbG91ZCBBbmFseXRpYyBTZXJ2aWNlcyBTZXJ2ZXI7ICAqUFJPRE5VTTExNDIgPSBDUlNSRUNPTU1FTkQgQWN0aW9uIFNldCBmb3IgUmVjb21tZW5kZXI7ICAqUFJPRE5VTTExNDMgPSBDUlNNVFBTUlZDIEFjdGlvbiBTZXQgZm9yIE1pZHRpZXIgU2VydmljZXM7ICAqUFJPRE5VTTExNDUgPSBDUlNORVRTT0MgQWN0aW9uIFNldCBmb3IgU29jaWFsIE5ldHdvcmsgQW5hbHlzaXM7ICAqUFJPRE5VTTExNDYgPSBDUlNORVRDT01NT04gQWN0aW9uIFNldCBmb3IgTmV0d29yayBDb21tb247ICAqUFJPRE5VTTExNDggPSBDUlNEUExSTklORyBBY3Rpb24gU2V0IERlZXAgTGVhcm5pbmc7ICAqUFJPRE5VTTExNTUgPSBDUlNBU1RPUkUgQWN0aW9uIFNldCBBU1RPUkUgU2NvcmluZzsgICpQUk9ETlVNMTE1NiA9IENSU0NNUFRSVlNOIENBUyBBY3Rpb24gU2V0IENvbXB1dGVyIFZpc2lvbjsgICpQUk9ETlVNMTE1OCA9IENSU01PREVMUFVCIEFjdGlvbiBTZXQgTW9kZWwgUHVibGlzaGluZzsgICpQUk9ETlVNMTE1OSA9IENSU1NHQ09NUCBBY3Rpb24gU2V0IGZvciBTdGF0aXN0aWNhbCBHcmFwaGljcyBDb21wdXRhdDsgICpQUk9ETlVNMTE2MSA9IENSU0RUUkVFQURWTiBBY3Rpb25TZXQgRGVjaXNpb24gVHJlZSBBZHY7ICAqUFJPRE5VTTExNjIgPSBDUlNQQVJTRUFEViBDQVMgQWN0aW9uIFNldCBQYXJzaW5nIEFkdjsgICpQUk9ETlVNMTE2MyA9IENSU1RYVE1JTkFEViBDQVMgQWN0aW9uIFNldCBUeHQgTWluaW5nIEFkdjsgICpQUk9ETlVNMTE2NSA9IENSU0ZBU1RLTk4gQWN0aW9uIFNldCBOZWFyZXN0IE5laWdoYm9yOyAgKlBST0ROVU0xMTY2ID0gQ1JTR1ZBUkNMVVMgQWN0aW9uIFNldCBWYXJpYWJsZSBDbHVzdGVyOyAgKlBST0ROVU0xMTY3ID0gQ1JTUlVMRU1JTkUgQ0FTIEFjdGlvbiBTZXQgUnVsZSBNaW5pbmc7ICAqUFJPRE5VTTExNjggPSBDUlNTU0xFQVJOIENBUyBBY3Rpb24gU2V0IFNlbWlTdXBlciBMZWFybjsgICpQUk9ETlVNMTE4MSA9IENSU1NWREQgQWN0aW9uIFNldCBmb3IgU3VwcG9ydCBWZWN0b3IgRGF0YSBEZXNjcmlwdGlvbjsgICpQUk9ETlVNMTE4MiA9IENSU1JQQ0EgQWN0aW9uIFNldCBmb3IgUm9idXN0IFByaW5jaXBsZSBDb21wb25lbnQgQW5hbDsgICpQUk9ETlVNMTE4MyA9IENSU1BMUyBBY3Rpb24gU2V0IGZvciBQYXJ0aWFsIExlYXN0IFNxdWFyZXMgUmVncmVzc2lvbjsgICpQUk9ETlVNMTE4NCA9IENSU1FVQU5UUkVHIEFjdGlvbiBTZXQgZm9yIFF1YW50aWxlIFJlZ3Jlc3Npb24gTW9kZWxpbjsgICpQUk9ETlVNMTE4NiA9IENSU0ZDTVBBQ1QgQWN0aW9uIFNldCBmb3IgQ29tcGlsZXIgYW5kIFN5bWJvbGljIERpZmZlcjsgICpQUk9ETlVNMTE4NyA9IENSU0RFRVBSTk4gQWN0aW9uIFNldCBEZWVwUmVjdXIgTmV1ck5ldDsgICpQUk9ETlVNMTE5MiA9IENSU1JNViBBY3Rpb24gU2V0IGZvciBSb2J1c3QgTXVsdGl2YXJpYXRlIE91dGxpZXIgRGV0ZTsgICpQUk9ETlVNMTE5NCA9IENSU0NPUlIgQWN0aW9uIFNldCBmb3IgQ29ycmVsYXRpb24gQW5hbHlzaXM7ICAqUFJPRE5VTTExOTUgPSBDUlNGUkVRIEFjdGlvbiBTZXQgZm9yIEZyZXF1ZW5jeSBhbmQgQ3Jvc3N0YWJ1bGF0aW9uIEE7ICAqUFJPRE5VTTExOTYgPSBDUlNHQU1QTCBBY3Rpb24gU2V0IGZvciBHZW5lcmFsaXplZCBBZGRpdGl2ZSBNb2RlbGluZzsgICpQUk9ETlVNMTE5NyA9IENSU01JWEVEIENBUyBBY3Rpb24gU2V0IE1peGVkOyAgKlBST0ROVU0xMTk4ID0gQ1JTUEhSRUcgQWN0aW9uIFNldCBmb3IgUHJvcG9ydGlvbmFsIEhhemFyZHMgTW9kZWxpbmc7ICAqUFJPRE5VTTExOTkgPSBDUlNTQU5EV0lDSCBBY3Rpb24gU2V0IFNhbmR3aWNoOyAgKlBST0ROVU0xMjAwID0gQ0RGQkFTRSBEYXRhIENvbm5lY3RvciBTQVMgRGF0YSBTZXRzOyAgKlBST0ROVU0xMjA2ID0gQ0RGSElWRSBTQVMgRGF0YSBDb25uZWN0b3IgdG8gSGFkb29wOyAgKlBST0ROVU0xMjA5ID0gQ0RGT1JDTCBEYXRhIENvbm5lY3RvciB0byBPcmFjbGU7ICAqUFJPRE5VTTEyMTEgPSBDREZQU1RHIERhdGEgQ29ubmVjdG9yIHRvIFBvc3RncmVTUUw7ICAqUFJPRE5VTTEyMTIgPSBUS0NERkNPTU1PTiBTQVMgRGF0YSBDb25uZWN0IEVtYmVkZGVkIFByb2Nlc3MgU3dpdGNoOyAgKlBST0ROVU0xMjEzID0gVEtDREZUUyBDb21tb24gVEsgRXh0ZW5zaW9ucyBmb3IgQ0FTIERhdGEgRmVlZGVyczsgICpQUk9ETlVNMTIxOSA9IFRLT1JBQ0xFIFNBUyBUSyBFeHQgZm9yIE9yYWNsZTsgICpQUk9ETlVNMTIyMSA9IFRLSEFET09QSElWRSBTQVMgVEsgRXh0IGZvciBIYWRvb3AgSGl2ZTsgICpQUk9ETlVNMTIyOCA9IFRLUE9TVEdSRVMgU0FTIFRLIEV4dCBmb3IgUG9zdGdyZVNRTDsgICpQUk9ETlVNMTIzMSA9IENERldFQiBXRUIgTWVkaWEgRGF0YSBGZWVkZXI7ICAqUFJPRE5VTTEyMzggPSBDREZTUERFIERhdGEgQ29ubmVjdG9yIHRvIFNQREU7ICAqUFJPRE5VTTEzMDggPSBCSUdRVUVSWU9SRCBTQVMvQUNDRVNTIHRvIEdvb2dsZSBCaWdRdWVyeTsgICpQUk9ETlVNMTMwOSA9IFRLQklHUVVFUlkgVEsgRXh0IGZvciBHb29nbGUgQmlnUXVlcnk7ICAqUFJPRE5VTTEzMTAgPSBDREZCSUdRVUVSWSBEYXRhIENvbm5lY3RvciB0byBHb29nbGUgQmlnUXVlcnk7ICAqUFJPRE5VTTE1MDAgPSBDUlNTUEMgQWN0aW9uIFNldCBmb3IgU3RhdGlzdGljYWwgUHJvY2VzcyBDb250cm9sOyAgKlBST0ROVU0xNTE4ID0gQ1JTQklPTUVESU1HIEFjdGlvbiBTZXQgQmlvbWVkIEltZyBQcmNzOyAgKlBST0ROVU0xNTE5ID0gQ1JTUFNFVURPIENBUyBBY3Rpb24gU2V0IFBTRVVETyBMb2NhbDsgICpQUk9ETlVNMTUyMCA9IENSU01CQyBDQVMgQWN0aW9uIFNldCBNZGwtQmFzZWQgQ2x1c3RyOyAgKlBST0ROVU0xNTIxID0gQ1JTQVVESU8gQ0FTIEFjdGlvbiBTZXQgZm9yIEF1ZGlvOyAgKlBST0ROVU0xNTIyID0gQ1JTU1BDSDJUWFQgQ0FTIEFjdGlvbiBTZXQgZm9yIFNwZWVjaCB0byBUZXh0OyAgKlBST0ROVU0xNTI1ID0gQ1JTSUNBIENBUyBBY3Rpb24gU2V0IEluZC4gQ21wbnQgQW5seXM7ICAqUFJPRE5VTTE1MjYgPSBDUlNUU05FIENBUyBBY3Rpb24gU2V0IGZvciB0U05FOyAgKlBST0ROVU0xNTI3ID0gQ1JTTVRMRUFSTiBDQVMgQWN0aW9uIFNldCBNdWx0aS10YXNrIExlYXJuOyAgKlBST0ROVU0xNTI4ID0gQ1JTUFJPQk1MIENBUyBBY3Rpb24gU2V0IGZvciBwcm9iTUw7ICAqUFJPRE5VTTE1MjkgPSBDUlNNTFRPT0xTIENBUyBBY3Rpb24gU2V0IE1hY2ggTHJuaW5nIFRvb2w7ICAqUFJPRE5VTTE1MzcgPSBDUlNEU1BJTE9UIEFjdGlvbiBTZXQgZm9yIEF1dG9tYXRlZCBNYWNoaW5lIExlYXJuaW5nOyAgKlBST0ROVU0xNTM4ID0gQ1JTRVhQQUkgQWN0aW9uIFNldCBmb3IgQ29tcG9zaXRlIEludGVycHJldGFiaWxpdHk7ICAqUFJPRE5VTTE1MzkgPSBDUlNFWFBNT0RFTCBBY3Rpb24gU2V0IGZvciBNb2RlbCBJbnRlcnByZXRhYmlsaXR5OyAgKlBST0ROVU0xNTQwID0gQ1JTU1BBUlNFTUwgQWN0aW9uIFNldCBmb3IgTWFjaGluZSBMZWFybmluZyBmb3IgU3BhcnNlOyAgKlBST0ROVU0xNTQxID0gQ1JTRFBMUk5TQlNUIFN1YnNldCBvZiBBY3Rpb24gU2V0IGZvciBEZWVwIExlYXJuaW5nOyAgKlBST0ROVU0xNTQyID0gQ1JTTk1GIEFjdGlvbiBTZXQgZm9yIENSU05NRjsgICpQUk9ETlVNMTU0MyA9IENSU1NJTVNZUyBBY3Rpb24gU2V0IGZvciBDUlNTSU1TWVM7ICAqUFJPRE5VTTE1NDQgPSBDUlNLRVJORUxQQ0EgQWN0aW9uIFNldCBLZXJuZWxQQ0E7ICAqUFJPRE5VTTE1NDUgPSBDUlNBQ1RJVkVMUk4gQWN0aW9uIFNldCBmb3IgQWN0aXZlIE1hY2hpbmUgTGVhcm5pbmc7ICAqUFJPRE5VTTE1NDcgPSBDUlNSRUlOTEVBUk4gQWN0aW9uIFNldCBSZWluZm9yY2VtZW50IExlYXJuaW5nOyAgKlBST0ROVU0xNTUwID0gQ1JTREVEVVAgQWN0aW9uIFNldCBmb3IgRGVkdXBsaWNhdGlvbjsgICpQUk9ETlVNMTU1NSA9IENSU1RFWFRNQU5BR0VNRU5UIEFjdGlvbiBTZXQgZm9yIFRleHQgTWFuYWdlbWVudDsgICpQUk9ETlVNMTk0ID0gT1JBQ0xFQk5ETCBTQVMvQUNDRVNTIHRvIE9SQUNMRTsgICpQUk9ETlVNNTYxID0gSEFET09QQk5ETCBTQVMvQUNDRVNTIHRvIEhhZG9vcDsgICpQUk9ETlVNNTY0ID0gUE9TVEdSRVNCTkRMIFNBUy9BQ0NFU1MgdG8gUG9zdGdyZVNRTDsgICpQUk9ETlVNNjc3ID0gSFBTIFNBUyBIaWdoLVBlcmZvcm1hbmNlIFNlcnZlcjsgICpQUk9ETlVNNjg2ID0gSFBTVEFUIFNBUyBIaWdoLVBlcmZvcm1hbmNlIFNUQVQ7ICAqUFJPRE5VTTgyNiA9IEJJQ0VOVFJBTE1JRCBTQVMgSG9tZTsgICpQUk9ETlVNODI3ID0gQklTUlZNSUQgU0FTIFZpc3VhbCBBbmFseXRpY3MgU2VydmljZXM7ICAqUFJPRE5VTTkyMSA9IEJJTVZBIFNBUyBWaXN1YWwgQW5hbHl0aWNzIFNlcnZlciBDb21wb25lbnRzOyAgKlBST0ROVU05NTIgPSBWU09SRCBTQVMgVmlzdWFsIFN0YXRpc3RpY3M7ICAqUFJPRE5VTTk4NSA9IFNBR0VNSUQgU0FTIFZpc3VhbCBBbmFseXRpY3MgRXhwbG9yZXI7ICAqTElDRU5TRT1TQVM7ICAqMDEwMjUwMDAwMSBWMDQuMDA7ICAqWFlaIDg2MzEwMzsgIiwiY2xpZW50Q2VydCI6Ik1JSUd4QUlCQXpDQ0JwQUdDU3FHU0liM0RRRUhBYUNDQm9FRWdnWjlNSUlHZVRDQ0JXY0dDU3FHU0liM0RRRUhCcUNDQlZnd2dnVlVBZ0VBTUlJRlRRWUpLb1pJaHZjTkFRY0JNQndHQ2lxR1NJYjNEUUVNQVFZd0RnUUlPY2Z2MFBuRUxoQUNBZ2dBZ0lJRklIWjBVVzEvT0kyUm42Z2JuNittdHM5d2lXeHh0UHU3M3B3dDlGY1IzV05VMmVRZFFRbG5NN1FVR2ZhdnkzaFAzUkJpbGZjZWladGp1VDNoVHRxTjl3ZEExdHdHZ0NNdjNUY1N5aS9JRERtWDVEbldvdjVWTTF4MjlCSGZUeTIxalZuaFRITkNsVkhLaGx2N1JibXNUbHNpSFVoWTZnMjlydGVjdUVXN3VLVld1eTgvVXFCV08yUE9jUWRPMHFuMUZZcklmMzk5U0pHaTJVQTU3ZTBqeTJkanI3bHNHWVFQOTVaMmp4Vi85bTJqUU5rUGdyMEhtK1pXNWs2eEJTYXQ1RnhzNUxsQi83Mmo5REcxanhQMWhtcW9DaUliY1U1TUxLK1V4TE5ETlJVS0FrN09FVTdVVVpGYVB3QXZxTGtHVGdpM1NUNDlhbTJBZ09nUjNWR0x1RVdqc0Y2VFJNeDZQU3daN1dTZS9vQ0xLWXJwczBiS3RoRW9yRWFKR3ZiVElwZzI2VW91OUVZa0tHMitDUDRJVm9laTlld0FlWmhuNlpMemtaN1lQVnBYTFgxUnZFbVY5RWpBaFlXUDdXejNiUEcrWCtFTVRNWTRGZ0Y2SlY4QkRUQzFLUWxMVHlmb2xuQllsRkJ0U1ZGVjVpTHl5RHAyVE9veGZCWGFUSnFGUUJuMktSNjQyUXlyNDBLcHkyNSs0aUVERVlnYmVmaXZOQnlKUzdzcVlJR1ROT0QrczBidFVPRWJ6WFNTTGRoNUZ3bGZZdmpFWGVFL3FQaU1jYmk0OVE4dEJOZDhGNkZsV3FtTEQzc2NKWXdGb0V6VE4wbnVvWDJMV1hoNGcrcVdZRjdVNzVQSjNnQmdRSURQcGx2YUs3TEtET2ZGNEx3V2I2NVN2MEhhRjEzVnpLUkpDSk5CQ3RBWUtDR1hQTkl4SWJ6STZ0aHIvMkpaTG5hN1FCMWJzWEVLQkdGNDVZRENwcE8rY2dxM1FKcWJtK2lhaThzTVVGUW5sdHYrSE1rWVlUbmZBMnNrV1FLV2ZHQVlkNlU5ZDlmdE9FZ1Jwekk5dThwMCtFVHQwMWVYNVhTUCt1YmlaelAzcWtyZm50OHpQN0FXWE8vYmNESWNYV1AwZEZKdmZYMy93ZnVrRU0vSW9BejJ4R0xTWXd5SXFZbjllMlU5NEFQTi9kcWp2RTlIR0hDVDVaTEJmcTNGc09INC8wMWRiZ241blJkUDhHZXZSL2JVVzljVnduZks0NFpLVkN1dGJDZnVRVWxhbDVoWGkwaG5ua3pVdmpEaVFQWFpUYmxSOS9Ua1pXTmRETkJiOEJvNkJWV0Fqc29WRjlCQlAwb1NMeTNIRkgvaWliUURJckljZWdvZHRNcFkrYWpyOENFbStESnVzUHhHTHE5LzB4ZlVpRVNrR0Y3K3ZuMnRwY0pNeUZ5WGwwMHpFTjVrY0tPL3FlV01mNmVxazhlUHN3aG12NXdlamFvdzgxZTRRNDg5dnFwM0NTN01Eb3p1ZnM2eWtrRTNFVWxCb1NySzRrVGZDcFJnMGx2UWFjcUxOWnFraVNrNmt6dlpiZmtHeGcvRjBFVHRyQld3WUhvMXFwRGJ4enRzWDZRcE4wWTVxKzFSNjdCMFNiV3N0SU9XZjVQVHZMOTR4blptdm1vR0NWK2h2ZUc3T0tyZXBndjZUa1ZIaE5UbGgrK1VXeTlucUljbjIzY09VVGVoVk81U0ZZQnM4OE1QcFNsa1c5NzVRd0Z3amVEcU5rdkI5bmNOYk8rMzhROEZIY1duVkFwcFFWMmN6Y3Mya0NaN2F2OWdjaW5MR3MzNzFrSThzVHQvTlVQTkdPanB1MDZyUHhqK1dEQjFNTDliL2NvQkpCcE9zM2NFTXFKSjlScmZOdXoydys0MGg0bkZMMmRZdVRsTVhZZGV0TmR5WmpVaTE4TnRVUks2cG5jSGdpcm0yTXQ1Vjgzd2F2eFhxYTdTUUY4R1ZkeUxCVmpwTk1XZTI2K2IwaEhrMDhGcGFidEVhaTFTbGpuellRVTFETG93Z1l5Y2s3TGQ2UXplczk3c0lxamVEZzdsdjNENVJYek55N29mNFFKVDk3YnJhYUNNRWpBQ2VNM0t2Ym5qSFJSUExLQnBkN1NhMThGSk5MV1lLb3RGWG1GZ2E1OWlzVld5M3FhcjVMdEFiUTRIc0ZSQXVYeTVUZTF6Um1wcGpOZndOOC9PdG5UWmo0NU5PVm5ZUGhJY0pSUkpoS3hjMUZ5ekprcEY1S1pqZmVFTUNNYllLazd0bFZqTis3TmNQK3dYbVpyNWNPMThjRmdXZno4cmpVekJvYlpFSTFrd2dnRUtCZ2txaGtpRzl3MEJCd0dnZ2Z3RWdma3dnZll3Z2ZNR0N5cUdTSWIzRFFFTUNnRUNvSUc4TUlHNU1Cd0dDaXFHU0liM0RRRU1BUU13RGdRSUtKOC9ZbVZLQlhnQ0FnZ0FCSUdZb1F5UEllZFRXNkNNTklxZVdRNVVpbHV3bmVsL2hvZ3BndXp6NFdZeVYvcHIwREprV1d4MUI2WVpnMWhEWHpNVDJvdnhaMFdQVHFyYXVsNEVidWxyRXZDWEZ6SGRqSjBNY2RzUFR5ZDJ5VVZyQVJ6UjEyWnBTZ0ZJOHROKzJzZlNpUVIxeTBwaDZqWVhvOWpDNkl1ZnRqU2VxVHdnMk8xYis0akMyME1TSUFvbnJzamdVVXJ1YnVqRzhYeW1zbWlZTXJwTFBEY2hXMDB4SlRBakJna3Foa2lHOXcwQkNSVXhGZ1FVbExvTlFGOGp6TzRDODZLWUN2QTIwMzNJMHo0d0t6QWZNQWNHQlNzT0F3SWFCQlN0Z0hZK2hvb2dOY1c2MldWMlY4clppb1hMRGdRSVBxLzJLVmhPVmV3PSIsImZyYW1ld29ya0NvbnRyYWN0IjoiIn19.8fbo4XEzbqkZKdV40xuNwtL1EBehcgUoY4OnS4MDnCPV6rhDidHfpTWUjR4kuOXCtbW2BKOJUPDY8Gd9xBImRg
     certificate: |
       -----BEGIN RSA PRIVATE KEY-----
       MIIEpAIBAAKCAQEA6WvxCE7hV92nyGH+rOX5sGR6+S2SXL5FTddtMxhJ8PttAi4Y
       kwzfSxweru7okDY08chczB/syM7QWHT8FIKvnZZSwU8JWiV9J8zCH89O/DN8Es73
       jYt9Smg8V6PPQ22z+5mWH0sMf1QVM81YqhMKL025pp1CONG3OKY12zXMksh/10Nw
       3wuOYFDJ+xz/D4NR6BSq6OjnjvATzSvR/xC9Qstn1SKu7gpijGDeh1tP+BEPVQ8L
       nzYig4btuH2k/BD0NkuLE1clxYIH+bJfyxACnfX2iO7vc7T7Zb+y7zH+eR+8gse0
       PrKl1pfgsrJ6sxud7zvFQyQEJI3dMnd4+55EJwIDAQABAoIBAQCJDafoiOgm/y6U
       qXUvb5i7yUOrKubVLaLjoamsZoaDyBypOweSz+wL3ebmL8C9bBaKIGrcL6KIBWav
       iYC5SkJy9OCCQDXtiDWEOOWCZ+aojlI7eOpBYbWfCrTjgHshzDfxcqyCkz4zRNtu
       HxQASE2imLB487z+P6SkznKw01XamF+vzWtDPW/xJ89USx5fhkORRjIg0srZ5Dsn
       56JVp0XA0+803f63ZoG7j5nSpuSGutZ18UrEvElGgdX7rBefZBhBpjWhkufGQi+o
       ml0YX1WyWvvWKOGn2tEN+2lblUH3UNm4P/IduSq1vuEWJZAfnRmqiaP45JSFgcJ0
       OjIGf7GBAoGBAOsWpWdJZOqYu3ILBG9ul79xej205+84rbQXS58hxuqlgYq1xX17
       NW2+6ZrOVLsSJCM+SGWXE1CXSLcw+305KntcuFmsEbbKuzmuwY4vNMLUiOGBtVjf
       Jbx1OtmUrnoNASsnHMZdfR3xI3OsJMxWZQvkped78qahAkOSf2MOF+99AoGBAP4v
       VtvPEsRBMsW1YBMEalPS03VaSo1hwuz9EaCgjQUfMXzWd8fRvvfE8QBvQS9dkuN2
       NJn2odJvvCkiQ/g146dT/y+mBFVfMb5cVLuOd9esJjOtP2QDmuVBHwnzzbnGJy7W
       A9kjcv/5MJM0tM+lHTpi6aX77r97hSkSoe4c4ZtzAoGBAKDPZumWXP/U5jQGsUwA
       XLFKUJIxU45iOQA+By6djlIoUMqvuJ4zT8L4mxeYGIG20R2Cl0dW5pF0Svt0+DMa
       jaLBNCGzAJMHbrbwgdpfFDpJ5DBN590ZF9koX89CU2+NwcThBl/yx4lZ0CRqFuno
       F0rhZ1NHiB7PeJr8dUMu+tSJAoGAfXki2Eiky+ofRQdekKSqVAyLQ6+5g4cRsOjP
       rcnzMucOB8DayfGY4jf+e6dvtxDq9IuiNapQgU+Uw31drgX0BeJp4ryCAR6HsJ9l
       WFxgfj9FcFcCJr281ZRK3R/TmvPc3brZlXNxTjhVKSVoZ+PqxKqVCdGOLkmsFvVS
       p/bry08CgYAkRcSmEfvB2XVtlMSVqG+8NCF/OlQ/PPws+tIxWXo6F2LMvLTeoaWw
       24ydutBLmRj3sMRcaFDd/r9q+L1KmLn3H6YkOvCeFdxpdqL1IMn3J35rSxbyuCiY
       o0DA7Rm6Uy99gpo6kXA9pfzFe9xwp/bocQvYYN/4QZ49MZwUkyvFLg==
       -----END RSA PRIVATE KEY-----
       -----BEGIN CERTIFICATE-----
       MIIDrTCCApWgAwIBAgIIKCb55Wc23IkwDQYJKoZIhvcNAQELBQAwgagxHDAaBgNV
       BAoME1NBUyBJbnN0aXR1dGUsIEluYy4xHDAaBgNVBAsME1JlbGVhc2UgRW5naW5l
       ZXJpbmcxODA2BgNVBAMML0NlcnRpZmljYXRlIEF1dGhvcml0eSBmb3IgQ2xpZW50
       IEF1dGhlbnRpY2F0aW9uMTAwLgYJKoZIhvcNAQkBFiFTb2Z0d2FyZVByb2R1Y3Rp
       b25TeXN0ZW1zQHNhcy5jb20wHhcNMjAwOTI0MDAwMDAwWhcNMzAwOTI1MDAwMDAw
       WjBBMQswCQYDVQQGEwJVUzEbMBkGA1UEChMSU0FTIEluc3RpdHV0ZSBJbmMuMRUw
       EwYDVQQDEwxzYXMuZG93bmxvYWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
       AoIBAQDpa/EITuFX3afIYf6s5fmwZHr5LZJcvkVN120zGEnw+20CLhiTDN9LHB6u
       7uiQNjTxyFzMH+zIztBYdPwUgq+dllLBTwlaJX0nzMIfz078M3wSzveNi31KaDxX
       o89DbbP7mZYfSwx/VBUzzViqEwovTbmmnUI40bc4pjXbNcySyH/XQ3DfC45gUMn7
       HP8Pg1HoFKro6OeO8BPNK9H/EL1Cy2fVIq7uCmKMYN6HW0/4EQ9VDwufNiKDhu24
       faT8EPQ2S4sTVyXFggf5sl/LEAKd9faI7u9ztPtlv7LvMf55H7yCx7Q+sqXWl+Cy
       snqzG53vO8VDJAQkjd0yd3j7nkQnAgMBAAGjQTA/MA4GA1UdDwEB/wQEAwIHgDAM
       BgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFE/3c5oPytpLpJ7mk9rM0VDRRgE7MA0G
       CSqGSIb3DQEBCwUAA4IBAQBIvFNT+V6OqkRA+UOQL7ULDy7SN5DPPmk81oaRClXI
       z6/bBwWRvrRN5Kq8kaQS1HugjnQrHS5fCEJRYBSrLPMxci6Dgx41MLPW7HStcweb
       F/oH9MXH6gB5gbVtfeQJ1LZ9OTNxYxmBw5/9kXYaXCw/176gjgltPY+OmHPHRq1b
       6Y2ly+X9puJb+SZN+13XAaU9gyKQGGJvZUyLyWO1kCCQcNTe8WP5wWYlskMMD0Z7
       26kYQS3E7yEJsdPYyXom52bGxDldHoM3dsvqBOY+GUmpSr86nLY3wcNgFC+AyCiG
       XjeqP3nvixa9PIUP/+aDHniWHDRpuTa4AtXmlfPzrDOe
       -----END CERTIFICATE-----
     cacertificate: |
       -----BEGIN CERTIFICATE-----
       MIIGCTCCA/GgAwIBAgINAJBzNrZ92ZFOlwkpDTANBgkqhkiG9w0BAQsFADCBiDEL
       MAkGA1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRD
       YXJ5MRswGQYDVQQKExJTQVMgSW5zdGl0dXRlIEluYy4xHDAaBgNVBAsTE1JlbGVh
       c2UgRW5naW5lZXJpbmcxFjAUBgNVBAMTDVNFUyBSb290IDIwMTgwHhcNMTgwMjI2
       MTczNjQ0WhcNMjgwMjI4MTczNjQ0WjCBiDELMAkGA1UEBhMCVVMxFzAVBgNVBAgT
       Dk5vcnRoIENhcm9saW5hMQ0wCwYDVQQHEwRDYXJ5MRswGQYDVQQKExJTQVMgSW5z
       dGl0dXRlIEluYy4xHDAaBgNVBAsTE1JlbGVhc2UgRW5naW5lZXJpbmcxFjAUBgNV
       BAMTDVNFUyBSb290IDIwMTgwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
       AQCnKTvK1LBNHaZAeWgkCIofAvdz8q/MVewUyrYToKxvFNvr7c9Xx8+P4t2Zal7c
       VCxwun+x/Wt1T+bhaAmTFn9rI0xuobbpZPDvztaf8AlohsVSByNatPq8igm83iID
       EMQkxByIwpKTJAPMCYIHKfFulJRkGWXMyoxIWgRq+8Mmapg1O/4E6M5nNgBGEAxA
       tBpsFLeJG/mn3c5o6d8gx4VXEb7t3gD3mZUNhIkyF9eyLoEx8WKIfAUOBJfkOc/9
       RS0TIFsOwftjQ2ilnR0NKLR/lCX+mMhMJMYY5cOw+Y+2X5w7iTs4PbhSHi9T3U/V
       4sZurjJvuChRMTX2WBRGZLYNf2qeOtgBKblGaBO455Iboy1DbDVGR7v+YsqDpjiD
       xvCLtkl2TMWqvIsMj4uP4/9Wz+WoWTDDaI6LpOw9UFgvzcifFHR34RF8Fr3uo5B0
       WhQxFRcqD7uLNtu2XDpSlAptG47kU9ja7ZBK0Qc8YCHo4NduaPoOj1Ffdxk1ayMU
       CRSx6HwVPuXphL/A6Hi/ucX4D1LYEiS8DVF053zJ704TgHISfdnDjBEwEp6cZIkW
       BvoMuHaU8Lhl/inRwaFqxLEITgrtIcODAIwvdtsFJIcu+/ugaxzAAVSdoB14VAYY
       PsbwzW/+iFt0/EXk+ysaK2HXxu6UrEhoDJMKDa1PhHiPhQIDAQABo3AwbjAOBgNV
       HQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUmYRS2G/8YjwQ
       7cVtxpKZ1UHk0aowLAYDVR0RBCUwI4EhU29mdHdhcmVQcm9kdWN0aW9uU3lzdGVt
       c0BzYXMuY29tMA0GCSqGSIb3DQEBCwUAA4ICAQA7Z84uZVLuI7j/UE0omM6+Zaji
       xzr/e49c7S7J+zfFcUsUYpTvqa/N/ksrssKWntJUpZ/VT0fDGBN9TlDKDdPRUdCe
       bOszKLAGZn7e40HihtoyQdlzXIUvRXw8QSaJtnXNWwWaY0kUYgiH2oQn74AL7Rnu
       WFOirHZdqCo7RIGPIjL7D85NEke01/MW4WjHiwuR0s+euHdGABfNVkGCLNqPhYV9
       gevFDu1DdkcgdzIEZxIUV7HFi0Y8MK2veCtUGzJf1yIdEv1/nSOJ4UxPEf6c06on
       lHvIU6h5SHM7VpKB6X9IxrZweF2tjxhL9Ed3dY0Tqe5POzupNcQMA/v21uEutMco
       3IF8Y5dPzqXmHCTPFmGSfPu04fai6oG1zJvcmngBtwVDEIUFyRIC5Ws/0YlxkJBI
       WuVwvm0hCmcl80BMkLyGpADyRBqZNGpg6InkJZgB7xMt+YHPP+V09HVAOQOOSpme
       j++eaXRpvc227fKeyQJ7JEp1C7rbpFMKgbi+B5VnkUbsE1KqXYkjEhGo77aNsEG+
       MZNn1tqgGdFQlZ1wgh4lZOCl/FZDVyAEe6wrzAmT9eISbfE2vWxHAawaGuER2WDk
       wIzUm55s5b5QpSHOUSgVPXyjy57Qf5uYj8jttZMm37xJJZDAGu458VM4Awr3U5RT
       NiNQhLrdNnInhFySNA==
       -----END CERTIFICATE-----
   EOF
   ```

This is the information from the license zip file that you can download from the my.sas.com portal. For example, the `SASViyaV4_9CFHCQ_certs.zip` file.

### Step 2. Create the Custom Resource file

Now you need to create the Custom Resource definition to describe the Viya deployment. For this let's reuse what you did for the 'lab' deployment (deploying a simple environment).

To recap, in that exercise you created/updated the required input files.  For example:

* sitedefault.yaml
* custom-config/postgres-custom-config.yaml
* security/cert-manager-provided-ingress-certificate.yaml
* kustomization.yaml

We need the same configuration for the operator to use.

As the name might suggest, the in-line method uses one YAML file to capture all this configuration. Once again, we will deploy the cadence version Stable 2020.1.5.

1. Use the following command to create the deployment Custom Resource definition for your environment.

   ```bash
   INGRESS_SUFFIX=$(hostname -f)
   echo $INGRESS_SUFFIX

   bash -c "cat << EOF > ~/project/operator-driven/inline-projects/lab/lab-inline-deployment.yaml
   apiVersion: orchestration.sas.com/v1alpha1
   kind: SASDeployment
   metadata:
     name: lab-inline-sasdeployment
   spec:
     cadenceName: \"stable\"
     cadenceVersion: \"2020.1.5\"
     cadenceRelease: \"\"
     # The following is an example of how to specify inline user content.
     # See documentation for specifying license, client certificate,
     # and certificate authority certificate.
     userContent:
       files:
         \"kustomization.yaml\": |-
           ---
           namespace: lab
           resources:
             - sas-bases/base
             - sas-bases/overlays/cert-manager-issuer     # TLS
             - sas-bases/overlays/network/ingress
             - sas-bases/overlays/network/ingress/security   # TLS
             - sas-bases/overlays/internal-postgres
             - sas-bases/overlays/crunchydata
             - sas-bases/overlays/cas-server
             - sas-bases/overlays/update-checker       # added update checker
             - sas-bases/overlays/cas-server/auto-resources    # CAS-related
           configurations:
             - sas-bases/overlays/required/kustomizeconfig.yaml  # required for 0.6
           transformers:
             - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
             - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
             - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
             - sas-bases/overlays/required/transformers.yaml
             - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
             - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
             - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
           #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
           #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
           configMapGenerator:
             - name: ingress-input
               behavior: merge
               literals:
                 - INGRESS_HOST=lab.${INGRESS_SUFFIX}
             - name: sas-shared-config
               behavior: merge
               literals:
                 - SAS_SERVICES_URL=https://lab.${INGRESS_SUFFIX}
             - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
               behavior: merge
               files:
                 - SITEDEFAULT_CONF=sitedefault.yaml
             # # This is to fix an issue that only appears in RACE Exnet.
             # # Do not do this at a customer site
             - name: sas-go-config
               behavior: merge
               literals:
                 - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='5m'
           generators:
             - postgres-custom-config.yaml
         \"sitedefault.yaml\": |-
           ---
           config:
             application:
               sas.logon.initial:
                 user: sasboot
                 password: lnxsas
         \"postgres-custom-config.yaml\": |-
           ---
           apiVersion: builtin
           kind: ConfigMapGenerator
           metadata:
             name: postgresql-custom
           behavior: merge
           literals:
           - |
             postgres-ha.yaml=
             ---
             bootstrap:
               dcs:
                 loop_wait: 10                                      # Added through SAS provided kustomize configMapGenerator
                 ttl: 30                                            # Added through SAS provided kustomize configMapGenerator
                 master_start_timeout: 0                            # Added through SAS provided kustomize configMapGenerator
                 postgresql:
                   parameters:
                     archive_timeout: 60                            # Added through SAS provided kustomize configMapGenerator
                     checkpoint_completion_target: 0.9              # Added through SAS provided kustomize configMapGenerator
                     effective_cache_size: 4GB                      # Added through SAS provided kustomize configMapGenerator
                     hot_standby: on                                # Added through SAS provided kustomize configMapGenerator
                     log_filename: 'postgresql_%Y%m%d%H%M%S.log'    # Added through SAS provided kustomize configMapGenerator
                     log_line_prefix: '%m'                          # Added through SAS provided kustomize configMapGenerator
                     log_min_duration_statement: -1                 # Added through SAS provided kustomize configMapGenerator
                     log_statement: 'none'                          # Added through SAS provided kustomize configMapGenerator
                     log_truncate_on_rotation: on                   # Added through SAS provided kustomize configMapGenerator
                     logging_collector: on                          # Added through SAS provided kustomize configMapGenerator
                     maintenance_work_mem: 128MB                    # Added through SAS provided kustomize configMapGenerator
                     max_connections: 1280                          # Added through SAS provided kustomize configMapGenerator
                     max_prepared_transactions: 1280                # Added through SAS provided kustomize configMapGenerator
                     max_wal_senders: 8                             # Added through SAS provided kustomize configMapGenerator
                     max_wal_size: 2GB                              # Added through SAS provided kustomize configMapGenerator
                     min_wal_size: 80MB                             # Added through SAS provided kustomize configMapGenerator
                     password_encryption: scram-sha-256 # Added through SAS provided kustomize configMapGenerator
                     shared_buffers: 4GB                            # Added through SAS provided kustomize configMapGenerator
                     ssl_ciphers: 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384'     # Added through SAS provided kustomize configMapGenerator
                     ssl_prefer_server_ciphers: on                  # Added through SAS provided kustomize configMapGenerator
                     synchronous_standby_names: ''                  # Added through SAS provided kustomize configMapGenerator
                     wal_buffers: 16MB                              # Added through SAS provided kustomize configMapGenerator
                     wal_keep_segments: 1000                        # Added through SAS provided kustomize configMapGenerator
                     wal_level: hot_standby                         # Added through SAS provided kustomize configMapGenerator
                     wal_log_hints: on                              # Added through SAS provided kustomize configMapGenerator
                     work_mem: 16MB                                 # Added through SAS provided kustomize configMapGenerator
               initdb:
                - encoding: UTF8
                - no-locale
             postgresql:
               pg_hba:
                 - local all postgres peer
                 - local all all trust
                 - local all crunchyadm peer
                 - hostssl replication primaryuser 0.0.0.0/0 scram-sha-256
                 - hostssl all all 127.0.0.1/32 scram-sha-256
                 - hostssl all all 0.0.0.0/0 scram-sha-256
         \"site-config/security/cert-manager-provided-ingress-certificate.yaml\": |-
           ---
           apiVersion: builtin
           kind: PatchTransformer
           metadata:
             name: sas-cert-manager-ingress-annotation-transformer
           patch: |-
             - op: add
               path: /metadata/annotations/cert-manager.io~1issuer
               value: sas-viya-issuer # name of the cert-manager issuer that will supply the Ingress cert, such as sas-viya-issuer
           target:
             kind: Ingress
             name: .*
     license:
       secretKeyRef:
         name: order-secrets
         key: license
     clientCertificate:
       secretKeyRef:
         name: order-secrets
         key: certificate
     caCertificate:
       secretKeyRef:
         name: order-secrets
         key: cacertificate
   EOF"
   ```

If you review the file that has been created you will see the same configuration. But your cadenceVersion will be for 2020.1.5.

![inline-CRD](/06_Deployment_Steps/img/inline.png)

### Step 3. Deploy SAS Viya using the operator
Use the following steps to deploy SAS Viya to the lab namespace.

1. Clean-up and create the namespace.
   ```bash
   kubectl delete ns lab
   kubectl create ns lab
   ```

1. Create the order secrets.
    ```bash
    cd ~/project/operator-driven/inline-projects/lab
    kubectl apply -f order-secrets.yaml -n lab
    ```

    To confirm the configuration you can use the following command: `kubectl describe secret/order-secrets -n lab`

    You should see something similar to the following.

    ```log
    Name:         order-secrets
    Namespace:    lab
    Labels:       <none>
    Annotations:
    Type:         Opaque

    Data
    ====
    cacertificate:  2155 bytes
    certificate:    3013 bytes
    license:        16763 bytes
    ```

1. Deploy SAS Viya

    ```bash
    cd ~/project/operator-driven/inline-projects/lab
    kubectl apply -f lab-inline-deployment.yaml -n lab
    ```

    If you wait a few minutes and list the pods you should see them starting. Use `kubectl -n lab get pods` to see the current status of the pods. Or you can use the 'gel_OKViya4' command to confirm if SAS Viya is ready.

    ```sh
    # Set the namesape to lab
    NS=lab
    time gel_OKViya4 -n ${NS} --wait -ps
    ```

1. Confirm the cadence version that has been deployed using the following command.

    ```sh
    kubectl -n lab get cm -o yaml | grep ' SAS_CADENCE'
    ```

As you can see using the inline configuration is possible, but would very quickly become unworkable for complex deployments.

Finally, if you want to logon to the Viya environment you can use the following to get the URLs.

```sh
NS=lab
DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
EV_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASEnvironmentManager/"
# Write the URLs to the urls.md file
printf "\n" | tee -a ~/urls.md
printf "\n  ************************ $NS URLs ************************" | tee -a ~/urls.md
printf "\n* [Viya Drive ($NS) URL (HTTP**S**)]( ${DRIVE_URL} )" | tee -a ~/urls.md
printf "\n* [Viya Environment Manager ($NS) URL (HTTP**S**)]( ${EV_URL} )\n\n" | tee -a ~/urls.md
```

Remember you will have to use the 'sasboot' user as this environment isn't configured to use GELLDAP.

* Username: sasboot
* Password: lnxsas

---

## Navigation

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [01 Introduction / 01 033 CheatCodes](/01_Introduction/01_033_CheatCodes.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 051 Create your own Viya order](/03_Viya_4_Software_Specifics/03_051_Create_your_own_Viya_order.md)
* [03 Viya 4 Software Specifics / 03 056 Getting the order with the CLI](/03_Viya_4_Software_Specifics/03_056_Getting_the_order_with_the_CLI.md)
* [04 Pre Requisites / 04 081 Pre Requisites automation with Viya4-ARK](/04_Pre-Requisites/04_081_Pre-Requisites_automation_with_Viya4-ARK.md)
* [05 Deployment tools / 05 121 Setup a Windows Client Machine](/05_Deployment_tools/05_121_Setup_a_Windows_Client_Machine.md)
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 081 Deploying a programing only environment](/06_Deployment_Steps/06_081_Deploying_a_programing-only_environment.md)
* [06 Deployment Steps / 06 091 Deployment Operator setup](/06_Deployment_Steps/06_091_Deployment_Operator_setup.md)
* [06 Deployment Steps / 06 093 Using the DO with a Git Repository](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md)
* [06 Deployment Steps / 06 095 Using an inline configuration](/06_Deployment_Steps/06_095_Using_an_inline_configuration.md)**<-- you are here**
* [06 Deployment Steps / 06 097 Using the Orchestration Tool](/06_Deployment_Steps/06_097_Using_the_Orchestration_Tool.md)
* [06 Deployment Steps / 06 101 Create Viya Deployment Roles](/06_Deployment_Steps/06_101_Create_Viya_Deployment_Roles.md)
* [07 Deployment Customizations / 07 021 Configuring SASWORK](/07_Deployment_Customizations/07_021_Configuring_SASWORK.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirror manager to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirror_manager_to_populate_the_local_registry.md)
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [07 Deployment Customizations / 07 091 Configure SAS ACCESS Engine](/07_Deployment_Customizations/07_091_Configure_SAS_ACCESS_Engine.md)
* [07 Deployment Customizations / 07 101 Configure SAS ACCESS TO HADOOP](/07_Deployment_Customizations/07_101_Configure_SAS_ACCESS_TO_HADOOP.md)
* [07 Deployment Customizations / 07 102 Parallel loading with EP for Hadoop](/07_Deployment_Customizations/07_102_Parallel_loading_with_EP_for_Hadoop.md)
* [09 Validation / 09 011 Validate the Viya deployment](/09_Validation/09_011_Validate_the_Viya_deployment.md)
* [09 Validation / 09 021 SAS Viya deployment reports](/09_Validation/09_021_SAS_Viya_deployment_reports.md)
* [11 Azure AKS Deployment / 11 000 Navigating the AKS Hands on Deployment Options](/11_Azure_AKS_Deployment/11_000_Navigating_the_AKS_Hands-on_Deployment_Options.md)
* [11 Azure AKS Deployment / 11 999 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_999_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment/Fully Automated / 11 500 Full Automation of AKS Deployment](/11_Azure_AKS_Deployment/Fully_Automated/11_500_Full_Automation_of_AKS_Deployment.md)
* [11 Azure AKS Deployment/Fully Automated / 11 590 Cleanup](/11_Azure_AKS_Deployment/Fully_Automated/11_590_Cleanup.md)
* [11 Azure AKS Deployment/Standard / 11 100 Creating an AKS Cluster](/11_Azure_AKS_Deployment/Standard/11_100_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment/Standard / 11 110 Performing the prerequisites](/11_Azure_AKS_Deployment/Standard/11_110_Performing_the_prerequisites.md)
* [11 Azure AKS Deployment/Standard/Cleanup / 11 400 Cleanup](/11_Azure_AKS_Deployment/Standard/Cleanup/11_400_Cleanup.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 200 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/Standard/Manual/11_200_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 210 Deploy a second namespace in AKS](/11_Azure_AKS_Deployment/Standard/Manual/11_210_Deploy_a_second_namespace_in_AKS.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 220 CAS Customizations](/11_Azure_AKS_Deployment/Standard/Manual/11_220_CAS_Customizations.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 230 Install monitoring and logging](/11_Azure_AKS_Deployment/Standard/Manual/11_230_Install_monitoring_and_logging.md)
* [12 Amazon EKS Deployment / 12 010 Access Environments](/12_Amazon_EKS_Deployment/12_010_Access_Environments.md)
* [12 Amazon EKS Deployment / 12 020 Provision Resources](/12_Amazon_EKS_Deployment/12_020_Provision_Resources.md)
* [12 Amazon EKS Deployment / 12 030 Deploy SAS Viya](/12_Amazon_EKS_Deployment/12_030_Deploy_SAS_Viya.md)
* [13 Google GKE Deployment / 13 011 Creating a GKE Cluster](/13_Google_GKE_Deployment/13_011_Creating_a_GKE_Cluster.md)
* [13 Google GKE Deployment / 13 021 Performing Prereqs in GKE](/13_Google_GKE_Deployment/13_021_Performing_Prereqs_in_GKE.md)
* [13 Google GKE Deployment / 13 031 Deploying Viya 4 on GKE](/13_Google_GKE_Deployment/13_031_Deploying_Viya_4_on_GKE.md)
* [13 Google GKE Deployment / 13 041 Full Automation of GKE Deployment](/13_Google_GKE_Deployment/13_041_Full_Automation_of_GKE_Deployment.md)
* [13 Google GKE Deployment / 13 099 Fast track with cheatcodes](/13_Google_GKE_Deployment/13_099_Fast_track_with_cheatcodes.md)
<!-- endnav -->
