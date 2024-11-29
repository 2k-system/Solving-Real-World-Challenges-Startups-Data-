#!/bin/bash

# Author: Pranali Dhawde
# Created: 25th Nov 2024
# Last Modified: 25th Nov 2024

# Description:
# This script performs the following tasks:
# Ensures that the HDFS directory exists; if not, creates it.
# Uploades the CSV file to the HDFS File System.
# Executes a Hive script (create.hive) to set up data.
# If the Hive script fails, uploads a CSV file to HDFS and tries the script again.
# Executes another Hive script (show.hive) and handles failures by retrying the script directly.

# Usage:
# ./list.sh

# Path to the first Hive script
HIVE_SCRIPT_1="create.hive"    

# Path to the second Hive script
HIVE_SCRIPT_2="show.hive"

# CSV file to be uploaded if Hive script fails
CSV_FILE="startups.csv"         

# HDFS directory path to store the CSV file
HDFS_PATH="/user/talentum/assignment_2"      

# Check if the HDFS directory exists. If not, creating it.
hdfs dfs -test -d "$HDFS_PATH"
if [ $? -ne 0 ]; then
    echo "Directory $HDFS_PATH does not exist. Creating it..."
    hdfs dfs -mkdir -p "$HDFS_PATH"
    
    if [ $? -eq 0 ]; then
        echo "Directory created successfully."
    else
        echo "Failed to create directory $HDFS_PATH. Exiting..."
        exit 1
    fi
else
    echo "Directory $HDFS_PATH already exists."
fi

# Check if the CSV file exists before uploading
if [ -f "$CSV_FILE" ]; then
    hdfs dfs -put "$CSV_FILE" "$HDFS_PATH"
    if [ $? -eq 0 ]; then
        echo "CSV file uploaded to HDFS successfully."
    else
        echo "Failed to upload CSV file to HDFS. Exiting..."
        exit 1
    fi
else
    echo "CSV file '$CSV_FILE' not found. Exiting..."
    exit 1
fi


# Executing the first Hive script (create.hive)
hive -f "$HIVE_SCRIPT_1"
HIVE_STATUS_1=$?

# If the first Hive script fails, re-uploading the CSV file to HDFS and re-running the script.
if [ $HIVE_STATUS_1 -ne 0 ]; then
    echo "Hive script ($HIVE_SCRIPT_1) failed. Attempting to upload CSV file to HDFS..."

    # Check if the CSV file exists before uploading
    if [ -f "$CSV_FILE" ]; then
        hdfs dfs -put "$CSV_FILE" "$HDFS_PATH"
        if [ $? -eq 0 ]; then
            echo "CSV file uploaded to HDFS successfully."
        else
            echo "Failed to upload CSV file to HDFS. Exiting..."
            exit 1
        fi
    else
        echo "CSV file '$CSV_FILE' not found. Exiting..."
        exit 1
    fi
    
    # Retry executing the Hive script after file upload
    hive -f "$HIVE_SCRIPT_1"
    HIVE_STATUS_1=$?
    if [ $HIVE_STATUS_1 -eq 0 ]; then
        echo "Hive script ($HIVE_SCRIPT_1) executed successfully after file upload."
    else
        echo "Hive script ($HIVE_SCRIPT_1) execution failed again after file upload. Exiting..."
        exit 1
    fi
else
    echo "Hive script ($HIVE_SCRIPT_1) executed successfully."
fi

# Executing the second Hive script (show.hive)
hive -f "$HIVE_SCRIPT_2"
HIVE_STATUS_2=$?

# If the second Hive script fails, retry executing the script
if [ $HIVE_STATUS_2 -ne 0 ]; then
    echo "Hive script ($HIVE_SCRIPT_2) failed. Retrying script execution..."
    # Retry executing the Hive script
    hive -f "$HIVE_SCRIPT_2"
    HIVE_STATUS_2=$?
    if [ $HIVE_STATUS_2 -eq 0 ]; then
        echo "Hive script ($HIVE_SCRIPT_2) executed successfully after retry."
    else
        echo "Hive script ($HIVE_SCRIPT_2) execution failed again. Exiting..."
        exit 1
    fi
else
    echo "Hive script ($HIVE_SCRIPT_2) executed successfully."
fi

# End of script

