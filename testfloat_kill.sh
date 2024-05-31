#!/bin/bash

ps aux | grep 'mktests_testfloat_mod_aux.sh' | awk '{print $2}' | sudo xargs kill -9