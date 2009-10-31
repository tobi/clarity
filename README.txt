Clarity - a log search tool
By John Tajima & Tobi Lütke
---------------------------------------------------------------------------------

Clarity is an eventmachine-based web application that is used at Shopify to
search log files on production servers.

We wrote Clarity to allow authorized users to use a simple interface to look
through the various log files in our server farm, without requiring access to
production servers.

Clarity requires eventmachine and eventmachine/evma_httpserver.

  sudo gem install eventmachine eventmachine_httpserver



Changelog
---------

Oct 31, 2009  - Added command line interface



Sept 12, 2009 - Search terms are now optional. If no search terms are submitted, 
                uses (gz)cat instead of (z)grep or tail
              - Refactoring of commands, parsers, view templates
              - Added tests

