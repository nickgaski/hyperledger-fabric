#!/bin/bash
START_TIME=$(date +%s)

##### GLOBALS ######
CHANNEL_NAME="$1"
CHANNELS="$2"
CHAINCODES="$3"
ENDORSERS="$4"
fun="$5"

##### SET DEFAULT VALUES #####
: ${CHANNEL_NAME:="mychannel"}
: ${CHANNELS:="1"}
: ${CHAINCODES:="1"}
: ${ENDORSERS:="4"}
: ${TIMEOUT:="100"}
COUNTER=0
MAX_RETRY=5

# find address of orderer and peers in your network
ORDERER_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("orderer")); print "$a\n";'`
PEER0_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer0")); print "$a\n";'`
PEER1_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer1")); print "$a\n";'`
PEER2_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer2")); print "$a\n";'`
PEER3_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer3")); print "$a\n";'`

echo "-----------------------------------------"
echo "Orderer IP $ORDERER_IP"
echo "PEER0 IP $PEER0_IP"
echo "PEER1 IP $PEER1_IP"
echo "PEER2 IP $PEER2_IP"
echo "PEER3 IP $PEER3_IP"


echo "Channel name prefix: $CHANNEL_NAME"
echo "Total channels: $CHANNELS"
echo "Total Chaincodes: $CHAINCODES"
echo "Total Endorsers: $ENDORSERS"
echo "-----------------------------------------"

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
		echo "Total execution time $(($(date +%s)-START_TIME)) secs"
   		exit 1
	fi
}

setGlobals () {
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peer/peer$1/localMspConfig
	CORE_PEER_ADDRESS=peer$1:7051
	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org0MSP"
	else
		CORE_PEER_LOCALMSPID="Org1MSP"
	fi
}

createChannel() {
	CHANNEL_NUM=$1
	peer channel create -o $ORDERER_IP:7050 -c $CHANNEL_NAME$CHANNEL_NUM -f crypto/orderer/channel$CHANNEL_NUM.tx >&log.txt
	res=$?
	cat log.txt
	verifyResult $res "Channel creation with name \"$CHANNEL_NAME$CHANNEL_NUM\" has failed"
	echo "===================== Channel \"$CHANNEL_NAME$CHANNEL_NUM\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	for (( i=0; $i<$CHANNELS; i++))
	do
		peer channel join -b $CHANNEL_NAME$i.block  >&log.txt
		res=$?
		cat log.txt
		if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
			COUNTER=` expr $COUNTER + 1`
			echo "PEER$1 failed to join the channel 'mychannel$i', Retry after 2 seconds"
			sleep 2
			joinWithRetry $1
		else
			COUNTER=0
		fi
        	verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
		echo "===================== PEER$1 joined on the channel \"$CHANNEL_NAME$i\" ===================== "
		sleep 2
	done
}

joinChannel () {
	PEER=$1
	setGlobals $PEER
	joinWithRetry $PEER
	echo "===================== PEER$PEER joined on $CHANNELS channel(s) ===================== "
	sleep 2
	echo
}


installChaincode () {
	for (( i=0; $i<$ENDORSERS; i++))
	do
		for (( ch=0; $ch<$CHAINCODES; ch++))
		do
			PEER=$i
			setGlobals $PEER
			peer chaincode install -n ex02 -v 1 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
			res=$?
			cat log.txt
		        verifyResult $res "Chaincode 'ex02' installation on remote peer PEER$PEER has Failed"
			echo "===================== Chaincode 'ex02' is installed on remote peer PEER$PEER ===================== "

			peer chaincode install -n ex04 -v 1 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example04 >&log.txt
			res=$?
			cat log.txt
		        verifyResult $res "Chaincode 'ex04' installation on remote peer PEER$PEER has Failed"
			echo "===================== Chaincode 'ex04' is installed on remote peer PEER$PEER ===================== "
			echo
			echo
		done
	done
}

instantiateChaincodeEx02() {
	PEER=$1
	setGlobals $PEER
	for (( i=0; $i<$CHANNELS; i++))
	do
		for (( ch=0; $ch<$CHAINCODES; ch++))
		do
		  peer chaincode instantiate -o $ORDERER_IP:7050 -C $CHANNEL_NAME$i -n ex02 -v 1 -c '{"Args":["init","a","1000", "b", "2000"]}' -P "OR ('Org0MSP.member','Org1MSP.member')" >&log.txt
		  res=$?
		  cat log.txt
		  verifyResult $res "Chaincode 'ex02' instantiation on PEER$PEER on channel '$CHANNEL_NAME$i' failed"
		  echo "===================== Chaincode 'ex02' Instantiation on PEER$PEER on channel '$CHANNEL_NAME$i' is successful ===================== "
		  echo
		done
	done
}


instantiateChaincodeEx04() {
	PEER=$1
	setGlobals $PEER
	for (( i=0; $i<$CHANNELS; i++))
	do
		for (( ch=0; $ch<$CHAINCODES; ch++))
		do
		  peer chaincode instantiate -o $ORDERER_IP:7050 -C $CHANNEL_NAME$i -n ex04 -v 1 -c '{"Args":["init","Event", "123"]}' -P "OR ('Org0MSP.member','Org1MSP.member')" >&log.txt
		  res=$?
		  cat log.txt
		  verifyResult $res "Chaincode 'ex04$ch' instantiation on PEER$PEER on channel '$CHANNEL_NAME$i' failed"
		  echo "===================== Chaincode 'ex04' Instantiation on PEER$PEER on channel '$CHANNEL_NAME$i' is successful ===================== "
		  echo
		done
	done
}

chaincodeInvokeEx04() {
        local channel_num=$1
        local peer=$2
	peer chaincode invoke -o $ORDERER_IP:7050  -C $CHANNEL_NAME$channel_num -n ex04 -c '{"Args":["invoke","ex02","Event","1"]}' >&log.txt
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$peer failed "
	echo "===================== Invoke transaction from chaincodeEx04 on PEER$peer on $CHANNEL_NAME$channel_num/ex02 is successful ===================== "
	echo
}

chaincodeQueryEx02() {
  local channel_num=$1
  local peer=$2
  local res=$3
  echo "===================== Querying on PEER$peer on $CHANNEL_NAME$channel_num/ex02... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$peer ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME$channel_num -n ex02 -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$res" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$peer on $CHANNEL_NAME$channel_num/ex02 is successful ===================== "
	echo
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$peer is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	echo "Total execution time $(($(date +%s)-START_TIME)) secs"
	echo
	exit 1
  fi
}

chaincodeQueryEx04() {
  local channel_num=$1
  local peer=$2
  local res=$3
  echo "===================== Querying on PEER$peer on $CHANNEL_NAME$channel_num/mycc$chain_num... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$peer ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME$channel_num -n ex04 -c '{"Args":["query","Event", "ex02", "a", "myc0"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$res" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$peer on $CHANNEL_NAME$channel_num/mycc$chain_num is successful ===================== "
	echo
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$peer is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	echo "Total execution time $(($(date +%s)-START_TIME)) secs"
	echo
	exit 1
  fi
}

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/orderer/localMspConfig
CORE_PEER_LOCALMSPID="OrdererMSP"

validateArgs () {
        if [ -z "${fun}" ]; then
                echo "create/join/install/instantiate/invokeQuery not mentioned"
                printHelp
                exit 1
        fi
        if [ "${fun}" = "create" -o "${fun}" == "join" -o "${fun}" == "install" -o "${fun}" == "instantiate" -o "${fun}" == "invokeQuery" ]; then
                return
        else 
           	echo "Invalid Argument"
           	exit 1
        fi
}

validateArgs

if [ "${fun}" = "create" ]; then
## Create channel
	for (( ch=0; $ch<$CHANNELS; ch++))
	do
		createChannel $ch
	done
elif [ "${fun}" == "join" ]; then
## Join all the peers to all the channels
	for (( peer=0; $peer<$ENDORSERS; peer++))
	do
		echo "====================== Joing PEER$peer on all channels ==============="
		joinChannel $peer
	done
elif [ "${fun}" == "install" ]; then
## Install chaincode on Peer0/Org0 and Peer2/Org1
	echo "Installing chaincode on all Peers ..."
	installChaincode

elif [ "${fun}" == "instantiate" ]; then
#Instantiate chaincode on Peer2/Org1
	echo "Instantiating chaincode on all channels on PEER0 ..."
	instantiateChaincodeEx02 0
	instantiateChaincodeEx04 0

elif [ "${fun}" == "invokeQuery" ]; then
#Invoke/Query on all chaincodes on all channels
	echo "send Invokes/Queries on all channels ..."
        sleep 30
        ch=0
        PEER=0
        setGlobals "$PEER"
	chaincodeQueryEx02 $ch $PEER "1000"
	sleep 30
	chaincodeInvokeEx04 $ch $PEER 
	sleep 30
	chaincodeQueryEx04 $ch $PEER "990"
	echo
	echo "===================== All GOOD, End-2-End execution for chaincode example04 completed ===================== "
	echo
	echo "Total execution time $(($(date +%s)-START_TIME)) secs"
	exit 0
else
	printHelp
	exit 1
fi
