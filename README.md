# Example Helix Nagios Plugins  
* * *

### Introduction

This project contains an example bash script that shows how Helix components could be monitored from a Nagios server. The plugin currently checks:

* if the P4D server is responding.
* if the P4D server license is about to expire.
* if the P4D disk space is low.
* if the number of running P4D processes is excessive.
* if replication is running (replica server only). 

The return states are configurable so could be customised for other monitoring solutions as needed:

    STATE_OK=0
    STATE_WARNING=1
    STATE_CRITICAL=2


### Scripts

**check_helix_p4d_health**

    Usage:
        check_helix_p4d_health -p <p4port> [options] [tests]

        options: [-u <p4-user>] [-T <p4-ticket-file-name>] [-P <p4-password>] 
                 [-t <p4trust-file>] [--tips] [--comment] [--version] [--help]

        tests:   [--all]
                 [--remoteonly]
                 [--licensecheck]  [--licthreshold <expire-days-threshold>]
                 [--pidcheck] [--pidthreshold <running-p4-pid-threshold>] 
                 [--p4monitorcheck] [--monthreshold <p4-processes-threshold>]
                 [--p4diskcheck] [--diskthreshold <disk-used-threshold>]
                 [--p4repcheck]

         dependencies: The plugin relies on 'p4' being installed on the 
                       machine executing the plugin.

    Nagios plugins are required to only output one line of text. The '--tips'
    flag can be used to display full error/status output and a helpful tip
    to help find the cause or solve the problem.

    The '-u' flag specifies the P4D user name. This user must be an 'operator'
    user or must have 'super' access to the P4D server

    The '-p' flag specifies the P4D hostname and port in the 
    format 'hostname:port'.

    The '-t' flag specifies the location of the P4TRUST file for SSL 
    connections.
    
    The '-T' flag specifies the location of the tickets file.

    The '-P' flag explicitly sets the password to use. Note this may not be 
    secure and the use of 'p4 login' and a tickets file ('-T') on the server 
    provides better security.

    If no tests are specified then only the P4D server online test is run.
    Multiple test arguments can be supplied. Thresholds can be supplied
    with specific tests or when using '--all' or '--remoteonly'. 

    The '--all' flag runs all tests. 

    The '--remoteonly' flag runs only remote tests using the p4 client. These
    tests can be run from any machine with network access to the P4D server 
    (including the Nagios server).

    The '--licensecheck' flag tests if the license file is nearing it's 
    expiry date.  By default it checks for expiry within '30' days but this 
    can be overriden with the '--licthreshold' flag.

    The '--p4diskcheck' flag checks for free disk space on the P4D drives using
    the Perforce command 'p4 diskspace' and warns if the disks are over 95% used.
    This value can be overriden by speciying a value between 0 and 99 using with 
    the '--diskthreshold' flag.
    
    The '--pidcheck' flag counts the number of connected p4d processes using 
    'netstat' and warns if the are over 500 processes running. This value can 
    be overriden with the '--pidthreshold' flag. This test must be run on the 
    P4D server machine.

    The '--p4monitorcheck' flag counts the number of commands in the 
    'p4 monitor' table and warns if there are over 500 running. This value can be 
    overriden with the '--monthreshold' flag.

    The '--p4repcheck' flags (REPLICA ONLY) checks that replication is running.

    The '--message' flag allows you to prepend an alert with a custom message.


 Example output without '--tips':

     CRITICAL: P4D server not responding!

 Example output with '--tips':

     CRITICAL: P4D server not responding!
     Perforce client error:
         Connect to server failed; check $P4PORT.
         TCP connect to localhost:1666 failed.
         connect: 127.0.0.1:1666: Connection refused
     TIP:
     Check if the 'p4d' process is running on the box.
     Check the P4D log file for errors if it unexpectedly
     stopped.

 Examples:

 Run all checks against server on localhost:1666

    check_helix_p4d_health -p 1666 --all

Check if license will expire in next 45 days

    check_helix_p4d_health -p 1666 --licensecheck -licthreshold 45


### Nagios and P4D using SSL

If the P4D server is running using SSL then the connection must first be trusted. For example to trust connection 'ssl:localhost:1666':

    export P4TRUST=/etc/nagios/.p4trust
    touch $P4TRUST
    p4 -p ssl:localhost:1666 trust 
    chown nagios:nagios $P4TRUST
    chmod 600 $P4TRUST

The Nagios command then may look similar to:

    check_helix_p4d_health -p 1666 --p4diskcheck -u operator -T /etc/nagios/.p4tickets


### Nagios and Perforce User Login

Many of the Perforce tests require the user to be logged in. The plugin allows you to specify a password with the '-P' flag but it's better practice to use a long lived ticket owned by the Nagios user on the monitored system. For example to create a ticket under '/etc/nagios/.p4tickets' for a Helix P4D user called 'operator':

    export P4TICKETS=/etc/nagios/.p4tickets
    touch $P4TICKETS
    p4 -p localhost:1666 -u operator login
    chown nagios:nagios $P4TICKETS
    chmod 600 $P4TICKETS

The Nagios command then may look similar to:

    check_helix_p4d_health -p localhost:1666 -u operator -T /etc/nagios/.p4tickets --p4diskcheck

It's also good practice that the P4D user is an 'operator' user to decrease the amount of power this user has. If you have any queries about Helix P4D users and security discuss this with your security team or 'support@perforce.com'.


### Example Nagios Installation

While this document uses the term "Nagios" it's more precise to say these instructions are for Nagios Core, the GPL version of the Nagios monitoring engine. As Nagios XI uses the Nagios Core component for the checks, there is no reason to believe the plugin will not work in Nagios XI. However, directly editing the config files will not work in Nagios XI unless you use their static directory. See https://assets.nagios.com/downloads/nagiosxi/docs/Managing-Config-Files-Manually-With-Nagios-XI.pdf for additional information.

The script can be run using SSH or NRPE. In the example below I use the NRPE plugin. Note that it requires that the NRPE service accepts arguments which can be a security risk. If you have an doubts use SSH or hard code the paramaters on the monitored server.

Below are the command definitions for the NRPE service and scripts on the Nagios server.

    define command{
        command_name    check_nrpe
        command_line    /usr/lib/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$ -a $ARG2$
        }

    define command{
        command_name    check_helix_p4d_health
        command_line    $USER1$/check_helix_p4d_health $ARG1$
        }


Below is a service definition that runs the script 'check_helix_p4d_health' use 'check_nrpe' and provides the parameters '-p localhost:1666 --licensecheck'. This can be used to check the Helix P4D license status on port 1666 on theserver 'master-helix-server'.

    define service {
      host_name                       master-helix-server
      service_description             Helix P4D ServerName 1666 License Check
      check_command                   check_nrpe!check_helix_p4d_health!'-p localhost:1666 --licensecheck'
      max_check_attempts              2
      check_interval                  2
      retry_interval                  2
      check_period                    24x7
      check_freshness                 1
      contact_groups                  admins
      notification_interval           2
      notification_period             24x7
      notifications_enabled           1
      register                        1
    }

As you can see the '-p' flag is the value that will be run on the server running the script. When using NRPE the script will be run on the Perforce server so 'localhost:1666' could be passed.

Note: You can choose to have a seperate service definition that allows you to monitor each test as a seperate entry in Nagios as above, or specify multipls tests in one definition (for example using '--all'). For example:

    define service {
      host_name                       master-helix-server
      service_description             Helix P4D ServerName 1666
      check_command                   check_nrpe!check_helix_p4d_health!'-p localhost:1666 --all -u operator -T /etc/nagios/.p4tickets'
      max_check_attempts              2
      check_interval                  2
      retry_interval                  2
      check_period                    24x7
      check_freshness                 1
      contact_groups                  admins
      notification_interval           2
      notification_period             24x7
      notifications_enabled           1
      register                        1
    }  
 

On the monitored server the command is configured within NRPE as a single line:

    command[check_helix_p4d_health]=/usr/lib/nagios/plugins/check_helix_p4d_health $ARG1$*

More information on configuring NRPE can be found on the Nagios website.


## Test Harness

The plugin has been tested on Ubuntu 14.04 with P4D 2016.1 Beta, P4D 2015.2 and P4D 2013.1. The test harness has been provided to allow it to easily be tested on other platforms with other P4D versions. The tests should be run from the plugin directory using:
 
           perl t/check_helix_p4d_health.t

The tests require that P4 and P4D are in the path and will start P4D servers on ports 1234 and 1235 under the directory './t/tmp/'. At the end of a the test suite the P4D servers on these ports and the './t/tmp' directory will be removed.

IMPORTANT NOTE: This test harness is intended for development purposes only and should not be run on a live P4D machine.


### Roadmap

Additional P4D checks:
* highlight when replication slows down.
* check btree depths.
* warn on long running commands.

Additional Helix checks:
* Swarm checks.
* Helix4Git checks.

