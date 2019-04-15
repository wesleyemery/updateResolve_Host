#!/bin/bash

#Script to update /etc/hosts and /etc/resolv.conf search domains on cloud endure migrated servers

ipAddress=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
etcHosts="/etc/hosts"
etcResolv="/etc/resolv.conf"
logDate=$(date +"%b %e %H:%M:%S")
date=$(date +%m+%d+%Y)
log="/var/log/messages"
hostname=$(hostname -s)

. ./removeVMTools

function removeHost() {
   local hostRegEx="\(\s\+\)${hostname}\s*"
   local hostLine=`grep -e $hostRegEx $etcHosts`

   if [ -n "${hostLine}" ]; then
      cp /etc/hosts /etc/hosts.${date}
      echo "${logDate} ${HOSTNAME} Found in your ${etcHosts}, Removing now." | tee -a $log > /dev/null 2>&1
      sed -i -e "s/${hostLine}//g" -e "/^[^#][0-9\.]\+\s\+$/d" ${etcHosts}
   else
      echo "${logDate} ${HOSTNAME} not found in your ${etcHosts}" | tee -a $log > /dev/null 2>&1
   fi
}

function addHost() {
   local hostRegEx="\(\s\+\)${HOSTNAME}\s*$"
   local hostLine=`grep -e $hostRegEx $etcHosts`

   if [ -n "${hostLine}" ]; then
      echo "${logDate} ${HOSTNAME} already exists : ${hostLine}" | tee -a $log > /dev/null 2>&1
   else
      echo "${logDate} ${HOSTNAME} Adding ${HOSTNAME} to your ${etcHosts}" | tee -a $log > /dev/null 2>&1
      echo -e "${ipAddress}\t${HOSTNAME}" >> ${etcHosts}
   fi

}

function addSearchDomain() {
   local searchDomain1="westrock.com"
   local searchDomain2="rocktenn.com"
   local searchDomain3="ec2.internal"
   local searchDomainLine=$(grep "search" $etcResolv)

   if [ -n "$searchDomainLine" ]; then
      cp /etc/resolv.conf /etc/resolv.conf.${date}
      sed -i "s/${searchDomainLine}/search $searchDomain1 $searchDomain2 $searchDomain3/g" /etc/resolv.conf
      echo "${logDate} ${HOSTNAME} ${searchDomain1} ${searchDomain2} ${searchDomain3} added to ${etcResolv}" | tee -a $log > /dev/null 2>&1
      chattr +i $etcResolv
   else
      cp /etc/resolv.conf /etc/resolv.conf.${date}
      sed -i '4i\search $searchDomain1 $searchDomain2' $etcResolv
      echo "${logDate} ${HOSTNAME} ${searchDomain1} ${searchDomain2} ${searchDomain3} added to ${etcResolv}" | tee -a $log > /dev/null 2>&1
      chattr +i $etcResolv
   fi

}

addSearchDomain
removeHost
addHost
removeVMTools
