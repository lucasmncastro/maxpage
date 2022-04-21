# 🐶 Max, your app's best friend!

__Max Page__ sniffs metrics in your app to check if is everything right.

![ "MaxPage Example (code and generated page)"](./docs/print.png?raw=true)

In other words, it's a [Ruby on Rails](https://github.com/rails/rails) engine to create "status pages" for your project.

__Max__ is similiar to what [GitHub](https://www.githubstatus.com/), [Heroku](https://status.heroku.com/), [Atlassian](https://status.atlassian.com/) and others do to keep their users noticed about the operational status. However, __Max__ it's much more about the apps's data than its infrastructure. If you would like something to keep a history of incidents, subscriptions, and integrations with external, try specific tools like [StatusPage](https://www.atlassian.com/software/statuspage).

__Max get together your app's metrics, in a single page.__

For metrics, I mean some numbers and verifications that help us to understand if the app is running fine as a whole. They are not necessarily infrastructure checks.

Examples of metrics:

1. Check health of internal and external services;
2. Number of users registered last 24h;
3. Number of clients that are using the key features;
4. Size of internal queue processing services;
5. Nodes we are consuming in the Kubernetes cluster.

## Installation

Install the `maxpage` gem in your Rails app by using `bundle`:

```bash
$ bundle add maxpage
```

After that, add the configuration file `config/initializers/maxpage.rb` to start creating your metrics, like the following code:

```ruby
MaxPage.setup do
  metric 'Users registered last 24h' do
    User.where("created_at > ?", 24.hours.ago).count
  end
end
```

Mount the route for the status page in `config/routes.rb`:

```ruby
  mount MaxPage::Engine => "/status"
```

In that case, we are going to accces the page using the `/status` path: [http://localhost:3000/status](http://localhost:3000/status).

You can use __Max__ exclusively to monitor other apps and services. In that case consider to use only `/` instead `/status` to mount the `MaxPage` engine, as your Rails application would not need other routes.

## Usage

To set up `MaxPage` all we need is to create an initializer file to define metrics.

Before do it, let's establish some concepts:
* A `metric` is anything you want to monitor;
* A `metric` has a `name` and a `block` of code;
* The `block`'s result will be presented in the page;
* The `block`'s result can be verified to produce an __warning__ or __success__ message;

Let's to an example!

```ruby
MaxPage.setup do
  metric 'Users registered last 24h' do
    User.where("created_at > ?", 24.hours.ago).count
  end
end
```

In the above code we have a metric named "User registered last 24h", with a block code that count in the database the users registed last 24h, using `ActiveRecord`.

__⚠️ Important:__ As our configuration is under `config/initializers` folder we __MUST__ restart the Rails server to see the changes. Soon we're going to move the setup code to the `app` directory and eliminate the need of restarting. Work in progress.

### The option `verify`

Let's say that usually I have 30 new users per day in my app.

I would like to know when this number is less than 20, what means something wrong is happening.

So, we are going to add the `verify` option to check this metric status:

```ruby
MaxPage.setup do
  metric 'Users registered >= 20 ', verify: { min: 20 } do
    User.where("created_at > ?", 24.hours.ago).count
  end
end
```

Alternatively, we could use `verify: true`:

```ruby
MaxPage.setup do
  metric 'Users registered last 24h is more than 20', verify: true do
    User.where("created_at > ?", 24.hours.ago).count > 20
  end
end
```

Observe that when we use `verify: true`, it's expected the metric returns `true`. The page shows
a check icon (✅) if this condition is satisfied, otherwise, it shows a warning icon (⚠️).

At mostly, when I am checking numbers, I prefer to use verify with `min` or `max`.

### Warning and success messages

On top of the page, Max print a message accordling the verifications.

If all the metrics have their verify satisfied, the `success message` is printed.
Otherwise, we see the `warning message`.

Remember that the `verify` is not a required option, therefore if it is not defined we consider the metric is always __Okay__ to the overall verification.

We can change these messages. In the following code I translated them to Portuguese:

```ruby
StatusPage.setup do
  success_message 'Tudo certo!'
  warning_message 'Ops, tem algo de errado.'

  metric 'Usuários cadastrados nas últimas 24 horas', verify: { min: 20 } do
    User.where("created_at > ?", 24.hours.ago).count
  end
end
```

### Groups of metrics

It's possible to create group of metrics just to organize them.

We can do it as the following code:

```ruby
MaxPage.setup do
  group 'Application data' do
    metric 'User registered last 24h' do
      # ...
    end

    # ...
  end

  group 'Internal services status' do
    metric 'ElasticSearch is up' do
      # ...
    end

    metric 'Redis is up' do
      # ...
    end
  end
end
```

### Authentications and Authorizations

Sometimes our page presents sensible data that could't be published to everyone.

Thinking of this, we can use the `before_action` option to  define authentication and authorization rules.

Example:

```ruby
MaxPage.setup do
  before_action do
    authenticate_user!
  end

  # ... 
end
```

The `before_action` block will be evaluated in `before_action` callback, using the controller scope.
This is why you can use methods like `authenticate_<resource_name>!` from [Devise](https://github.com/heartcombo/devise) and `authorize` from [Pundit](https://github.com/varvet/pundit).

## Examples

### Health status

Here we are checking the standard library `Net::HTTP` the request a URI:

```ruby
  metric 'Health check using Net::HTTP', verify: true do
    # Rescue errors returning false 
    result = Net::HTTP.get(URI('https://example.com/health/check')) rescue false

    # Double bang to return true because result is String if the request succeeded.
    !!result
  end
```

Now, some examples using [HTTParty](https://github.com/jnunemaker/httparty) to check the HTTP status.

```ruby
  require 'httparty'

  metric 'Health check', verify: true do
    HTTParty.get('https://example.com').success?
  end

  # Will warn once https://example.com/health/check will return the 404 status.
  metric 'Health check status code', verify: 200 do
    HTTParty.get('https://example.com/health/check').code
  end
```

### Database records

```ruby
  metric 'PostgreSQL records count', description: "Heroku's Hobby Dev plan limits to 10,000", verify: { max: 10_000 } do
    ActiveRecord::Base.connection.execute(%{
      select sum(c.reltuples) as rows
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where c.relkind = 'r'
      and n.nspname not in ('information_schema','pg_catalog');
    }).first['rows']
  end
```

### Delayed::Job

```ruby
  group "Delayed Job" do
    metric 'Failures', verify: { max: 0 } do
      Delayed::Job.where.not(failed_at: nil).count
    end

    metric 'Size of the queue "mailer"' do
      Delayed::Job.where(queue: 'mailer').count
    end
  end
```

### Bugsnag errors

```ruby
  require 'httparty'

  metric 'Open errors on Bugsnag', verify: { max: 0 } do
    project_id = '<PROJECT-ID>'
    auth_token = '<AUTH-TOKEN>'
    response = HTTParty.get "https://api.bugsnag.com/projects/#{project_id}?auth_token=#{auth_token}"
    response['open_error_count']
  end
```

## Contributing

Contributions are welcome! Feel free to open an issue and pull request on [GitHub](https://github.com/lucasmncastro/maxpage).

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).