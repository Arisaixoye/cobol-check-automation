#!/bin/bash

# mainframe_operations.sh

echo "Setting environment..."

export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

java -version

# Username from GitHub Secrets
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

echo "Using user: $LOWERCASE_USERNAME"

cd cobolcheck || exit 1
echo "Changed to $(pwd)"
ls -al

chmod +x cobolcheck

cd scripts
chmod +x linux_gnucobol_run_tests
cd ..

run_cobolcheck () {

  program=$1
  echo "Running COBOL Check for $program"

  ./cobolcheck -p $program || true

  if [ -f "CC##99.CBL" ]; then
      cp CC##99.CBL "//'${ZOWE_USERNAME}.CBL(${program})'"
      echo "Copied COBOL output"
  else
      echo "No CC##99.CBL generated"
  fi

  if [ -f "${program}.JCL" ]; then
      cp ${program}.JCL "//'${ZOWE_USERNAME}.JCL(${program})'"
      echo "Copied JCL"
  fi
}

for program in NUMBERS EMPPAY DEPTPAY
do
  run_cobolcheck $program
done

echo "Mainframe operations completed"
