## To execute run from the root of this repo:

`docker-compose run bosh-in-docker`

## In a different tab, to connect to the running container. From the root of this repo:

```
docker-compose exec bosh-in-docker /bin/bash
source /shared-creds/bosh-creds.bash
# Now you can run bosh commands
bosh deployments
bosh vms
```

## To terminate the container:

Either run Cmd + C or Ctrl + C in the first terminal (the one in which you ran `docker-compose run bosh-in-docker`.

Or open a new terminal, navigate to the root of this repo and run:
`docker-compose down`

## Running on Docker for Mac

Ensure you have deprecatedCgroupv1 enabled. Find detailed instructions in the following readme.

https://github.com/cloudfoundry/haproxy-boshrelease/blob/master/acceptance-tests/README.md#running-on-docker-for-mac

## Open issue to investigate the error I'm getting

https://github.com/cloudfoundry/bosh-docker-cpi-release/issues/18

Excerpt:
```
Task 34 | 18:26:36 | Creating missing vms: tcp-router/fba5d8cc-00f1-4e49-bfe3-43f4da28d2ed (0) (00:00:01)
                   L Error: CPI error 'Bosh::Clouds::CloudError' with message 'Creating VM with agent ID '{{36671fcd-fd27-411b-88a5-8cd1dbdfe74d}}': Unmarshaling VM properties: json: cannot unmarshal object into Go struct field VMProps.ports of type string' in 'create_vm' CPI method (CPI request ID: 'cpi-269875')
Task 34 | 18:26:36 | Creating missing vms: router/a79e0d70-8817-488f-8fee-08ba28ca94b7 (0) (00:00:01)
                   L Error: CPI error 'Bosh::Clouds::CloudError' with message 'Creating VM with agent ID '{{0e8ecd89-aae6-4b30-90ec-125f1499547a}}': Unmarshaling VM properties: json: cannot unmarshal object into Go struct field VMProps.ports of type string' in 'create_vm' CPI method (CPI request ID: 'cpi-519893')
```
