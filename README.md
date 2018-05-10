# Ubiquiti-Device-UNMS-Enable
A sometimes functional script for enabling UNMS feature on Ubiquiti equipment.
Runs on /24 network by default (change network in script).
Change user.txt, pass.txt, and unms.key files before running.
Works great on my Ubuntu 16.04 server without GUI.
Doesn't work on my Ubuntu 16.10 server with GUI.
This broke our 5 port Toughswitches. We had to go manually power cycle them at the towers because they couldn't be pinged or web interfaced or SSHd.
