---
title: 'pangitive: README'
---
<!-- vim: set syntax=markdown: -->

# Info

Pangitive is a fork of [fugitive](http://shebang.ws/fugitive-readme.html), a blog engine running on top of git using hooks to generate static html pages and thus having only git as dependency.
Pangitive adds one dependency: pandoc, a general marker converter written in Haskell.

In its hooks, pangitive uses only standard UNIX® tools that are included in the GNU core-utils package, plus sh as script interpreter.
There is no dependencies like Rack, Heroku, Node.js or whatever Ruby gems you can think of.
No configuration files.
Few metadata in your articles (none mandatory, except maybe for the title).

This documentation file is also based on the documentation of fugitive ([copyleft](http://www.gnu.org/copyleft/copyleft.html) [Pablo <span class="sc">Rauzy</span>](http://pablo.rauzy.name/)).


## Pangitive VS fugitive

A foreword before you start to install: you can see pangitive as pandoc with the hooks of fugitive; or as an extension of fugitive to the capacities of pandoc.
Honestly, if you are not interested in pandoc's advanced configuration options (which means: you should read the doc), just use fugitive and set pandoc as your preprocessor with something like:<br />
`git config fugitive.preproc "pandoc"`<br />
Actually this is what I started with.
Now here are some feature that I could get by working out a better integration of pandoc:

- automatic syntax highlighting;
- automatic section numbering (available through CSS in fugitive);
- additional metadata, if needed;
- easy LaTeX rendering _via_ MathML;
- JavaScript email obfuscation;
- and of course, all features concerning markup conversion; for my part, it means Markdown and the numerous extensions of this language supported by pandoc (footnote, tables).

Additionally, pangitive enables writing static pages (such as an “about” page for instance) that will not be included into RSS feed or blog archives.
The injection of article contents into the template is performed by Haskell and no more by shell tools, slightly reducing the number of spawn processes.
The biggest drawback is of course that you need to install pandoc, both on your development machine and on the one where you will host your blog.

# Install

## Install pandoc

You need to install pandoc both on the machine you use to write your blog, and on the one hosting your blog.
So far pandoc version 1.12.4.2 is known to work (you guessed it, that's the one I used for developing pangitive), please tell me if you face issues with other versions.
Pandoc should be available in most package repositories, check those of your favorite distribution.

And read the doc: `man pandoc`, `man pandoc_markdown`. You will learn a lot about this software capabilities.

## Build

If you want to build pangitive from the source, clone the git repository:<br />
`git clone https://github.com/Qeole/pangitive pangitive`<br />
Then change to the newly created directory: `cd pangitive`, and run the build script: `./build.sh`.
This will generate an executable file “pangitive”, which you can use to create your blog.

## Create a blog

There are two install modes for pangitive: local and remote.
The local mode should be used to install a repository where you edit your blog, and the remote mode for a repository to which you are going to push to publish your blog.
The local mode can also be used to publish if you edit your files directly on your server.

To create your blog run, the command:<br />
`pangitive --install-mode <dir>`,<br />
where *mode* is either “local” or “remote”.
This will create a git repository with appropriate hooks, config and files in `<dir>`.
If `<dir>` is not specified, then the current working directory is used.

<span class="important">Once you have installed your blog you need to set the *blog-url* parameter in your git configuration.
See [configuration](#configuration) for details.</span>

# Configuration

All these settings are in the “pangitive” section of the git config.
You can change them with the command `git config pangitive.parameter value`, where *parameter* is one of the following:

**blog-url**<br />
This is the public URL of the generated blog.
**You need to set it** as soon as possible since it is required for the RSS feed (and used in the default footer template).<br />
**blog-owner**<br />
This is the name of the blog owner.
Defaults to the Git user name of the user creating the blog.<br />
**blog-title**<br />
This is the title of your blog.
Defaults to “*blog-owner*'s blog”.<br />
**public-dir**(1)<br />
This is the path to the directory that will contain the generated HTML files.
Default value is "\_public". You could set it to "\_public/blog" for instance if you want to have have a website in "\_public" and your blog in "/blog".<br />
**articles-dir**(1)<br />
This is the path where pangitive will look for published articles.
Default value is "\_articles".<br />
**pages-dir**(1)<br />
This is the path where pangitive will look for published pages.
Those pages are similar to articles, but they will not have any “Previous”/“Next” links and will not appear either in RSS feed or blog archives.
Do not forget to link to them from somewhere else if you want your readers to find them.
Default value is "\_pages".<br />
**templates-dir**(1)<br />
This is the path where pangitive will look for templates files.
Default value is "\_templates".<br />
**pandoc**<br />
The path to the pandoc binary to use.
It is filled by default with the result of `which pandoc` command.<br />
**pandoc-options**<br />
Options to provide to pandoc to generate HTML files.
Default value is:<br />
`--from=markdown --to=html5 --smart --css=pangitive.css --number-sections`<br />
Of course you can change it.
Of course you should read pandoc documentation.

\(1\) Those paths are relative to the root of the Git repository, and they must be in it and must not start with “.” neither have a “/” at the end.
Example: “dir/subdir” is valid but “./dir/subdir” and “dir/subdir/” are not.

# Usage

## General use

Articles you want to publish should be a file without the .html extension in the *articles-dir* directory (see [configuration](#configuration)).
The first line of the file will be used as a title and the rest of the file as the content of the article.

By default there is a "\_drafts" directory in which you can put articles you are writing and you want to version control in your Git repository but you do not want to publish yet.

When you commit change to a pangitive Git repository, the post-commit hook looks in the *articles-dir* and *pages-dir* directories (see [configuration](#configuration)) for newly added articles, modified articles and deleted ones.
Then it does the following things:

-   it generates static HTML files for newly added articles and pages,
-   it regenerates static HTML files for modified articles and pages,
-   it deletes static HTML files for deleted articles and pages,
-   it regenerates static HTML files for articles (not pages) that are just before and after newly added and deleted articles (this to maintain the “previous” and “next” links alive),
-   it regenerates the archives.html, tags.html, and feed.xml files,
-   and finally it copies the static HTML file of the last article to “index.html”.

If a change happens in the *templates-dir* directory (see [configuration](#configuration)), then static HTML files for everything is regenerated to make the change effective.

All generated files are created in the *public-dir* directory (see [configuration](#configuration)).

When you push to a remote repository installed with pangitive, the same thing will happen but instead of looking only at the last commit, the hook will analyse every changes since the last push and then (re)generate HTML files accordingly.

<span class="warning">Do not create an article or page file named “archives”.
Do not create an article or page file named “index”. They would overwrite the index or archives created by pangitive.</span>

## Pangitive feature: previewing without commiting

Contrary to fugitive, pangitive is able to generate a preview of the articles without committing (because I was tired of committing all the time to check rendering).
It comes with the “preview” script, which regenerates HTML files for modified articles and pages without committing.
Some notes about its usage:

- running `./preview` regenerates HTML files for articles and pages that have been modified since last commit (all files if templates were modified), but the archives and RSS feed are **NOT** regenerated (you should commit for this);
- running `./preview -a` (or alternatively `./preview --all`) does the same, plus it regenerates archives and RSS feed;
- the script only checks files in the Git tree: to preview a newly (non-committed) file, add it to Git index first with _e.g._ `git add _articles/my_new_article` (this is not committing, you can still revert this later with `git reset _articles/my_new_article`);
- **previewing is not publishing**: there will be broken “Previous” and “Next” links, as well as broken author names and emails. This is expected. That's because previewing will not have access to data related to the commit registering the changes (whereas Git hooks obviously have access to this). Normally, everything should be set correctly when you commit your changes;
- the preview script embeds the same code as Git post-commit and post-receive hooks (but has no `--help` feature, so you will just have to read the code).

## Template system

The better explanation about the templates system is to see what the default templates looks like.

Fugitive includes macros in XML preprocessor syntax in the templates.o
Pangitive dropped this system in favor of pandoc templating system.
Did I mention that you should read pandoc documentation already?

Pandoc performs variable rendering, obtained either from command line (pangitive makes an extensive use of variable definitions in the hooks) or from metadata in YAML- or in JSON-formatted blocks inside the article files.
Inside templates, variable name besides dollars (like this: `$varname$`) are expended---if possible---by pandoc.

In addition to variable rendering, pandoc also has conditional and a foreach loop constructs.
This is an example of the conditional statement:

    $if(varname)$
      Template code which is ignored if var value is empty,
      and which typically includes $varname$.
    $endif$

The syntax of the conditional construct is as follows:

    $for(varname)$
      Template code which is repeated for each value of varname,
      and which typically includes $varname$.
    $enfor$

### Metadata block

Metadata can be added to article Markdown files contents inside a YAML or a JSON block (see `man pandoc_markdown` for details).
You should set at least a title; the date will be taken from the commit data with Git hooks.
For an example, here are the first lines that were used to generate this article:

    ---
    title: 'pangitive: README'
    ---

When metadata contains a colon (“:”), it needs to be enclosed into single quotes to prevent the parser to return a “source not found” error.

### Generic variables

The following variables are available everywhere:

**page\_title**<br />
Its value is “archives” in the archives.html template, “feed” in the feed.xml template, or the article or page title in the article.html template.<br />
**blog\_url**<br />
The *blog-url* value in the "pangitive" section of the Git configuration (see [configuration](#configuration)).<br />
**blog\_owner**<br />
The *blog-owner* value in the "pangitive" section of the Git configuration (see [configuration](#configuration)).<br />
**blog\_title**<br />
The *blog-title* value in the "pangitive" section of the Git configuration (see [configuration](#configuration)).<br />
**blog\_years**<br />
Used to set years relative to copyright in the default template. In the form “20XX−20YY”, where “20XX” is the year of the first commit and “20YY” the year of the last commit.<br />
**commit\_Hash**<br />
Its value is the hash corresponding to the last commit that provoked the (re)generation of the file.<br />
**commit\_hash**<br />
Its value is the short hash (the seven first digit of the hash) corresponding to the last commit that provoked the (re)generation of the file.<br />
**commit\_author**<br />
Its value is the name of the author of the last commit that provoked the (re)generation of the file.<br />
**commit\_author\_email**<br />
Its value is the email of the author of the last commit that provoked the (re)generation of the file (see [email obfuscation](#email-obfuscation)).<br />
**commit\_date**<br />
Its value is the date and time of the last commit that provoked the (re)generation of the file.<br />
**commit\_date\_html5**<br />
Its value is the date and time of the last commit that provoked the (re)generation of the file, but in an HTML 5 `<time>` compliant format.<br />
**commit\_date\_day**<br />
Its value is the date (day) of the last commit that provoked the (re)generation of the file.<br />
**commit\_date\_time**<br />
Its value is the time of the last commit that provoked the (re)generation of the file.<br />
**commit\_timestamp**<br />
Its value is the UNIX timestamp of the last commit that provoked the (re)generation of the file.<br />
**commit\_comment**<br />
Its value is the comment (first line of the commit message) of the last commit that provoked the (re)generation of the file.<br />
**commit\_slug**<br />
Its value is the comment of the last commit that provoked the (re)generation of the file but formatted to be file name friendly.<br />
**commit\_body**<br />
Its value is the body (the rest of the commit message) of the last commit that provoked the (re)generation of the file.<br />
**body**<br />
Generated content.

### Variables specific to the article.html template:

**article\_title**<br />
   Its value is the title of the article (see [metadata block](#metadata-block)).<br />
**article\_file**<br />
Its value is the file name of the article (without the .html extension).<br />
**article\_cdate**<br />
Its value is the date and time of the publication of the article (the date of the commit which added the article to the repository in the *articles-dir* directory (see [configuration](#configuration))).<br />
**article\_cdate\_html5**<br />
Same as previous, but in an HTML5 `<time>` compliant format.<br />
**article\_cdate\_day**<br />
Its value is the date of the publication of the article.<br />
**article\_cdate\_time**<br />
Its value is the time of the publication of the article.<br />
**article\_ctimestamp**<br />
Its value is the timestamp of the publication of the article.<br />
**article\_mdate**<br />
Its value is the date and time of the last modification of the article (the date of the last commit which changed the article file).<br />
**article\_mdate\_html5**<br />
Same as previous, but in an HTML 5 `<time>` compliant format.<br />
**article\_mdate\_day**<br />
Its value is the date of the last modification of the article.<br />
**article\_mdate\_time**<br />
Its value is the time of the last modification of the article.<br />
**article\_mtimestamp**<br />
Its value is the timestamp of the last modification of the article.<br />
**article\_author**<br />
This is an alias to the variable **article\_cauthor** (see below).<br />
**article\_cauthor**<br />
Its value is the author of the commit which added the article to the repository.<br />
**article\_cauthor\_email**<br />
Its value is the email of the author of the commit which added the article to the repository (see [email obfuscation](#email-obfuscation)).<br />
**article\_mauthor**<br />
Its value is the author of the last commit which changed the article file.<br />
**article\_mauthor\_email**<br />
Its value is the email of the author of the last commit which changed the article file (see [email obfuscation](#email-obfuscation)).<br />
**article\_previous**<br />
Its value is the file name (without .html extension) of the previous article ordered by publication date.<br />
**article\_previous\_title**<br />
Its value is the title of the previous article ordered by publication date.<br />
**article\_next**<br />
Its value is the file name (without .html extension) of the next article ordered by publication date.<br />
**article\_next\_title**<br />
Its value is the title of the next article ordered by publication date.

<span class="note">Some other variables can be internally set by pandoc.</span>

### for loops in archives.html and feed.xml:

Those loops use variable attributes as permitted by pandoc: “article” receives all needed values in attribute members (_e.g._ “article.file”, “article.cdate-time”) from a YAML block written in a temporary file; pandoc then loops upon the different values taken by the “article” variable, and injects corresponding attributes inside the template.

The only difference between the archives.html and feed.xml templates is that in feed.xml these constructs only loop over the last five articles and commits.

### Email obfuscation

Pandoc is able to perform HTML of even JavaScript email obfuscation.
Guess how you might learn more about it?

Roughly, it consists in not writing the plain email inside the HTML source but to write a JavaScript snippet instead, which will assemble HTML decimal and hexa entities so as to render the email link and text.
It is very to use from the article contents, but it is not easily accessible from templates (since they are not parsed from Markdown to HTML).
Hence to obfuscate emails in the templates I implemented an equivalent function in shell which you can call to sanitize emails from inside the hooks (it's the *sanit\_mail* function).
It is an alternative to the *name \_at\_ domain .dot. tld* form used by fugitive.

# Hacking pangitive

If you want to hack pangitive code to customize the behavior of the hooks, you can either edit the hooks directly in your pangitive blog repository, or edit them in the pangitive source code, then rebuild the `pangitive` executable using the `build.sh` script provided in the source code repository.

In the latter case and if you already have a pangitive blog running, you will need to install the new hooks.
This can be done by running the command: `pangitive --install-hooks <dir>`, where `<dir>` is the path to your pangitive blog repository.
If it is not specified then the current working directory is used.

This can be handy if you decide for instance that you want to have the last *n* articles on your index.html page rather than a mere copy of the last article.

# Known issues

fugitive seems to be have some issues with the version of git provided in Debian Lenny (1.5.\*), and pangitive most probably inherited from it.
It will probably not be investigated, because Squeeze is out and git 1.7.\* is available in the backports which are now officially supported by Debian.
