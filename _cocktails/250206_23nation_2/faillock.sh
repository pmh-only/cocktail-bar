#!/bin/bash

authconfig --enablefaillock --faillockargs="deny=5 fail_interval=300 unlock_time=120" --update
