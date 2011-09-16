# TrackHistory

## Introduction

Sometimes you want to track changes in a model, but in larger tables its _really_ inefficient to query against a polymorphic relationship in a single table like 'audits'.  __TrackHistory__ is a way to do this in a performant way, and its still easy!

Imagine you want to track how the name of users change over time:

``` ruby
# add a mix-in to your model (yes, that's all)
track_history
```

Then create a migration for a table with the following structure (generator coming soon):

    id, user_id, email_before, email_after, created_at

If you want to also record creations and deletions, you should add a column like:

``` ruby
action ENUM ('create', 'update', 'destroy') # action can also be a varchar
```

You will automatically get:

``` ruby
user.histories
user.histories.first.class # UserHistory

user.histories.first.modifications # ["email"]
```

You can do this with any field or method.

---

## There's more

But wait, you say!  I want to use this to annotate some more information when there's changes, about the current state of the object.

``` ruby
# add the field, ex: 'name' in a migration
track_history do
  annotate :name
  annotate :name, :as => :the_name
end

# or you can pass a block
track_history do
  annotate(:name) { "#{name} !!!" }
end
```

If you need to change the field names to work with legacy tables you can do that too:

``` ruby
track_history do
  field :name, :before => :name_from, :after => :name_to
end
```

And if you don't want the reference field maintained for whatever reason:

``` ruby
track_history :reference => false
```

---

## Adding methods to *History

To add methods to your History classes, or create additional relationships that you may need, you can work directly in the `track_history` block:

``` ruby
track_history(:model_name => 'WorkflowChange', :reference => false) do
  annotate :object_id
  self.belongs_to :object
end
```

---

## Installation (in your Gemfile)

``` ruby
gem 'track_history', '0.0.10'
```

---

## Other options

If you need to change the name of the model, you can do something like:

``` ruby
track_history :model_name => 'UserAudit'
track_history :table_name => 'user_audits'
```

---

### License

The MIT License (see attached)
