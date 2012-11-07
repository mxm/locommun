Powwow (working title)
====

Version
-------

We're using Django, a Python web framework. Due to the fact that the Django developers are still porting to python3, we're using python2.7.


Getting started
---------------

1. switch to project root
2. Create database
3. python manage.py runserver
4. open web browser and direct it to http://localhost:8000


Create/Update database
-----------------

1. switch to project root
2. python manage.py syncdb


Admin account
-------------

django admin is at http://localhost:8000/admin

user: admin
pw: powwow


Running tests
-------------

1. Create tests in tests.py
2. python manage.py test
