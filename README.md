pygd-vim
========

A better "go to declaration" for Python files in vim


What is this?
-------------

pygd-vim replaces vim's built-in `gd` command - 'go to declaration' - with an implementation 
that uses Python's Abstract Syntax Tree to understand the meaning of the code and go to the 
place that the identifier actually was declared.

See [my blog](http://blog.roseman.org.uk/2013/12/17/a-better-vim-go-to-declaration-with-asts/)
for motivation and an explanation.


Installation
------------

pygd requires [pyflakes](https://github.com/pyflakes/pyflakes), as it builds on that project's
AST visitor code. pyflakes is included as a submodule, so will be automatically installed 
alongside pygd.

The best way of installing pygd is via Vundle. From inside vim, just do:

    :BundleInstall 'danielroseman/pygd-vim'
    
then add this line to your `.vimrc`:

    Bundle 'danielroseman/pygd-vim'
    
Alternatively, you can clone the repo and move `pygd.vim` and the `pyflakes` subdirectory
into your `ftplugin/python` directory.


Usage
-----

Just place the cursor over an identifier - variable, function or class - and press `gd`, and
you will be moved to the place that that identifier was defined within the current scope.
