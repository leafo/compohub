# How to add a new jam

To add a new jam you'll need to submit a pull request with the jam's
information added to one of the `json` files in this directory. Once accepted
the page will be updated and your jam will be visible.

> If you're not familiar with creating a pull request then you can also open an
> issue on the [issues tracker](https://github.com/leafo/compohub/issues) with
> the jam you want added.

Jams are organized by their starting year. Choose the `json` file that
corresponds to the year when your jam starts, if the file doesn't exist yet
then you can create it.

For example let's create a new jam that starts *May 4th, 2014 at 12pm* and
lasts 10 days.

You'll need to create a new object in the `jams` array, the position doesn't
matter but for simplicity keep things in ascending order of start date.

If you are specifying a time in addition to date for your start and end then
you should provide a timezone (otherwise it defaults to UTC). More information
on times and dates below.

The following fields are required: `name`,  `url`, `start_date`, `end_date`.

**jams/2014.json**

    {
      jams: [
        .. other jams ..,

        {
          "name": "My cool jam",
          "url": "http://example.com/my-jam",
          "start_date": "2014-05-04 13:00 -0700",
          "end_date": "2014-05-14 13:00 -0700"
        }
      ]
    }



Optionally you can provide the fields `description`, `image`, `tags`, `themes`.
Here's a more complete version of the above example:

**jams/2014.json**

    {
      jams: [
        .. other jams ..,

        {
          "name": "My cool jam",
          "url": "http://example.com/my-jam",
          "start_date": "2014-05-04 13:00 -0700",
          "end_date": "2014-05-14 13:00 -0700",
          "themes": ["cool-things"],
          "tags": ["leafo-jams"],
          "description": "This is the jam we've been waiting for, I hope you are ready. I know I am!"
        }
      ]
    }


### Tags and themes

Tags and themes can be used to classify your jam. If your jam is part of a
series then definitely make a tag for that series (even if it's the first one
of the series). Re-use existing tags whenever possible.

Tags and themes should be written `in-lowercase` and `separated-by-dashes`.

Both tags and themes are JSON arrays, so provide an array of strings (even if
there is only one tag/theme).


### Date and time format

The following patterns are supported for parsing dates. If either the start or
end can't be parsed then the jam entry is invalid.

    YYYY-MM-DD HH:mm:ss Z
    YYYY-MM-DD HH:mm Z
    YYYY-MM-DD


`Z` means timezone, in the form `+0000`. So PST would be `-0700`. You must
provide 2 digits for day, month, or seconds even when they are less than 10. So
`05` for May, `01` for the first day of the month, etc.

The final format `YYYY-MM-DD` is special, there is no time or timezone. This
will cause the jam's start time to be `0:00` and end time to be `23:59` in the
viewer's local time zone on the respective days passed in. That makes an
inclusive range from start to end.

### Editing an existing jam

Feel free to edit any existing jams, fixing any errors or adding themes after
they've been announced.
