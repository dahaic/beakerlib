# Beah - Test harness. Part of Beaker project.
#
# Copyright (C) 2009 Marian Csontos <mcsontos@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

from setuptools import setup, find_packages
from time import strftime
import os
import os.path
import glob

# FIXME: Works only if setup.py runs from same directory it is located in!
def glob_(*patterns):
    answ = []
    for pattern in patterns:
        answ += glob.glob(pattern)
    answ = list([file for file in answ if not os.path.isdir(file)])
    print "glob_(%r) -> %r" % (patterns, answ)
    return answ

def glob_to(prefix, dirs):
    return list([(prefix+'/'+dir, glob_(dir+'/*')) for dir in dirs])

more_data_files = glob_to('share/beah', [
    'examples/tasks',
    'examples/tests',
    'examples/tests/rhtsex',
    'examples/tests/testargs',
    #'tests', # FIXME: add some tests here!
    'doc',
    ])

setup(

    name="beah",
    version="0.1.a1%s" % os.environ.get('BEAH_DEV', strftime(".dev%Y%m%d%H%M")),

    # FIXME: Find out about real requirements - packages, versions.
    install_requires=['Twisted_Core >= 0',
                      'Twisted_Web >= 0',
                      'zope.interface >= 0',
                      'simplejson >= 0'],
    # NOTE: these can be downloaded from pypi:
    #dependency_links=['http://twistedmatrix.com/trac/wiki/Downloads',
    #                      'http://pypi.python.org/pypi/Twisted',
    #                      'http://zope.org/Products/ZopeInterface',
    #                      'http://pypi.python.org/pypi/zope.interface',
    #                      'http://pypi.python.org/pypi/simplejson'],
    # Other requirements: PyXML, python-fpconst, SOAPpy, python-zope-filesystem

    packages=find_packages(),
    py_modules=['beahlib'],
    #package_dir={'':'.'},

    # FIXME: move this to beah.bin(?)
    scripts=['bin/beat_tap_filter'], # + ['tests/*'],

    namespace_packages=['beah'],

    data_files=[
        ('/etc', ['beah.conf', 'beah_beaker.conf']),
        ('/etc/init.d', ['init.d/beah-srv', 'init.d/beah-beaker-backend']),
        ] + more_data_files,
    #package_data={
    #    '': ['beah.conf', 'beah_beaker.conf'],
    #    'init.d': ['beah-srv', 'beah-beaker-backend'],
    #},

    entry_points={
        'console_scripts': (
            'beah-srv = beah.bin.srv:main',
            'beah = beah.bin.cli:main',
            'beah-cmd-backend = beah.bin.cmd_backend:main',
            'beah-out-backend = beah.bin.out_backend:main',
            'beah-beaker-backend = beah.backends.beakerlc:main',
        ),
    },

    license="GPL",
    keywords="test testing harness beaker twisted qa",
    url="http://fedorahosted.org/beaker/wiki",
    author="Marian Csontos",
    author_email="mcsontos@redhat.com",
    description="Beah - Beaker Test Harness. Part of Beaker project - http://fedorahosted.org/beaker/wiki.",
    long_description="""\
Beah - Beaker Test Harness.

Ultimate Test Harness, with goal to serve any tests and any test scheduler
tools. Harness consist of a server and two kinds of clients - backends and
tasks.

Backends issue commands to Server and process events from tasks.
Tasks are mostly events producers.

Powered by Twisted.
""",
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Environment :: Console',
        'Environment :: No Input/Output (Daemon)',
        'Framework :: Twisted',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU General Public License (GPL)',
        'Operating System :: POSIX :: Linux', # FIXME: Wishing 'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Topic :: Software Development :: Testing',
    ],
)
