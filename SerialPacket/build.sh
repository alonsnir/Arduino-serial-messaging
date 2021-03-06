#!/bin/bash
##
# build.sh - Script to build several Arduino .ino files at the same time
#   1. Build the source
#   2. Static code analysis using cppcheck
#   3. Fix indentation using bcpp
#
# Copyright 2012 Jeroen Doggen (jeroendoggen@gmail.com)
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

START=$(date +%s)
START2=$(date)

##################################################################  
# SCRIPT SETTINGS                                               #
##################################################################

SCRIPTPATH="`pwd`"
RESOURCESPATH=$SCRIPTPATH"/resources/"
EXAMPLESPATH=$SCRIPTPATH"/examples/"
CPPCHECKOPTIONS="--enable=all --error-exitcode=1 --std=c99 --std=posix  --std=c++11 -v"

BUILDSUCCESCOUNTER=0
BUILDFAILURECOUNTER=0

CODECHECKFAILURECOUNTER=0
CODECHECKSUCCESCOUNTER=0

INDENTSUCCESCOUNTER=0
INDENTFAILURECOUNTER=0

MAXDEPTH=1

##################################################################  
# SELECT FILES TO BUILD                                          #
##################################################################

cd examples

# create the FILES[] array, filled with all the folder names in the examples folder
FILES=( $(find . -maxdepth 2 -type d -printf '%P\n') )

# select the range of file you want to build (from FIRSTFILE up to LASTFILE)
FIRSTFILE=0
LASTFILE=${#FILES[@]}-1  #equals last element of the FILES[] array

##################################################################  
# FUNCTIONS                                                      #
##################################################################  

function buildFile 
{
  scons > /dev/null
  if [ $? -eq 0 ] 
    then
      echo "Build OK in folder: '`pwd | awk -F/ '{print $(NF-1),$NF}'`' "
      echo "`date`: Build OK in folder: '`pwd | awk -F/ '{print $(NF-1),$NF}'`' " >> $RESOURCESPATH/succes.log
        let BUILDSUCCESCOUNTER++ 

    else
      echo "Build errors in folder: '`pwd | awk -F/ '{print $(NF-1),$NF}'`' "
      echo "`date`: Build errors in folder: '`pwd | awk -F/ '{print $(NF-1),$NF}'`' " >> $RESOURCESPATH/errors.log
      let BUILDFAILURECOUNTER++
  fi
}

function CreateLogfiles 
{
  if [ -f $RESOURCESPATH/succes.log ];
  then
    echo -ne ""
  else
    echo "File succes.log does not exist, creating it now"
    touch $RESOURCESPATH/succes.log
  fi

  if [ -f $RESOURCESPATH/errors.log ];
  then
    echo -ne ""
  else
    echo "File errors.log does not exist, creating it now"
    touch $RESOURCESPATH/errors.log
  fi
}

function PrintStats
{
  echo ""
  echo "------------------------------"
  echo "| Succesfull builds      : $BUILDSUCCESCOUNTER  "
  echo "| Failed builds          : $BUILDFAILURECOUNTER  "
  echo "|-----------------------------"
  echo "| Succesfull code checks : $CODECHECKSUCCESCOUNTER  "
  echo "| Failed code checks     : $CODECHECKFAILURECOUNTER  "
  echo "|-----------------------------"
  echo "| Succesfull indents     : $INDENTSUCCESCOUNTER "
  echo "| Failed indents         : $INDENTFAILURECOUNTER "
  echo "------------------------------"
  echo ""
}

function logStats
{
  echo "--------------------------------" > $RESOURCESPATH/lastbuild.log
  echo "| `date` |" >> $RESOURCESPATH/lastbuild.log
  echo "--------------------------------" >> $RESOURCESPATH/lastbuild.log
  echo "| Succesfull builds : $BUILDSUCCESCOUNTER        |" >> $RESOURCESPATH/lastbuild.log
  echo "| Failed builds     : $BUILDFAILURECOUNTER        |" >> $RESOURCESPATH/lastbuild.log
  echo "|------------------------------|" >> $RESOURCESPATH/lastbuild.log
  echo "| Succesfull code checks : $CODECHECKSUCCESCOUNTER   |" >> $RESOURCESPATH/lastbuild.log
  echo "| Failed code checks     : $CODECHECKFAILURECOUNTER   |" >> $RESOURCESPATH/lastbuild.log
  echo "--------------------------------" >> $RESOURCESPATH/lastbuild.log

  END=$(date +%s)
  DIFF=$(( $END - $START ))
  echo "Build took $DIFF seconds." >> $RESOURCESPATH/lastbuild.log
  echo "Build took $DIFF seconds."
}

function buildFiles
{
  for ((i=FIRSTFILE;i<=LASTFILE;i++)); do
    echo ${FILES[i]} | grep build > /dev/null  # don't try a scons build in the build folder
    if [ $? -eq 1 ]
        then
        cd ${FILES[i]}
        if [ -f *.ino ];   # to ignore (toplevel) folders without .ino files
          then
            buildFile
        fi
        cd $EXAMPLESPATH
    fi
  done
}

function staticCodeCheck
{
if [ $BUILDFAILURECOUNTER -eq 0 ]
    then
      staticCodeCheckRun
    else
      echo "Build errors -> skipping static code analysis"
fi
}

function staticCodeCheckRun
{
  FILES=( $(find . -maxdepth 3 -type d -printf '%P\n') )
  for ((i=FIRSTFILE;i<=LASTFILE;i++)); do
    cd ${FILES[i]}
    if [ -f *.ino ];   # to ignore (toplevel) folders without .ino files
      then
        staticCodeCheckFile
     fi
    cd $EXAMPLESPATH
  done

  cd $SCRIPTPATH
  cppcheck $CPPCHECKOPTIONS *.h > /dev/null
  if [ $? -eq 0 ] 
    then
      echo "Cppcheck OK in header file(s)"
      echo "`date`: Cppcheck OK in header file(s)" >> $RESOURCESPATH/succes.log
        let CODECHECKSUCCESCOUNTER++ 

    else
      echo "Cppcheck errors in header file(s)"
      echo "`date`: Cppcheck errors in header file(s)" >> $RESOURCESPATH/errors.log
      let CODECHECKFAILURECOUNTER++
  fi

  cppcheck $CPPCHECKOPTIONS *.cpp > /dev/null
  if [ $? -eq 0 ] 
    then
      echo "Cppcheck OK in cpp file(s)"
      echo "`date`: Cppcheck OK in cpp file(s)" >> $RESOURCESPATH/succes.log
        let CODECHECKSUCCESCOUNTER++ 

    else
      echo "Cppcheck errors in cpp file(s)"
      echo "`date`: Cppcheck errors in cpp file(s)" >> $RESOURCESPATH/errors.log
      let CODECHECKFAILURECOUNTER++
  fi
}

function staticCodeCheckFile
{
  if [ -f *.cpp ];   # to ignore (toplevel) folders without .cpp files
      then
        cppcheck $CPPCHECKOPTIONS *.cpp > /dev/null
        if [ $? -eq 0 ] 
          then
            echo "Cppcheck OK in folder: '`pwd | awk -F/ '{print $NF}'`' "
            echo "`date`: Cppcheck OK in folder: '`pwd | awk -F/ '{print $NF}'`' " >> $RESOURCESPATH/succes.log
              let CODECHECKSUCCESCOUNTER++ 

          else
            echo "Cppcheck errors in folder: '`pwd | awk -F/ '{print $NF}'`' "
            echo "`date`: Cppcheck errors in folder: '`pwd | awk -F/ '{print $NF}'`' " >> $RESOURCESPATH/errors.log
            let CODECHECKFAILURECOUNTER++
        fi
  fi
}

function indentFiles
{
if [ $BUILDFAILURECOUNTER -eq 0 ]
    then
      indentFilesRun
    else
      echo "Build errors -> skipping code indenter"
fi  
}

function indentFilesRun
{
  filesuffix="h"
  indentFilesType
  filesuffix="cpp"
  indentFilesType
  filesuffix="ino"
  MAXDEPTH=5
  indentFilesType
}

function indentFilesType
{
  file_list=`find -maxdepth $MAXDEPTH ${1} -name "*.${filesuffix}" -type f`
  for file2indent in $file_list
    do
      echo "Indenting file $file2indent"
      bcpp -fi "$file2indent" -fnc $RESOURCESPATH/"bcpp_indenter.cfg" -fo indentoutput.tmp
      if [ $? -eq 0 ] 
        then
          let INDENTSUCCESCOUNTER++
        else
          let INDENTFAILURECOUNTER++
      fi
      mv indentoutput.tmp "$file2indent"
  done
}

function cleanPreviousBuilds
{
  ls | grep .elf > /dev/null
  if [ $? -eq 0 ] 
    then 
      rm *.elf
  fi

  ls | grep .hex > /dev/null
  if [ $? -eq 0 ] 
    then 
      rm *.hex
  fi

  ls | grep build > /dev/null
  if [ $? -eq 0 ] 
    then 
      rm -rf build
  fi

  ls -lah | grep .sconsign.dblite > /dev/null
  if [ $? -eq 0 ] 
    then 
      rm .sconsign.dblite
  fi

  ls -lah | grep "~" > /dev/null
  if [ $? -eq 0 ] 
    then 
      rm *~
  fi
}

function cleanFiles
{
  for ((i=FIRSTFILE;i<=LASTFILE;i++)); do
    echo ${FILES[i]} | grep build > /dev/null  # don't try a clean in the build folder
    if [ $? -eq 1 ]
        then
          cd ${FILES[i]}
          echo "Cleaning: ${FILES[i]}"
          cleanPreviousBuilds
    fi
    cd $EXAMPLESPATH
  done
}

##################################################################  
# MAIN CODE STARTS HERE                                          #
##################################################################

if [ "$1" = "clean" ] 
  then
    cleanFiles
  else
    CreateLogfiles
    buildFiles
    staticCodeCheck
    indentFiles
    PrintStats
    logStats
fi