blog_url=`git config --get pangitive.blog-url`
if [ "$blog_url" = "" ]; then
  echo -n "[pangitive] WARNING: git config pangitive.blog-url is empty and "
  echo "should not be, please set it as soon as possible."
fi
blog_owner=`git config --get pangitive.blog-owner`
blog_title=`git config --get pangitive.blog-title`
blog_years=`git log --format='%ai' | \
  sed -n '1{s/-.*//;h};${G;s/\(-.*\)\?\n/−/;s/^\(.*\)−\1$/\1/;p}'`
templates_dir=`git config --get pangitive.templates-dir`
public_dir=`git config --get pangitive.public-dir`
if [ ! -d "$public_dir" ]; then mkdir -p "$public_dir"; fi
articles_dir=`git config --get pangitive.articles-dir`
pages_dir=`git config --get pangitive.pages-dir`
pandoc=`git config --get pangitive.pandoc`
pandoc_opt=`git config --get pangitive.pandoc-options`
if [ ! -f "$pandoc" -o ! -x "$pandoc" ]; then
  echo "Cannot access pandoc executable. Aborting." && exit
fi

# If template changed, regenerate all articles
tpl_change=`echo "$added_files" "$modified_files" "$deleted_files" | \
  grep -c "$templates_dir/"`
if [ "$tpl_change" -gt 0 ]; then
  first=`git log --format="%H" --reverse | head -1`
  modified_files=`git log $first..HEAD^ --name-status --pretty="format:" | \
    grep -E '^A' | cut -f2 | sort | uniq`
  deleted_files=
  tmpust=`mktemp pangitiveXXXXXX`
  tmpart=`mktemp pangitiveXXXXXX`
  tmpmod=`mktemp pangitiveXXXXXX`
  ls "$articles_dir"/* > "$tmpust"
  ls "$pages_dir"/* >> "$tmpust"
  sort "$tmpust" > "$tmpart"
  echo "$modified_files" | tr " " "\n" > "$tmpmod"
  modified_files=`comm -12 --nocheck-order "$tmpmod" "$tmpart"`
  rm "$tmpust" "$tmpart" "$tmpmod"
  echo "[pangitive] Templates changed, regenerating everything..."
fi

generated_files=`mktemp pangitiveXXXXXX`

# List of articles (base names), sorted by time stamp, one per line
articles_sorted=`mktemp pangitiveXXXXXX`
for f in "$articles_dir"/*; do
  ts=`git log --format="%at" -- "$f" | tail -1`
  if [ "$ts" != "" ]; then
    echo "$ts ${f#$articles_dir/}"
  fi
done | sort -k1,1nr | cut -d' ' -f2 > "$articles_sorted"

if [ "`head -1 $articles_sorted`" = "" ]; then
  echo "[pangitive] WARNING: there's no article, errors may occur." >&2
fi

# List of articles including deleted ones
articles_sorted_with_delete=`mktemp pangitiveXXXXXX`
for f in "$articles_dir"/* $deleted_files; do
  ts=`git log --format="%at" -- "$f" | tail -1`
  if [ "$ts" != "" ]; then
    echo "$ts ${f#$articles_dir/}"
  fi
done | sort -k1,1nr | cut -d' ' -f2 > "$articles_sorted_with_delete"

commits=`mktemp pangitiveXXXXXX`
git log --oneline | cut -d' ' -f1 > "$commits"

get_article_info() {
  git log --format="$1" -- "$2/$3"
}
get_article_next_file() {
  next=`grep -B1 "^$1$" "$articles_sorted" | head -1`
  if [ "$next" != "$1" ]; then
    echo "$next"
  fi
}
get_article_previous_file() {
  previous=`grep -A1 "^$1$" "$articles_sorted" | tail -1`
  if [ "$previous" != "$1" ]; then
    echo "$previous"
  fi
}
get_deleted_next_file() {
  next=`grep -B1 "^$1$" "$articles_sorted_with_delete" | head -1`
  if [ "`echo $deleted_files | grep -c \"$next\"`" = "0" ]; then
    echo "$next"
  fi
}
get_deleted_previous_file() {
  previous=`grep -A1 "^$1$" "$articles_sorted_with_delete" | tail -1`
  if [ "`echo $deleted_files | grep -c \"$previous\"`" = "0" ]; then
    echo "$previous"
  fi
}
get_article_title() {
  if [ "$2" != "" ]; then
    sed -n 's/^\s*title\s*:\s*\(.*\)/\1/p;T;q' "$1/$2" | sed "s/^'\(.*\)'$/\1/"
  fi
}
get_commit_info() {
  git show -s --format="$1" "$2"
}
get_commit_body() {
  tmp=`mktemp pangitiveXXXXXX`
  git show -s --format="%b" "$1" > "$tmp"
  if [ "`cat \"$tmp\" | sed \"/^$/d\" | wc -l`" != "0" ]; then
    echo "$tmp"
  else
    rm "$tmp"
  fi
}

# Used with following function to obfuscate emails for bots
convert_to_html() {
  if [ "$1" = "" ] ; then
    return
  fi
  i=1;
  while [ $i -le ${#1} ] ; do
    l=`echo -n "$1" | cut -c$i`
    # pandoc does not do exactly the same here, it has another algorithm to
    # switch between decimal and hexadecimal notation (don't know what it is)
    if [ $((i%2)) -eq 0 ] ; then
      printf '&#%d;' \'"$l"
    else
      printf '&#x%x;' \'"$l"
    fi
    i=$((i+1))
  done
}

# Obfuscate emails, pandoc style (more or less)
sanit_mail() {
  if [ "$1" = "" -o `echo -n "$1" | sed 's/[^@]//g' | wc -c` -ne 1 ] ; then
    echo "[preview mode]"
    return
  fi
  name=`echo $1 | cut -d@ -f1`
  host=`echo $1 | cut -d@ -f2`
  n=`convert_to_html "$name"`
  a='&#64;'
  h=`convert_to_html "$host"`

  n_ns=`echo "$name" | sed 's/\./ dot /g'`
  n_ns=`convert_to_html "$n_ns"`
  a_ns=`convert_to_html ' at '`
  h_ns=`echo "$host" | sed 's/\./ dot /g'`
  h_ns=`convert_to_html "$h_ns"`

  if [ "$2" != "" ] ; then
    text="'$2'"
    noscript_mail="`convert_to_html \"$2\"`&#32;&#x28;$n_ns$a_ns$h_ns&#x29;"
  else
    text="e"
    noscript_mail="$n_ns$a_ns$h_ns"
  fi

  echo '<script type="text/javascript">'
  echo '<!--'
  echo "h='"$h"';a='"$a"';n='"$n"';e=n+a+h;"
  echo "document.write('<a h'+'ref'+'=\"ma'+'ilto'+':'+e+'\">'+\
"$text"+'<\/'+'a'+'>');"
  echo '// -->'
  echo "</script><noscript>$noscript_mail</noscript>"
}

# Declare global variables
commit_Hash=""
commit_hash=""
commit_author=""
commit_author_email=""
commit_date=""
commit_date_html5=""
commit_date_day=""
commit_date_time=""
commit_timestamp=""
commit_comment=""
commit_slug=""
commit_body=""

# Load variables to directly feed pandoc with
load_commit_info() {
  commit_Hash="--variable=commit-Hash:`get_commit_info '%H' \"$1\"`"
  commit_hash="--variable=commit-hash:`get_commit_info '%h' \"$1\"`"
  author_name=`get_commit_info '%an' "$1"`
  author_email=`get_commit_info '%ae' "$1"`
  commit_author="--variable=commit-author:$author_name"
  commit_author_email="--variable=commit-author-email:`sanit_mail \
    \"$author_email\" \"$author_name\"`"
  datetime=`get_commit_info '%ai' "$1"`
  commit_date="--variable=commit-date:$datetime"
  commit_date_html5="--variable=commit-date-html5:`echo \"$datetime\" | \
    sed 's/ /T/;s/ \(+\|-\)\([0-9][0-9]\)/\1\2:/'`"
  commit_date_day="--variable=commit-date-day:`echo $datetime | cut -d' ' -f1`"
  commit_date_time="--variable=commit-date-time:`echo $datetime | \
    cut -d' ' -f2`"
  commit_timestamp="--variable=commit-timestamp:`get_commit_info '%at' \"$1\"`"
  commit_comment="--variable=commit-comment:`get_commit_info '%s' \"$1\"`"
  commit_slug="--variable=commit-slug:`get_commit_info '%f' \"$1\"`"
  commit_body="--variable=commit-body:`get_commit_body \"$1\"`"
}

# Declare global variables
article_file=""
article_title=""
article_cdate=""
article_cdate_html5=""
article_cdate_day=""
article_cdate_time=""
article_ctimestamp=""
article_mdate=""
article_mdate_html5=""
article_mdate_day=""
article_mdate_time=""
article_mtimestamp=""
article_author=""
article_cauthor=""
article_cauthor_email=""
article_mauthor=""
article_mauthor_email=""
article_previous=""
article_previous_title=""
article_next=""
article_next_title=""
article_centent=""

# Load variables to directly feed pandoc with
load_article_info() {
  article_file="--variable=article-file:$2"
  article_title="--variable=article-title:`get_article_title \"$1\" \"$2\"`"
  cdatetime=`get_article_info '%ai' "$1" "$2" | tail -1`
  article_cdate="--variable=article-cdate:$cdatetime"
  article_cdate_html5="--variable=article-cdate-html5:`echo \"$cdatetime\" | \
    sed 's/ /T/;s/ \(+\|-\)\([0-9][0-9]\)/\1\2:/'`"
  article_cdate_day="--variable=article-cdate-day:`echo \"$cdatetime\" | \
    cut -d' ' -f1`"
  article_cdate_time="--variable=article-cdate-time:`echo \"$cdatetime\" | \
    cut -d' ' -f2`"
  article_ctimestamp="--variable=article-ctimestamp:`get_article_info \
    '%at' \"$1\" \"$2\" | tail -1`"
  u=`get_article_info "%ai" "$1" "$2" | wc -l`
  mdatetime=`if test "$u" -gt 1; then get_article_info '%ai' "$1" "$2" | \
    head -1; fi`
  article_mdate="--variable=article-mdate:$mdatetime"
  article_mdate_html5="--variable=article-mdate-html5:`echo \"$mdatetime\" | \
    sed 's/ /T/;s/ \(+\|-\)\([0-9][0-9]\)/\1\2:/'`"
  article_mdate_day="--variable=article-mdate-day:`echo \"$mdatetime\" | \
    cut -d' ' -f1`"
  article_mdate_time="--variable=article-mdate-time:`echo \"$mdatetime\" | \
    cut -d' ' -f2`"
  article_mtimestamp="--variable=article-mtimestamp:`if test \"$u\" -gt 1; \
    then get_article_info '%at' \"$1\" \"$2\" | head -1; fi`"
  tmp_cauthor=`get_article_info '%an' "$1" "$2" | tail -1`
  tmp_cauthor_email=`get_article_info '%ae' "$1" "$2" | tail -1`
  article_author="--variable=author:$tmp_cauthor"
  article_cauthor="--variable=article-cauthor:$tmp_cauthor"
  article_cauthor_email="--variable=article-cauthor-email:`sanit_mail \
    \"$tmp_cauthor_email\" \"$tmp_cauthor\"`"
  tmp_mauthor=`get_article_info '%an' "$1" "$2" | head -1`
  tmp_mauthor_email=`get_article_info '%ae' "$1" "$2" | head -1`
  article_mauthor="--variable=article-mauthor:$tmp_mauthor"
  article_mauthor_email="--variable=article-mauthor-email:`sanit_mail \
    \"$tmp_mauthor_email\" \"$tmp_mauthor\"`"
  if [ "$1" != "$pages_dir" ]; then
    previous_file=`get_article_previous_file "$2"`
    article_previous="--variable=article-previous:$previous_file"
    article_previous_title="--variable=article-previous-title:`\
      get_article_title \"$1\" \"$previous_file\"`"
    next_file=`get_article_next_file "$2"`
    article_next="--variable=article-next:$next_file"
    article_next_title="--variable=article-next-title:`get_article_title \
      \"$1\" \"$next_file\"`"
  else # don't keep remnant data from previous generated file in global vars
    article_previous="--variable=deactivated"
    article_previous_title="--variable=deactivated"
    article_next="--variable=deactivated"
    article_next_title="--variable=deactivated"
  fi
}

# Processing body of the article, without any template
get_article_content() {
  $pandoc --smart --from=markdown --to=html "$1" | tr '\n' ' '
}

generate_archives() {
  tmpfile=$2
  echo '---' > "$tmpfile"
  echo 'article:' >> "$tmpfile"
  for i in `cat "$1"`; do
    load_article_info "$articles_dir" "$i"
    echo $article_file | \
      sed "s/--variable=article-\([^:]*\):\(.*\)/  - \1: '\2'/" >> "$tmpfile"
    for j in \
      "$article_title" \
      "$article_cdate" \
      "$article_cdate_html5" \
      "$article_cdate_day" \
      "$article_cdate_time" \
      "$article_ctimestamp" \
      "$article_mdate" \
      "$article_mdate_html5" \
      "$article_mdate_day" \
      "$article_mdate_time" \
      "$article_mtimestamp" \
      "$article_cauthor" \
      "$article_mauthor" \
      "$article_previous" \
      "$article_previous_title" \
      "$article_next" \
      "$article_next_title"; do
      echo $j | \
        sed "s/--variable=article-\([^:]*\):\(.*\)/    \1: '\2'/" >> "$tmpfile"
    done
    for j in \
      "$article_cauthor_email" \
      "$article_mauthor_email"; do
      echo $j | \
        sed "s/--variable=article-\([^:]*\):\(.*\)/    \1: \2/" >> "$tmpfile"
    done
    if [ "$3" != "" ]; then # If anything provided as third arg, add content
      echo -n "    content: '" >> "$tmpfile"
      # Enclose in quotes in case it contains a colon; change inner quotes
      # into curly quotes so as to preserve outer enclosing
      get_article_content "$articles_dir/$i"  | sed "s/'/’/g" >> "$tmpfile"
      echo "'" >> "$tmpfile"
    fi
  done
  echo '---' >> "$tmpfile"
}

generate_article() {
  temp=`mktemp pangitiveXXXXXX`
  chmod a+r "$temp"
  if [ "$1" != "${1#$articles_dir}" ]; then
    art="${1#$articles_dir/}"
    dir=$articles_dir
    tpl="tpl.html"
  elif [ "$f" != "${1#$pages_dir}" ]; then
    art="${1#$pages_dir/}"
    dir=$pages_dir
    tpl="tpl.html"
  fi
  if [ "$art" != "" ]; then
    title=`get_article_title "$dir" "$art"`
    biblio=""
    if [ "`head \"$1\" | grep '^bibliography: true$'`" != "" ] ; then
      biblio="--filter pandoc-citeproc"
    fi
    load_commit_info "-1"
    load_article_info "$dir" "$art"
    $pandoc $pandoc_opt \
      --variable=pagetitle:"$title" \
      --variable=blog-url:"$blog_url" \
      --variable=blog-owner:"$blog_owner" \
      --variable=blog-title:"$blog_title" \
      --variable=blog-years:"$blog_years" \
      --template="$templates_dir/article.html" \
      $biblio \
      "$commit_Hash" \
      "$commit_hash" \
      "$commit_author" \
      "$commit_author_email" \
      "$commit_date" \
      "$commit_date_html5" \
      "$commit_date_day" \
      "$commit_date_time" \
      "$commit_timestamp" \
      "$commit_comment" \
      "$commit_slug" \
      "$commit_body" \
      "$article_file" \
      "$article_title" \
      "$article_cdate" \
      "$article_cdate_html5" \
      "$article_cdate_day" \
      "$article_cdate_time" \
      "$article_ctimestamp" \
      "$article_mdate" \
      "$article_mdate_html5" \
      "$article_mdate_day" \
      "$article_mdate_time" \
      "$article_mtimestamp" \
      "$article_author" \
      "$article_cauthor" \
      "$article_cauthor_email" \
      "$article_mauthor" \
      "$article_mauthor_email" \
      "$article_previous" \
      "$article_previous_title" \
      "$article_next" \
      "$article_next_title" \
      "$1" > "$temp"
    mv "$temp" "$public_dir/$art.html"
  fi
}

regenerate_previous_and_next_article_maybe() {
  if [ "$1" != "" -a \
       "`grep -c \"^$1$\" \"$generated_files\"`" = "0" ]; then
    echo -n "[pangitive] Regenerating $public_dir/$1.html"
    echo -n " (as previous article) from $articles_dir/$1... "
    generate_article "$articles_dir/$1"
    echo "done."
    echo "$1" >> "$generated_files"
  fi
  if [ "$2" != "" -a \
       "`grep -c \"^$2$\" \"$generated_files\"`" = "0" ]; then
    echo -n "[pangitive] Regenerating $public_dir/$2.html"
    echo -n " (as next article) from $articles_dir/$2... "
    generate_article "$articles_dir/$2"
    echo "done."
    echo "$2" >> "$generated_files"
  fi
}

modification=0
# Generate / regen added or modified files
for f in $added_files $modified_files; do
  art=""
  if [ "$f" != "${f#$articles_dir}" ]; then
    art="${f#$articles_dir/}"
    modification=$((modification + 1))
  elif [ "$f" != "${f#$pages_dir}" ]; then
    art="${f#$pages_dir/}"
  fi
  if [ "$art" != "" ]; then
    echo -n "[pangitive] Generating $public_dir/${art}.html from"
    echo -n " $f... "
    generate_article "$f"
    echo "done."
    echo "$art" >> "$generated_files"
  fi
done

# Update links to next and previous articles
for f in $added_files; do
  art=""
  if [ "$f" != "${f#$articles_dir}" ]; then
    art="${f#$articles_dir/}"
  elif [ "$f" != "${f#$pages_dir}" ]; then
    art="${f#$pages_dir/}"
  fi
  if [ "$art" != "" ]; then
    if [ "$preview" = "" ]; then
      echo -n "[pangitive] Adding $public_dir/$art.html to git ignore list... "
      echo "$public_dir/$art.html" >> .git/info/exclude
      echo "done."
    fi;
    if [ "$f" != "${f#$articles_dir}" ]; then
      previous=`get_article_previous_file "$art"`
      next=`get_article_next_file "$art"`
      regenerate_previous_and_next_article_maybe "$previous" "$next"
    fi;
  fi
done

if [ "$preview" = "" ]; then
  # Delete removed articles and update links
  for f in $deleted_files; do
    art=""
    if [ "$f" != "${f#$articles_dir}" ]; then
      art="${f#$articles_dir/}"
      modification=$((modification + 1))
    elif [ "$f" != "${f#$pages_dir}" ]; then
      art="${f#$pages_dir/}"
    fi
    if [ "$art" != "" ]; then
      echo -n "[pangitive] Deleting $public_dir/$art.html... "
      rm "$public_dir/$art.html"
      echo "done."
      echo -n "[pangitive] Removing $art.html from git ignore list... "
      sed -i "/^$public_dir\/$art.html$/d" .git/info/exclude
      echo "done."
      if [ "$f" != "${f#$articles_dir}" ]; then
        previous=`get_deleted_previous_file "$art"`
        next=`get_deleted_next_file "$art"`
        regenerate_previous_and_next_article_maybe "$previous" "$next"
      fi
    fi
  done

  # Generate archives
  if [ $modification -gt 0 ]; then
    temp=`mktemp pangitiveXXXXXX`
    archivetemp=`mktemp pangitiveXXXXXX`
    chmod a+r "$temp"
    echo -n "[pangitive] Generating $public_dir/archives.html... "
    load_commit_info "-1"
    generate_archives "$articles_sorted" "$archivetemp"
    $pandoc $pandoc_opt \
      --variable=pagetitle:archives \
      --variable=blog-url:"$blog_url" \
      --variable=blog-owner:"$blog_owner" \
      --variable=blog-title:"$blog_title" \
      --variable=blog-years:"$blog_years" \
      --template="$templates_dir/archives.html" \
      "$commit_Hash" \
      "$commit_hash" \
      "$commit_author" \
      "$commit_author_email" \
      "$commit_date" \
      "$commit_date_html5" \
      "$commit_date_day" \
      "$commit_date_time" \
      "$commit_timestamp" \
      "$commit_comment" \
      "$commit_slug" \
      "$commit_body" \
      "$archivetemp" > "$temp"
    cp "$temp" "$public_dir/archives.html"
    echo "done."

    # Generate feed
    echo -n "[pangitive] Generating $public_dir/feed.xml... "
    last_5_articles=`mktemp pangitiveXXXXXX`
    head -5 "$articles_sorted" > "$last_5_articles"
    generate_archives "$articles_sorted" "$archivetemp" "with_content"
    $pandoc $pandoc_opt \
      --variable=pagetitle:feed \
      --variable=blog-url:"$blog_url" \
      --template="$templates_dir/feed.xml" \
      "$commit_Hash" \
      "$commit_hash" \
      "$commit_author" \
      "$commit_author_email" \
      "$commit_date" \
      "$commit_date_html5" \
      "$commit_date_day" \
      "$commit_date_time" \
      "$commit_timestamp" \
      "$commit_comment" \
      "$commit_slug" \
      "$commit_body" \
      "$archivetemp" > "$temp"
    cp "$temp" "$public_dir/feed.xml"
    echo "done."
    rm "$archivetemp" "$last_5_articles" "$temp"
    echo -n "[pangitive] Using last published article as index page... "
    cp "$public_dir/`head -1 $articles_sorted`.html" "$public_dir/index.html"
    echo "done".
    echo "[pangitive] Blog update complete."
  fi
fi
rm "$articles_sorted"
rm "$articles_sorted_with_delete"
rm "$commits"
rm "$generated_files"
