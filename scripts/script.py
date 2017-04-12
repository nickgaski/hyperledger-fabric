#!/usr/bin/python2.7
import shlex
import sys
import subprocess
import unittest
from subprocess import Popen, PIPE

class TestExampleChaincodes(unittest.TestCase):

    def runIt(self, command, scriptName):
          cmd = "./scripts/%s %s %s %s %s %s"% (scriptName, CHANNEL_NAME, CHANNELS, CHAINCODES, ENDORSERS, command)
          print cmd
          p = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
          output = p.communicate()[0]
          print output
          self.assertEqual(p.returncode, 0)

    def createChannel(self, scriptName):
        self.runIt("create", scriptName)

    def joinChannel(self, scriptName):
        self.runIt("join", scriptName)

    def install(self, scriptName):
        self.runIt("install", scriptName)

    def instantiate(self, scriptName):
        self.runIt("instantiate", scriptName)

    def invokeQuery(self, scriptName):
        self.runIt("invokeQuery", scriptName)

#####Begin tests for different chaincode samples###################
    def test_example02(self):
        script_name = "script_example02_py.sh"
        self.createChannel(script_name)
        self.joinChannel(script_name)
        self.install(script_name)
        self.instantiate(script_name)
        self.invokeQuery(script_name)

    def test_example04(self):
        script_name = "script_example04_py.sh"
        self.install(script_name)
        self.instantiate(script_name)
        self.invokeQuery(script_name)

    def test_example05(self):
        script_name = "script_example05_py.sh"
        self.install(script_name)
        self.instantiate(script_name)
        self.invokeQuery(script_name)

if __name__ == '__main__':
    CHANNEL_NAME = sys.argv[1]
    CHANNELS = sys.argv[2]
    CHAINCODES = sys.argv[3]
    ENDORSERS = sys.argv[4]
    sys.argv.pop()
    sys.argv.pop()
    sys.argv.pop()
    sys.argv.pop()
    print CHANNEL_NAME
    print CHANNELS
    print CHAINCODES
    print ENDORSERS
    
    #suite = unittest.TestLoader().loadTestsFromTestCase(TestExampleChaincodes)
    #unittest.TextTestRunner(verbosity=2).run(suite)

    unittest.main(verbosity=2, testRunner=xmlrunner.XMLTestRunner(output='test-reports'))
