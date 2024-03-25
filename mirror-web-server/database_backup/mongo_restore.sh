#!/bin/bash
echo "Trying to execute mongorestore"
mongorestore  --uri="mongodb://root:example@localhost:27017/themirror?retryWrites=true&w=majority&authSource=admin" -d themirror --archive=/database_dump/dump.archive