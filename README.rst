# End-to-End CLI tests on example chaincodes that exist on fabric examples folder
=================================================================================

This test provides e2e test coverage for each chaincode example under fabric/examples/.
The test design and layout is similar to e2e test in fabric/examples/e2e_cli folder.
This is intended for use in automated daily test runs.


Note:
The end-to-end verification demonstrates usage of the configuration
transaction tool for orderer bootstrap and channel creation. The tool
consumes a configuration transaction yaml file, which defines the
cryptographic material (certs) used for member identity and network
authentication - in other words, the MSP information for each member and
its corresponding network entities.

*Currently the crypto material is baked into the directory.*

Currently we test following example chaincodes in single e2e flow:


## example-chaincode     bash-script                Very Brief One line description of chanicode function
===================================================================================================================
chaincode_example02    e2e_test_example02.sh    basic chaincode where value X is moved from asser A to asset B
chaincode_example03    e2e_test_example03.sh    -ve test case where a query is invalidated
chaincode_example04    e2e_test_example04.sh    chaincode calling chaincode on an event occurring in chaincode


These individual bash scripts are then wrapped inside script.py under "./scripts" folder and executed sequentially in a single test.

script.py is called as a command from docker-compose.yaml file.

------------------------------------------------------------------------------------------------------------

### To run exampleChaincode tests 

If not already done, clone the Fabric code base.

```

 git clone https://github.com/hyperledger/fabric.git

 cd fabric

 run "make docker"

 cd test/regression/daily/exampleChaincodes
 
 ./network_setup <up|down|retstart> [channel-name] [total-channels [chaincodes] [endorsers count]
```

### sample command

```
 ./network_setup up myc 1 1 4
```

### output of each of the steps on executing python script looks like 

```
./scripts/e2e_test_example03.sh myc 1 1 4 instantiate
```

where e2e_test_example03.sh is the shell script that has cli commands, like for instance here we are running chaincode_example03 instantiate command

### After the tests are run 
  ./network_setup.sh down
