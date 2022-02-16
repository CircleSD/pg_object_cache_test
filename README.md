# A PostgreSQL large schema memory exhaustion test

This is a barebones Rails 6.1 application that has a schema borrowed from FatFreeCRM (https://github.com/fatfreecrm/fat_free_crm). Its purpose is to show how a PostgreSQL instance consumes memory when it has a large number of database schemas.

## Introduction

In a previous project for a multi-tenant Rails application, we chose schemas as our tenant data separation policy. We picked this policy having looked at database, schema and row level separation policies - we liked the guaranteed separation schemas offered, the ability to backup and restore individual tenant datasets and the simpler approach regarding table indexing. At the time, native PostgreSQL [row level security](https://www.postgresql.org/docs/14/ddl-rowsecurity.html) wasn't available and would be our go to choice today. Our setup was running on AWS using multiple EC2 instances in a load balancer to run the Rails app, API and background worker instances, and RDS for a managed PostgreSQL instance.

## The Problem

Everything worked exactly as intended and post launch we were very happy with the database and infrastructure choices we made, performance was good and our clients were happy. As the product became more successful and attracted lots of new customers, naturally the number of schemas also increased. Once we got to around 2000 schemas we started to notice significant database performance degradation from time to time. Things soon hit a critical stage when the database server started to crash and restart on a regular basis.

## Investigations

Our investigations discovered that database server physical and swap memory usage was always very high just prior to a crash. We couldn't understand why memory usage was as high as it was, the server was well specified and should have had RAM to spare. While closely monitoring memory usage we could see it was pretty linear - as time passed memory utilisation increased.

Another discovery to surface during our investigation was that memory usage on the database server always dropped when we deployed new code before starting to rise again. We used a zero downtime deployment strategy that would launch new Ruby processes running the new code whilst killing the previous processes running the old. To explore this further, we started to cycle servers from the load balancer and restart them. As we did this we noticed that memory usage on the database instance also went down and then started to go back up again, just like during a deploy. Repeating this process resulted in a graph of memory utilisation that looked like a sawtooth. Both of these discoveries clearly showed that as connections to the database server were closed and reopened it resulted in memory being freed up. Why? What was this memory being used for?

## Conclusion

When a PostgreSQL connection receives requests it will keep a cache of metadata about the database schema's objects (tables, columns, indexes, views, etc.) it has touched during its lifetime. This is great news from a performance perspective and what you'd probably expect from a good database server. Critically, however, **there are no constraints on the amount of memory that can be used for this purpose**.

The end result of this is that as the number of schemas, objects and connections increase, so will the memory utilisation for object metadata caching. As there is no limit to the amount of memory that can be allocated there will come a critical point where the required metadata cache exceeds available memory, therefore the database server will ultimately consume all available system and swap memory to the point that the database instance processes will be killed by the operating system.

This issue will manifest when a database has a very high number of schemas/objects/connections, a simple formula will give you an understanding of the total potential size of a metadata cache: -

`((schemas * objects) * connections) = cache entries`

In our case with around 2,000 schemas, each with 3,500 objects, and 40 database connections resulted in approximately **280 million** potential cache entries over time. The size of a cache entry is variable, but with an estimated average of 128 bytes each that would equate to around 36GB of memory requirement. With no limits imposed on the amount of memory used by PostgreSQL for caching metadata, combined with connections that are long-lived, this size of cache will result in memory exhaustion in most typical server configurations.

## The Solution

Knowing that closing the connection resulted in PostgreSQL freeing that connection's cache memory we experimented with some code that would close and reconnect the database connection every few thousand requests. Doing this limits a connection's lifetime and therefore the size its object metadata cache could grow to.

`ActiveRecord::Base.connection.reconnect!`

With this code deployed to all servers we saw a sawtooth pattern in the memory utilisation as memory was consumed and then released, but crucially, memory utilisation was now under control. Whilst the connection reset took around 500ms, we saw no meaningful performance penalty across the stack (acknowledging that the request that triggered the reset would be slower than usual) and our database server was now on a much more reliable footing.

We always intended that this code change would be temporary whilst we worked out a more permanent solution, however, further reading and investigation revealed that the memory exhausting cache behaviour was "normal" and there was no other applicable solution than the one we had implemented. As a result, this code remains in place to this day doing an excellent job in keeping metadata cache memory utilisation in check.

An alternative approach to resetting the connection in code would be to use a connection pooler (e.g. PGBouncer) that can be configured to control the maximum lifetime of a connection.

## Demonstration

This application can be used to demonstrate the problem we discovered and how our solution worked. It is designed to be run locally in conjunction with Docker Desktop. A Docker Compose file is included that will launch a PostgreSQL v14.1 instance accessible locally via port `5555`. To launch the container use the following command: -

```
docker compose --compatibility up
```

The `compatibility` flag is used to enforce memory sizing constraints - in this case 2GB RAM.

You will need to create and migrate the database before running the testing task: -

```
rake db:create db:migrate
```

Note: the migration will create 3000 schemas and will take 20-30 minutes to complete.

Once the schemas and tables have been created, you can run a rake task to exercise the database instance. We made use of the `parallel` command line tool to run 4 instances of the rake task: -

```
parallel ::: "rake touch:test" "rake touch:test" "rake touch:test" "rake touch:test"
```

This rake task will cycle through each schema, selecting the first record from each table (note: none of the tables contain any data). In our testing each rake task will fail somewhere around the 800th schema. Increasing or reducing the number of parallel tasks will move the failure point accordingly, as will adjusting the amount of RAM in the Docker Compose configuration.

Here's a graph of memory utilisation during a test run, you'll see memory usage keeps growing until the database process is killed by the operating system: -

![no_reset](https://github.com/CircleSD/pg_object_cache_test/blob/main/db/graphs/no_reset.png?raw=true)

To enable connection resetting, use the following command: -

```
RESET_CONNECTION=true parallel ::: "rake touch:test" "rake touch:test" "rake touch:test" "rake touch:test"
```

This will reset the database connection every 500 schemas - in our testing each rake task will run successfully to the end having visited each of the 3000 schemas.

Here's a graph of memory utilisation during a test run with connection resetting enabled, you can clearly see where the connection gets reset: -

![with_reset](https://github.com/CircleSD/pg_object_cache_test/blob/main/db/graphs/with_reset.png?raw=true)

## References

https://dba.stackexchange.com/questions/160887/how-can-i-find-the-source-of-postgresql-per-connection-memory-leaks/222815#222815

https://stackoverflow.com/questions/5587830/postgresql-backend-process-high-memory-usage-issue

https://italux.medium.com/postgresql-out-of-memory-3fc1105446d
