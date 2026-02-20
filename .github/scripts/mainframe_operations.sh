#!/bin/bash
set -u

# mainframe_operations.sh

# ----- Config -----
ZOWE_USERNAME="Z89440"   # Replace with the actual username (or set via secrets/env)
CBL_PDS="${ZOWE_USERNAME}.CBL"
JCL_PDS="${ZOWE_USERNAME}.JCL"

# CobolCheck paths
COBOLCHECK_DIR="cobol-check"
COBOLCHECK_JAR="bin/cobol-check-0.2.19.jar"
GEN_CBL_PATH="testruns/CC##99.CBL"

# Convert username to lowercase for USS paths if needed
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

# ----- Environment (Runner already has Java; keep this harmless) -----
export PATH=$PATH:/usr/lpp/java/J8.0_64/bin
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$PATH:/usr/lpp/zowe/cli/node/bin

echo "Java version:"
java -version

echo "Working directory before cd: $(pwd)"

# ----- Go to cobol-check dir -----
cd "$COBOLCHECK_DIR"
echo "Changed to $(pwd)"
ls -al

# ----- Ensure scripts are executable -----
chmod +x "scripts/linux_gnucobol_run_tests"
echo "Made linux_gnucobol_run_tests executable"

# NOTE: You do NOT need chmod +x on a .jar
# chmod +x "$COBOLCHECK_JAR"

# ----- Ensure PDS exist (optional but recommended) -----
echo "Ensuring PDS exist: $CBL_PDS and $JCL_PDS"
zowe zos-files create data-set-partitioned "$CBL_PDS" >/dev/null 2>&1 || true
zowe zos-files create data-set-partitioned "$JCL_PDS" >/dev/null 2>&1 || true

# ----- Function -----
run_cobolcheck() {
    local program="$1"
    echo "==============================================="
    echo "Running cobolcheck for $program"
    echo "-----------------------------------------------"

    # Run CobolCheck (do not hard-fail the whole script here)
    java -jar "$COBOLCHECK_JAR" -p "$program" || true
    echo "Cobolcheck execution completed for $program (exceptions may have occurred)"

    # Show testruns directory to avoid "not found" confusion
    echo "Listing testruns directory:"
    ls -al testruns || true

    # Upload generated COBOL test program to PDS member
    if [ -f "$GEN_CBL_PATH" ]; then
        echo "Found generated COBOL file: $GEN_CBL_PATH"
        echo "Uploading to ${CBL_PDS}(${program}) ..."
        if zowe zos-files upload file-to-data-set "$GEN_CBL_PATH" "${CBL_PDS}(${program})"; then
            echo "Uploaded $GEN_CBL_PATH to ${CBL_PDS}(${program})"
        else
            echo "Failed to upload $GEN_CBL_PATH to ${CBL_PDS}(${program})"
        fi
    else
        echo "Generated COBOL file not found at: $GEN_CBL_PATH"
    fi

    # Upload JCL to PDS member
    if [ -f "${program}.JCL" ]; then
        echo "Found JCL file: ${program}.JCL"
        echo "Uploading to ${JCL_PDS}(${program}) ..."
        if zowe zos-files upload file-to-data-set "${program}.JCL" "${JCL_PDS}(${program})"; then
            echo "Uploaded ${program}.JCL to ${JCL_PDS}(${program})"
        else
            echo "Failed to upload ${program}.JCL to ${JCL_PDS}(${program})"
        fi
    else
        echo "${program}.JCL not found"
    fi
}

# ----- Run for each program -----
for program in NUMBERS EMPPAY DEPTPAY; do
    run_cobolcheck "$program"
done

echo "==============================================="
echo "Mainframe operations completed"

