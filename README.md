# T5DesktopShipyard
An old FlashBuilder app that really did a lot of things well (for the 2010s).

# Overall Structure

As far as I can tell:
- The app source is under /ACS.
- The wrapper might actually be in /T5DesktopShipyard... maybe.
- Supporting library code is in /as3yaml and /lib1541.

# Multiple formats supported
Internally, this app loads and saves in YAML, but it can also import and export in JSON and XML. This allows ship designs to be shared in a variety of formats, which is useful for compatibility with other tools and for users who prefer different data representations. 

In retrospect, it's overkill to support three formats, but it was relatively easy to implement them all.

# Component Structure

Most of the components are built from configuration files; this was done to provide a 
measure of forward-compatibility with future edits of T5. These configurations typically rely on a component factory that manages range, stage, and component type. The result is
a flexible but complex system where multiple picklists are required to define a component
list of items available.

The item editor is generic, containing stage effects and a direct editor for custom
changes. A future improvement would be to design item-specific editors by type, which 
would remove the complexity from the rest of the UI and allow the editor to be more 
centered on the main datagrid.


