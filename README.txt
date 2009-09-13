Clarity - a log search tool
By John Tajima & Tobi Lutke
---------------------------------------------------------------------------------

Clarity is an eventmachine-based web application that is used at Shopify to
search log files on production servers.

We wrote Clarity to allow authorized users to use a simple interface to look
through the various log files in our server farm, without requiring access to
production servers.

Clarity requires eventmachine and eventmachine/evma_httpserver.

If installing on Snow Leopard, make sure you install the
latest evma_httpserver by building gem from source:

> git clone git://github.com/eventmachine/evma_httpserver
> cd evma_httpserver
> gem build eventmachine_httpserver.gemspec 






Changelog
---------

Sept 12, 2009 - Search terms are now optional. If no search terms are submitted, 
                uses (gz)cat instead of (z)grep or tail
              - Refactoring of commands, parsers, view templates
              - Added tests

