# SQL-Nested-Set-Model
More complete implementation of the nested set model, with schema, triggers, stored procedures, and get-ers.

How to get started
---

1. Run `Create Entities.sql` in your favorite playground SQL database.  It will create the schema `nsm`, the base `table`, and the friendly `view`.
2. Run `Sample Data.sql` in said database to fill the new table with some data.
3. Run the `trg_` scripts to create the triggers.
4. Run `MoveCatSubtree.sql` to create the stored-procedure that moves nodes/subtrees around. 
  a. In re-thinking about this project, it should probably be called "ChangeCatParent", but I'll get to that renaming later.

Trying it out
---
* Check out the `Sample Queries.sql` to see some SELECTs in action.
* Revisit `Sample Data.sql` and run the comment-blocked INSERTs at the bottom.
* Write your own INSERT/UPDATE/DELETE queries to build your favorite family of cats!

I welcome any feedback, pull-requests, issues, suggestions, and rants!  Leave a comment on my blog (natethedba.wordpress.com), and of course, stalk me right here on GitHub!
