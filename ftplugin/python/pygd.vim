" Copyright 2013 Google Inc. All Rights Reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.

if exists("b:did_pygd_plugin")
    finish " only load once
else
    let b:did_pygd_plugin = 1
endif

if !exists('g:pygd_builtins')
    let g:pygd_builtins = []
endif

if !exists("b:did_pygd_init")
    python << EOF
import vim
import os.path
import sys

# get the directory this script is in: the pyflakes python module should be
# installed there.
scriptdir = os.path.join(os.path.dirname(vim.eval('expand("<sfile>")')),
                         'pyflakes')
sys.path.insert(0, scriptdir)
import ast
from pyflakes import checker

class GDChecker(checker.Checker):
    """An AST visitor that finds the definition of a target object."""

    def __init__(self, tree, lineno, name, filename='(none)'):
        """Initialize the checker and search for the target.

        Args:
          tree: an ast.Node representing the root of a tree.
          lineno: int, the line number of the object to be searched for.
          name: string, the identifier of the object.
          filename: optional string representing the module's file name.
        """
        self.name = name
        self.lineno = lineno
        self.target = None
        self.targetScope = None
        super(GDChecker, self).__init__(tree, filename)

    def getScope(self, target):
        """
        Find the target's scope.

        Given an ast.Node representing the target object, travel up the stack of
        scopes to find the node that originally defined the object.
        """
        if target in self.scope:
            return self.scope[target]
        for scope in self.scopeStack[-2::-1]:
            if target in scope:
                return scope[target]
        # Was not found: this is probably an attribute declared in another 
        # method, or perhaps an undefined reference.
        print 'Sorry, no definition found.'

    def handleChildren(self, tree):
        """
        Check if the `attr` of the current node matches target before iterating
        through child nodes.
        """
        if (hasattr(tree, 'lineno') and tree.lineno == self.lineno
              and hasattr(tree, 'attr') and tree.attr == self.name):
            self.target = tree
            scope = self.getScope(tree.attr)
            self.targetScope = scope

        for node in checker.iter_child_nodes(tree):
            self.handleNode(node, tree)

    def NAME(self, node):
        """
        Visitor function for `Name` nodes: check if it matches target before
        handling node.
        """
        super(GDChecker, self).NAME(node)
        if node.lineno == self.lineno and node.id == self.name:
            self.target = node
            self.targetScope = self.getScope(node.id)


# pyflakes Checker sets a lot of names explicitly to point at its handleChildren
# method. We need to re-point them to our overridden version.
for x in dir(checker.Checker):
    obj = getattr(checker.Checker, x)
    if obj == checker.Checker.handleChildren:
        setattr(GDChecker, x, GDChecker.handleChildren)


def goto_definition(buffer):
    """
    Main function called by vim.

    Parses the buffer into an AST, then uses the Checker to find the definition
    of the identifier under the cursor, and moves the cursor to the position of
    that definition.
    """

    filename = buffer.name
    contents = '\n'.join(buffer[:]) + '\n'

    vimenc = vim.eval('&encoding')
    if vimenc:
        contents = contents.decode(vimenc)

    builtins = []
    try:
        builtins = eval(vim.eval('string(g:pygd_builtins)'))
    except Exception:
        pass

    try:
        tree = ast.parse(contents, filename)
    except:
        print 'Error while parsing, could not continue.'
    word = vim.eval('expand("<cword>")')
    row, col = vim.current.window.cursor

    parser = GDChecker(tree, row, word, filename)
    scope = parser.targetScope

    if scope:
        source = parser.targetScope.source
        # If it's a function arg set, find the relevant one.
        if isinstance(scope, checker.Argument):
            for arg in scope.source.args.args:
                if arg.id == word:
                    source = arg
        vim.current.window.cursor = (source.lineno, source.col_offset)
        # Some statements (eg from foo import bar) don't have child nodes for
        # the sub-elements, so search the line until we find the actual word.
        target_word = vim.eval('expand("<cword>")')
        if target_word != word:
            line = vim.current.line
            vim.current.window.cursor = (source.lineno, line.find(word))


EOF
    let b:did_pygd_init = 1
endif

if !exists("*s:RunPygd")
    function s:RunPygd()
        python << EOF
goto_definition(vim.current.buffer)
EOF
    endfunction
endif

if !exists(":RunPygd")
    command RunPygd :call s:RunPygd()
endif

noremap <buffer><silent> gd :RunPygd<CR>
