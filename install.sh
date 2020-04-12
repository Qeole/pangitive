#!/bin/sh

replace_string() {
  sed "s/<?pangitive-install[[:space:]]\+$1[[:space:]]*?>/$2/"
}

pangitive_write_template() {
  name=`git config --get user.name`
  base64 -d | gunzip | replace_string "name" "$name" | \
    replace_string "year" "`date +%Y`"
}

pangitive_install_hooks() {
  echo -n "Installing pangitive hooks scripts... "
  (base64 -d | gunzip) > .git/hooks/pre-commit <<EOF
#INCLUDE:pre-commit.sh#
EOF
  (base64 -d | gunzip) > .git/hooks/pre-receive <<EOF
#INCLUDE:pre-receive.sh#
EOF
  (base64 -d | gunzip) > .git/hooks/post-commit <<EOF
#INCLUDE:post-commit.sh#
EOF
  (base64 -d | gunzip) > .git/hooks/post-receive <<EOF
#INCLUDE:post-receive.sh#
EOF
  (base64 -d | gunzip | \
    tee -a .git/hooks/post-commit) >> .git/hooks/post-receive <<EOF
#INCLUDE:html-gen.sh#
EOF
  chmod +x .git/hooks/pre-commit
  chmod +x .git/hooks/pre-receive
  chmod +x .git/hooks/post-commit
  chmod +x .git/hooks/post-receive
  echo "done."
  pangitive_make_previewer
}

pangitive_make_previewer() {
  echo -n "Creating preview script... "
  (base64 -d | gunzip) > preview <<EOF
#INCLUDE:preview-gen.sh#
EOF
  (base64 -d | gunzip) >> preview <<EOF
#INCLUDE:html-gen.sh#
EOF
  chmod +x preview
  echo "done"
}

pangitive_install_config() {
  echo -n "Adding default pangitive settings to git config... "
  if [ "$1" = "remote" ]; then
    git config --add receive.denyCurrentBranch "ignore"
  fi
  git config --add pangitive.blog-url ""
  git config --add pangitive.blog-owner "`git config --get user.name`"
  git config --add pangitive.blog-title "`git config --get user.name`'s blog"
  git config --add pangitive.templates-dir "_templates"
  git config --add pangitive.articles-dir "_articles"
  git config --add pangitive.pages-dir "_pages"
  git config --add pangitive.public-dir "_public"
  git config --add pangitive.pandoc "`which pandoc`"
  git config --add pangitive.pandoc-options "--from=markdown --to=html5 -f markdown+smart --css=pangitive.css --number-sections"
  echo "done."
}

pangitive_install() {
  if [ -d ".git" ]; then
    echo -n "There's already a git repository here, "
    echo "enter 'yes' if you want to continue: "
    read CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
      echo "Aborting."
      exit 1
    fi
  else
    echo -n "Creating new git repository... "
    git init >/dev/null
    echo "done."
  fi
  pangitive_install_config "$1"
  pangitive_install_hooks "$1"
  echo -n "Preventing git to track temporary and generated files... "
    cat >> .git/info/exclude <<EOF
*~
_public/index.html
_public/archives.html
_public/feed.xml
EOF
  echo "done."
  if [ "$1" = "local" ]; then
    echo -n "Creating default directory tree... "
    mkdir -p _drafts _articles _pages _templates _public
    echo "done."
    echo -n "Writing default template files... "
    (pangitive_write_template | tee _templates/archives.html) \
      > _templates/article.html <<EOF
#INCLUDE:default-files/top.html#
EOF
    pangitive_write_template >> _templates/article.html <<EOF
#INCLUDE:default-files/article.html#
EOF
    pangitive_write_template >> _templates/archives.html <<EOF
#INCLUDE:default-files/archives.html#
EOF
    (pangitive_write_template | tee -a _templates/archives.html) \
      >> _templates/article.html <<EOF
#INCLUDE:default-files/bottom.html#
EOF
    pangitive_write_template > _templates/feed.xml <<EOF
#INCLUDE:default-files/feed.xml#
EOF
    echo "done."
    echo -n "Writing default css files... "
    (base64 -d | gunzip) > _public/pangitive.css <<EOF
#INCLUDE:default-files/pangitive.css#
EOF
    (base64 -d | gunzip) > _public/print.css <<EOF
#INCLUDE:default-files/print.css#
EOF
    echo "done."
    echo -n "Importing files into git repository... "
    git add preview _templates/* _public/*.css >/dev/null
    git commit --no-verify -m "pangitive inital import" >/dev/null 2>&1
    echo "done."
    echo "Writing dummy article (README) and adding it to the repos... "
    (base64 -d | gunzip) > _articles/pangitive-readme <<EOF
#INCLUDE:README.md#
EOF
    git add _articles/pangitive-readme
    git commit --no-verify --author="Qeole < qeole _at_ qoba .dot. lt >" \
      -m "pangitive: README" >/dev/null
    echo "done."
  fi
  echo "Installation complete, please set your blog url using"
  echo '    git config pangitive.blog-url "<url>"'
}

pangitive_usage() {
  echo "This is pangitive installation script."
  echo "  To install a local (where you commit) repository of your blog run:"
  echo "      pangitive --install-local <dir>"
  echo -n "  where <dir> is where you want the installation to take place, "
  echo "defaults to current working directory."
  echo "  To install a remote (where you push) repository of your blog run:"
  echo "      pangitive --install-remote <dir>"
  echo -n "  where <dir> is where you want the installation to take place, "
  echo "defaults to current working directory."
}

pangitive_help() {
  echo -n "Pangitive is a blog engine running on top of pandoc and git,"
  echo "using hooks to generate static HTML pages."
  pangitive_usage
}

DIR="."
if [ "$2" != "" ]; then DIR="$2"; fi
if [ ! -d "$DIR" ]; then mkdir -p "$DIR"; fi
cd "$DIR"
case "$1" in
  "--help"|"-h") pangitive_help >&2;;
  "--install"|"--install-local") pangitive_install "local";;
  "--install-remote") pangitive_install "remote";;
  "--install-hooks") pangitive_install_hooks ;;
  "--install-config") pangitive_install_config "local";;
  *) pangitive_usage >&2;;
esac
cd - >/dev/null
