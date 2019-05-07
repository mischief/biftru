biftru - "Wind Master"
======

Biftru is a Wi-Fi manager.

Dependencies
------------

Biftru runs on OpenBSD, and only requires LuaJIT. Thus:

	pkg_add -vi luajit

Configuration
-------------

Copy [example.conf](example.conf) to `/etc/biftru.conf` and add your networks to it.

Running
-------------

Run `doas biftru`.

