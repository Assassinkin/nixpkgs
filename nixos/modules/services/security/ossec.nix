{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.ossec;
  configFile = pkgs.writeText "ossec-config-file"
  ''
          <ossec_config>
    <client>
      <server-ip>${cfg.managerIP}</server-ip>
    </client>

    <syscheck>
      <!-- Frequency that syscheck is executed - default to every 22 hours -->
      <frequency>1800</frequency>

      <!-- Directories to check  (perform all possible verifications) -->
      <directories check_sum="yes" realtime="yes" restrict="authorized_keys">/root/.ssh</directories>

    <directories check_sum="yes" realtime="yes" restrict="passwd|group|shadow|sudoers">/etc</directories>

    <directories check_sum="yes" realtime="yes" restrict="sh|bash">/bin</directories>
    <directories check_sum="yes" realtime="yes" restrict="sshd">/usr/sbin</directories>

    </syscheck>

    <rootcheck>
      <rootkit_files>/var/ossec/etc/shared/rootkit_files.txt</rootkit_files>
      <rootkit_trojans>/var/ossec/etc/shared/rootkit_trojans.txt</rootkit_trojans>
      <system_audit>/var/ossec/etc/shared/system_audit_rcl.txt</system_audit>
      <system_audit>/var/ossec/etc/shared/cis_debian_linux_rcl.txt</system_audit>
      <system_audit>/var/ossec/etc/shared/cis_rhel_linux_rcl.txt</system_audit>
      <system_audit>/var/ossec/etc/shared/cis_rhel5_linux_rcl.txt</system_audit>
    </rootcheck>

    <active-response>
      <disabled>yes</disabled>
    </active-response>

    <!-- Files to monitor (localfiles) -->

    <localfile>
      <log_format>syslog</log_format>
      <location>/var/log/messages</location>
    </localfile>

    <localfile>
      <log_format>syslog</log_format>
      <location>/var/log/secure</location>
    </localfile>

    <localfile>
      <log_format>syslog</log_format>
      <location>/var/log/maillog</location>
    </localfile>

    <localfile>
      <log_format>command</log_format>
      <command>df -h</command>
    </localfile>

    <localfile>
      <log_format>full_command</log_format>
      <command>last -n 5</command>
    </localfile>
    </ossec_config>
    ${cfg.extraConfig}
  '';
  ossecControl = pkgs.writeText "ossec-control"
   ''
      #!/bin/sh
      # ossec-control        This shell script takes care of starting
      #                      or stopping ossec-hids
      # Author: Daniel B. Cid <daniel.cid@gmail.com>

      DIR=${pkgs.ossec};


      ###  Do not modify bellow here ###
      NAME="OSSEC HIDS"
      VERSION="v2.9.3"
      AUTHOR="Trend Micro Inc."
      DAEMONS="ossec-logcollector ossec-syscheckd ossec-agentd ossec-execd"

      [ -f /etc/ossec-init.conf ] && . /etc/ossec-init.conf

      ## Locking for the start/stop
      LOCK="${DIR}/var/start-script-lock"
      LOCK_PID="${LOCK}/pid"

      # This number should be more than enough (even if it is
      # started multiple times together). It will try for up
      # to 10 attempts (or 10 seconds) to execute.
      MAX_ITERATION="10"

      checkpid()
      {
       for i in ${DAEMONS}; do
           for j in `cat ${DIR}/var/run/${i}*.pid 2>/dev/null`; do
               ps -p $j |grep ossec >/dev/null 2>&1
               if [ ! $? = 0 ]; then
                   echo "Deleting PID file '${DIR}/var/run/${i}-${j}.pid' not used..."
                   rm ${DIR}/var/run/${i}-${j}.pid
               fi
           done
       done
      }

      lock()
      {
       i=0;

       # Providing a lock.
       while [ 1 ]; do
           mkdir ${LOCK} > /dev/null 2>&1
           MSL=$?
           if [ "${MSL}" = "0" ]; then
               # Lock aquired (setting the pid)
               echo "$$" > ${LOCK_PID}
               return;
           fi

           # Waiting 1 second before trying again
           sleep 1;
           i=`expr $i + 1`;

           # If PID is not present, speed things a bit.
           kill -0 `cat ${LOCK_PID}` >/dev/null 2>&1
           if [ ! $? = 0 ]; then
               # Pid is not present.
               i=`expr $i + 1`;
           fi

           # We tried 10 times to acquire the lock.
           if [ "$i" = "${MAX_ITERATION}" ]; then
               # Unlocking and executing
               unlock;
               mkdir ${LOCK} > /dev/null 2>&1
               echo "$$" > ${LOCK_PID}
               return;
           fi
       done
      }

      unlock()
      {
       rm -rf ${LOCK}
      }

      help()
      {
       # Help message
       echo "Usage: $0 {start|stop|restart|status}";
       exit 1;
      }

      status()
      {
       RETVAL=0
       for i in ${DAEMONS}; do
           pstatus ${i};
           if [ $? = 0 ]; then
               RETVAL=1
               echo "${i} not running..."
           else
               echo "${i} is running..."
           fi
       done
       exit $RETVAL
      }

      testconfig()
      {
       # We first loop to check the config.
       for i in ${SDAEMONS}; do
           ${DIR}/bin/${i} -t;
           if [ $? != 0 ]; then
               echo "${i}: Configuration error. Exiting"
               unlock;
               exit 1;
           fi
       done
      }

      # Start function
      start()
      {
       SDAEMONS="ossec-execd ossec-agentd ossec-logcollector ossec-syscheckd"

       echo "Starting $NAME $VERSION (by $AUTHOR)..."
       lock;
       checkpid;

       # We actually start them now.
       for i in ${SDAEMONS}; do
           pstatus ${i};
           if [ $? = 0 ]; then
               ${DIR}/bin/${i} -c ${configFile};
               if [ $? != 0 ]; then
                   echo "${i} did not start";
                   unlock;
                   exit 1;
               fi

               echo "Started ${i}..."
           else
               echo "${i} already running..."
           fi
       done

       # After we start we give 2 seconds for the daemons
       # to internally create their PID files.
       sleep 2;
       unlock;
       echo "Completed."
      }

      pstatus()
      {
       pfile=$1;

       # pfile must be set
       if [ "X${pfile}" = "X" ]; then
           return 0;
       fi

       ls ${DIR}/var/run/${pfile}*.pid > /dev/null 2>&1
       if [ $? = 0 ]; then
           for j in `cat ${DIR}/var/run/${pfile}*.pid 2>/dev/null`; do
               ps -p $j |grep ossec >/dev/null 2>&1
               if [ ! $? = 0 ]; then
                   echo "${pfile}: Process $j not used by ossec, removing .."
                   rm -f ${DIR}/var/run/${pfile}-$j.pid
                   continue;
               fi

               kill -0 $j > /dev/null 2>&1
               if [ $? = 0 ]; then
                   return 1;
               fi
           done
       fi

       return 0;
      }

      stopa()
      {
       lock;
       checkpid;
       for i in ${DAEMONS}; do
           pstatus ${i};
           if [ $? = 1 ]; then
               echo "Killing ${i} .. ";

               kill `cat ${DIR}/var/run/${i}*.pid`;
           else
               echo "${i} not running ..";
           fi

           rm -f ${DIR}/var/run/${i}*.pid
        done

       unlock;
       echo "$NAME $VERSION Stopped"
      }

      ### MAIN HERE ###

      case "$1" in
      start)
       testconfig
       start
       ;;
      stop)
       stopa
       ;;
      restart)
       testconfig
       stopa
       sleep 1;
       start
       ;;
      reload)
       DAEMONS="ossec-logcollector ossec-syscheckd ossec-agentd"
       stopa
       start
       ;;
      status)
       status
       ;;
      help)
       help
       ;;
      *)
       help
      esac



   '';

in {
  options = {
    services.ossec = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Whether to enable the OSSEC HID agent";
      };

      managerIP = mkOption {
        default = "54.156.0.106";
        type = types.uniq types.string;
        description = "The IP address of the manager running ossec-authd";
      };

      managerPort = mkOption {
        type = types.uniq types.int;
        default = 1514;
        description = "The TCP port ossec-authd is running on";
      };
      extraConfig = mkOption {
        type = types.lines;
        description = "extra ossec configuration file";
        default = ''
        '';
      };
      agentKeyFile = mkOption {
        default = "/run/keys/ossecKey";
        type = types.uniq (types.nullOr types.path);
        description = ''
          The ossec agent key
          An example of how to use this in a nixops deployment would be:
          {
            deployoment.storeKeysOnMachine = false;
            deployment.keys.ossecKey = "MDE4IG5peC10ZXN0IDM4LjEwNC4wLjMwIDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";
            services.ossec.agentKeyFile = "/run/keys/ossecKey";
          }
        '';
      };

    };
  };

    config = lib.mkIf cfg.enable {


      environment.systemPackages = [ pkgs.ossec ];

      systemd.services.ossec = {
        preStart = with pkgs; ''
         # Add ossec key if available
         ${lib.optionalString (cfg.agentKeyFile != null) ''

          echo "I" | cat - <(cat ${cfg.agentKeyFile} | tr -d '\n') <(echo -e "\ny\n\nQ") | ${pkgs.ossec}/bin/manage_agents
         ''}
         ## Auto-register (fix it later)
         #if [[ ! -f ${pkgs.ossec}/etc/client.keys ]]; then
        #  echo "Registering agent at ${cfg.managerIP}"
        #  ${pkgs.ossec}/bin/agent-auth -m ${cfg.managerIP} -p ${builtins.toString cfg.managerPort}
         #else
        #  echo "Client key already available in ${pkgs.ossec}/etc/client.keys"
        # fi
        '';
        serviceConfig.ExecStart = "${ossecControl} start";
        serviceConfig.ExecStop = "${ossecControl}/bin/ossec-control stop";
        serviceConfig.Type = "forking";
        serviceConfig.TimeoutStartSec = "300";
        description = "The ossec-hid client";
        wantedBy = [ "multi-user.target" ];
        after = [ "syslog.target" ];
      };
       users.extraUsers.ossec = {
        description = "ossec-hid user";
        group = "ossec";
        uid = 902;
      };

      users.extraUsers.ossecr = {
        description = "ossec-hid remoted user";
        group = "ossec";
        uid = 903;
      };

      users.extraUsers.ossecm = {
        description = "ossec-hid mail user";
        group = "ossec";
        uid = 904;
      };

      users.extraGroups.ossec.gid = 905;
  };
}
#ossec-execd ossec-agentd ossec-logcollector ossec-syscheckd

