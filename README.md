Cyclop
======

Job queue with MongoDB with emphasis on never losing any task even if worker fails hard (segfault).

Build Status
---------

[![Build Status](http://travis-ci.org/TalentBox/cyclop.png)](http://travis-ci.org/TalentBox/cyclop)

Dependencies
------------

* Ruby >= 1.9.2
* gem "mongo", "~> 1.3.1"
* gem "posix-spawn", "~> 0.3.6"

Usage
-----

* Give Cyclop access to mongo:

        Cyclop.db = Mongo::Connection.new["database_name"]

    or with Replica-Sets

        Cyclop.db = Mongo::ReplSetConnection.new["database_name"]

    or if you're using MongoMapper:

        Cyclop.db = MongoMapper.database

    or if you're using Mongoid:

        Cyclop.db = Mongoid.database

* Queue a new task:

        Cyclop.push({
          queue: :upload,
          job_params: {
            url: "http://example.com",
          },
        })

* Queue a new task to process in 5 minutes, to retry 3 times in case of error with a 1 minute delay between each:

        Cyclop.push({
          queue: :convert,
          job_params: {
            tmp_file: "/tmp/uploaded_file_32.png",
          },
          delay: 300,
          retries: 3,
          splay: 60,
        })

* Get next job:

        Cyclop.next

* Get next job on specific queues:

        Cyclop.next :upload, :convert

* Get next job on specific queues for a specific host:

        Cyclop.next :upload, :convert, host: "tartarus.local"

* Get failed jobs (limit to 30):

        Cyclop.failed limit: 30

* Get failed jobs (skip first 10, limit to 30):

        Cyclop.failed skip: 10, limit: 30

* Requeue a failed job:

        job = Cyclop.failed.first
        job.requeue

* Start a worker:

        cyclop -c config.yml
        
* To get help about the format for config.yml

        cyclop -h

About
-----

License
-------

cyclop is Copyright © 2011 TalentBox SA. It is free software, and may be redistributed under the terms specified in the LICENSE file.
