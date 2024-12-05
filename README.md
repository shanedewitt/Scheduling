How to converted the SVN repo from https://trac.opensourcevista.net/svn/Scheduling to git.

- Install git-svn

~~~bash
brew install git-svn
~~~

- Create an authors.txt to map svn contributors to github users.

~~~html
george = glilly <glilly@glilly.net>
sam = shabiel <sam.habiel@gmail.com>
faisal = shabiel <sam.habiel@gmail.com>
tariq = shabiel <sam.habiel@gmail.com>
~~~

- Clone and convert repo

~~~bash
git svn clone https://trac.opensourcevista.net/svn/Scheduling --stdlayout --no-metadata -A authors.txt -T trunk -b branches -t tags Scheduling
~~~

- Create a repo in github

- Add github as a remote

~~~bash
git remote add origin https://github.com/shanedewitt/Scheduling.git
~~~

- Upload

~~~bash
git push -u origin master
~~~
