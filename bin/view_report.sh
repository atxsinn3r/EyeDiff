#!/bin/bash

open http://localhost:8181/index.html
ruby -run -e httpd ../report -p 8181
