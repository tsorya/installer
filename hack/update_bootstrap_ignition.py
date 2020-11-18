#!/usr/bin/python3
# -*- coding: utf-8 -*-

import json

hosts = {"overwrite": True, "path": "/etc/hosts", "user": {"name": "root"}, "contents": {
    "source": "data:text/plain;charset=utf-8;base64,MTkyLjE2OC4xNDAuMTAgYXBpLWludC50ZXN0LWNsdXN0ZXIucmVkaGF0LmNvbQoxMjcuMC4wLjEgICBsb2NhbGhvc3QgbG9jYWxob3N0LmxvY2FsZG9tYWluIGxvY2FsaG9zdDQgbG9jYWxob3N0NC5sb2NhbGRvbWFpbjQKOjoxICAgICAgICAgbG9jYWxob3N0IGxvY2FsaG9zdC5sb2NhbGRvbWFpbiBsb2NhbGhvc3Q2IGxvY2FsaG9zdDYubG9jYWxkb21haW42Cg=="},
         "mode": 420}

with open("mydir/bootstrap.ign") as _file:
    ign = json.load(_file)

ign["storage"]["files"].append(hosts)
with open("mydir/bootstrap.ign", "w") as _file:
    json.dump(ign, _file)

