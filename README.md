# Markdown Memo Web

* Based on usemod wiki (PERL wiki)
* In order to fetch multybyte character from query_string in http head, Encode is necessary above all. Some environments like built-in webserver couldn't handle that because latin1 is only encoding supported by the server.
* I am writing codes on eclipse + EPIC plugin holding the problem.
* TODO : changing translation module from wiki to markdown