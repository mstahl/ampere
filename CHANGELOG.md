# Changelog

## 1.2.1

* Model saves and multi-attribute updates are now completely atomic, using
  the MULTI and EXEC commands.

## 1.2.0

* Ampere model IDs are now integers. They are still stored internally the
  same way as before, so a model named Post will have IDs like "post.3892".
* Rails integration is now complete!
  + Add Ampere to your Gemfile.
  + Type `rails generate ampere:config` to generate an example config file.
  + Type `rake ampere:flush` to flush Redis (this will delete everything).
* Callbacks!
  + `before_save`
  + `before_create`
  + More to come.
* Better test coverage.