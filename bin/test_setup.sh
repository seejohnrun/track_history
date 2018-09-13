#!/bin/bash

# create database
psql -d postgres -c 'drop database if exists track_history;'
psql -d postgres -c 'create database track_history;'
