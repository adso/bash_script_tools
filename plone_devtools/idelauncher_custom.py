#!/usr/bin/python2.4
"""

    Through-the-IDE launch script for Eclipse and Plone 3.1.x.

    Assume default builtout folder layout with Omelette. Drop this script to instance/bin folder. Use instance folder as the
    working folder when running the script.

    Related tutorial: http://plone.org/documentation/how-to/developing-plone-with-eclipse-ide

    Omelette: http://theploneblog.org/blog/archive/2008/03/10/collective-recipe-omelette-for-more-navigable-eggs

    Please visit us at http://www.redinnovation.com
    
    Use following arguments:
    
        To start Plone server.
        
            idelauncher.py (no parameters)
            
        To run all tests in a product:
        
            test -s plone.app.contentrules 
            
        To run a specific test case:
        
            test -s plone.app.contentrules -t TestWorkflowTriggering (py modulename without extension)
            
    Zope does not give an error if the product/case is missing, but runs 0 tests.

"""

__author__ = "Mikko Ohtamaa <mikko@redinnovation.com>"
__docformat__ = "epytext"
__license__ = "3-clause BSD"
__copyright__ = "2008 Red Innovation Ltd."
__version__ = "1.1"

import os
import sys

# Guess our working directory based on the location of this file
module = sys.modules[__name__]
PROJECT_FOLDER=os.path.join(os.path.dirname(module.__file__), "..")

# Set up Zope environment variables
os.environ["ZOPE_HOME"]=os.path.join(PROJECT_FOLDER, "parts/zope2")
os.environ["INSTANCE_HOME"]=os.path.join(PROJECT_FOLDER, "parts/instance")
os.environ["CONFIG_FILE"]=os.path.join(PROJECT_FOLDER, "parts/instance/etc/zope.conf")
os.environ["SOFTWARE_HOME"]=os.path.join(PROJECT_FOLDER, "parts/zope2/lib/python")

# List all eggs in PYTHONPATH
# PYTHONPATH="/home/moo/workspace/PloneInstance/eggs/elementtree-1.2.7_20070827_preview-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/archetypes.kss-1.4-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/borg.localrole-2.0.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/kss.core-1.4.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/kss.demo-1.4.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.content-1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.contentmenu-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.contentrules-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.controlpanel-1.1.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.customerize-1.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.form-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.i18n-1.0.4-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.iterate-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.kss-1.4.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.layout-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.linkintegrity-1.0.8-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.openid-1.0.3-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.portlets-1.1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.redirector-1.0.7-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.viewletmanager-1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.vocabularies-1.0.4-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.app.workflow-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.browserlayer-1.0.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.contentrules-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.fieldsets-1.0.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.i18n-1.0.5-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.intelligenttext-1.0.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.keyring-1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.locking-1.0.5-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.memoize-1.0.4-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.openid-1.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.portlets-1.1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.protect-1.1-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.session-1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.theme-1.0-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.portlet.collection-1.1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/plone.portlet.static-1.1.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/wicked-1.1.6-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/five.customerize-0.2-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/five.localsitemanager-0.3-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/setuptools-0.6c8-py2.4.egg:/home/moo/workspace/PloneInstance/eggs/python_openid-2.0.1-py2.4.egg:$SOFTWARE_HOME:$PYTHONPATH"

# Omelette and other path completion goodies must not exist in sys.path when launching the instance.
# PyDev inserts it there for import autocompletion, but Plone
# chokes if it finds duplicate imports and other Omelette
# quirkies during start up
sys.path = [ x for x in sys.path if "python2.4" in x ]

# Use instance script to initialize PYTHONPATH
instance_script = open(os.path.join(PROJECT_FOLDER, "bin", "instance"), "rt")
data = ""
for line in instance_script:
    if line.startswith("if __name__ =="):
        # A hack to evaluate sys.path imports from instance script
        break
    data += line + "\n"

instance_script.close()

exec(data, globals())

if len(sys.argv) > 1 and sys.argv[1] == "test":    
    # Start Zope test runner.
    # We can invoke this using zope2instance.ctl, since its do_test()
    # does not fork a new process    
    
    old_arg = sys.argv[:]
    sys.argv = [ "ctl.py", "-C", os.environ["CONFIG_FILE"], "test" ]
    sys.argv += old_arg[2:]
    
    from plone.recipe.zope2instance import ctl
    ctl.main(sys.argv[1:])
else:
    # Start zope instance as a web server
    # Zope launcher module
    ZOPE_RUN=os.path.join(os.environ["SOFTWARE_HOME"], "Zope2/Startup/run.py")

    # Tinker with command-line to emulate normal Zope launch
    sys.argv = [ ZOPE_RUN, "-C", os.environ["CONFIG_FILE"], "-X", "debug-mode=on"]

    # Instead of spawning zopectl and Zope in another process, execute Plone in the context of this Python interpreter
    # to have pdb control over the code
    execfile(ZOPE_RUN)

