EyeDiff


Description:

Originally this was designed to allow our pentesters to be able to go through EyeWitness
results automatically, and more quickly identify important targets.

Once the important targets are identified, these pentesters can use shared notes to help
them engage these remote machines, which make them more productive.

If you don't know what EyeWitness is, see:
https://github.com/ChrisTruncer/EyeWitness

Note: EyeWitness can only be run on Kali as of now.


The Tools:

* client.rb - This allows you to identify a single image, or multiple from a directory remotely.
              You can also use this tool to add more references and notes.
* server.rb - The server allows you to look up an image by using the client.rb tool.
* id_image.rb - This allows you to look up an image from your own local database.
* generate_diff.rb - This will generate a diff image between two images.
* resize_image.rb - This allows you to resize an image.
* view_report.rb - This is the report interface for client.rb


Installation:

In your terminal, do:

$ bundle install


Typical Usage:

1. Start the server
2. Start view_report, this will spawn a browser to monitor the image diffing report
3. Run client.rb
4. Look at the image report.

To do:

1. Possible dir traversal
2. Build the database
3. MD for notes (redcarpet)
