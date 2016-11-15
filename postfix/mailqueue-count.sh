#!/bin/bash
mailq | grep -c "^[A-F0-9]"
