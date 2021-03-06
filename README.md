GroupManager
============

GroupManager application is reponsible for maintaining group membership and
topology information. The main module is [GroupManager](lib/group_manager.ex).

The application is based on two core services. [Chatter](https://github.com/dbeck/chatter_ex) is responsible for communication between peers. It favours UDP multicats over direct TCP communication and discovers networked nodes automatically.

The other main component is [TopologyDB](lib/group_manager/topology_db.ex) which maintains the list of groups and their topology in an ETS table.

License
=======

Copyright (c) 2015-2016 [David Beck](http://dbeck.github.io)

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
