# EyeDiff

## Description

EyeDiff is an **experimental** tool to diff screenshots.

Originally this was designed to allow our pentesters to be able to go through EyeWitness
results, and identify important targets automatically.

Once the important targets have been identified, the pentesters can use shared notes to help
them engage these remote machines. Ideally, notes may allow these people to perform on a
similar quality level, and hopefully more productive.

If you don't know what EyeWitness is, see:
https://github.com/ChrisTruncer/EyeWitness

Note: EyeWitness can only be run on Kali as of now.

## The Tools

* client.rb - This allows you to identify a single image, or multiple from a directory remotely.
              You can also use this tool to add more references and notes.
* server.rb - The server allows you to look up an image by using the client.rb tool.
* id_image.rb - This allows you to look up an image from your own local database.
* view_report.sh - This is the report interface for client.rb
* clear_local_report.sh - Clears the report.


## Wiki

To learn about this tool, including installation and usage, please visit the [wiki page](https://github.com/wchen-r7/EyeDiff/wiki).
